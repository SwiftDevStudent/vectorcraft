import AppKit
import VectorCraftCore

@MainActor
final class VectorCanvasView: NSView {
  var drawing = Drawing()
  var state = EditorState()
  var command: (DrawingCommand) -> Void = { _ in }
  var artworkPasteboard: NSPasteboard = .general
  lazy var bitmapPaste = CanvasBitmapPaste(view: self)
  private(set) var zoom: CGFloat = 1
  private var offset = CGPoint.zero
  private lazy var zoomAnimator = CanvasZoomAnimator(view: self) { [weak self] value, anchor in
    self?.setZoom(value, at: anchor)
  }
  private var fitMode = true
  private var fitAllArtboards = false
  private var laidOut = false
  private var boardIndex = 0
  private var lastAction: CanvasAction?
  private var down = CGPoint.zero
  private var current = CGPoint.zero
  private var downInView = CGPoint.zero
  private var panOffset = CGPoint.zero
  private var spaceHeld = false
  private var gesture: Gesture?
  private var pendingAnchors: [VectorAnchor] = []
  private var pencilPoints: [CGPoint] = []
  private var originalSelection = Set<Int64>()
  var preview: (drawing: Drawing, selection: Set<Int64>)?
  var gradientDrag: CanvasGradientDrag?
  var transformPreview: (drawing: Drawing, selection: Set<Int64>)?
  var displayedDrawing: Drawing { transformPreview?.drawing ?? preview?.drawing ?? drawing }
  var displayedSelection: Set<Int64> {
    let selected = transformPreview?.selection ?? preview?.selection ?? state.selection
    guard let isolation = state.isolationID else { return selected }
    return selected.filter { displayedDrawing.isInside($0, isolation: isolation) }
  }
  private var marquee: CGRect?
  var textEditor: CanvasTextEditor?
  var snapTargets: [CGRect] = []
  var snapGuides: [SnapGuide] = []
  var screenshotDropTarget: ScreenshotSlot?
  lazy var imagePreviews = CanvasImagePreviews(view: self)
  let snapFeedback = SnapFeedback()

  private enum Gesture {
    case pan
    case move(Int64?)
    case resize(ResizeHandle, CGRect)
    case rotate(CGPoint)
    case nodes(NodeSelection)
    case shape, pencil, pen, marquee, textFrame
  }
  override var isFlipped: Bool { true }
  override var acceptsFirstResponder: Bool { true }
  override func becomeFirstResponder() -> Bool {
    let accepted = super.becomeFirstResponder()
    if accepted { state.canvasHasFocus = true }
    return accepted
  }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    clipsToBounds = true
    registerForDraggedTypes([.fileURL])
    setAccessibilityElement(true)
    setAccessibilityRole(.image)
    setAccessibilityLabel("Vector Canvas")
  }
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    clipsToBounds = true
    registerForDraggedTypes([.fileURL])
    setAccessibilityElement(true)
    setAccessibilityRole(.image)
    setAccessibilityLabel("Vector Canvas")
  }

  func update(drawing: Drawing, state: EditorState, command: @escaping (DrawingCommand) -> Void) {
    let previousArtboard = fitBounds
    if self.drawing != drawing { preview = nil }
    self.drawing = drawing
    self.state = state
    self.command = command
    if gradientDrag != nil, state.tool != .gradient { cancelGradient() }
    if textEditor != nil && (state.tool != .text || state.homePresented) { finishTextEditing() }
    if let editor = textEditor, let id = editor.nodeID,
      drawing.node(id).map({ !editor.matches($0) }) ?? true
    {
      finishTextEditing()
    }
    textEditor?.updateGeometry()
    setAccessibilityValue("\(state.selection.count) Selected")
    if boardIndex != state.selectedArtboard {
      boardIndex = state.selectedArtboard
      fitAllArtboards = false
      fitMode = true
      fit()
    } else if fitMode, fitBounds != previousArtboard {
      fit()
    }
    if let action = state.canvasAction, lastAction != action {
      lastAction = action
      switch action {
      case .editText:
        DispatchQueue.main.async { [weak self] in
          guard let self, self.state.canvasAction == .editText,
            let id = self.state.selection.first, self.drawing.node(id)?.type == "text"
          else { return }
          self.beginTextEditing(id: id)
        }
      case .fitWorkspace:
        fitAllArtboards = true
        fitMode = true
        fit()
      case .fit:
        fitAllArtboards = false
        fitMode = true
        fit()
      case .actualSize:
        zoomAnimator.stop()
        fitMode = false
        setZoom(1, at: CGPoint(x: bounds.midX, y: bounds.midY))
      case .finishPath: finishPath(closed: false)
      case .closePath: finishPath(closed: true)
      case .cancelPath:
        pendingAnchors = []
        preview = nil
        gesture = nil
        marquee = nil
        endSnapping()
      }
      DispatchQueue.main.async { [weak self] in
        guard let self, self.state.canvasAction == action else { return }
        self.state.canvasAction = nil
        self.lastAction = nil
      }
    } else if state.canvasAction == nil {
      lastAction = nil
    }
    needsDisplay = true
  }

  override func layout() {
    super.layout()
    if fitMode { fit() }
    laidOut = true
    textEditor?.updateGeometry()
  }
  private var artboard: CGRect {
    drawing.artboards.indices.contains(boardIndex)
      ? drawing.artboards[boardIndex] : drawing.artboard
  }
  private var fitBounds: CGRect {
    fitAllArtboards ? drawing.screenshotWorkspaceBounds : artboard
  }
  private func fit() {
    zoomAnimator.stop()
    guard bounds.width > 0, bounds.height > 0 else { return }
    let board = fitBounds
    zoom = min((bounds.width - 60) / board.width, (bounds.height - 60) / board.height)
    zoom = min(128, max(0.005, zoom))
    offset = CGPoint(x: bounds.midX - board.midX * zoom, y: bounds.midY - board.midY * zoom)
    reportZoom()
    needsDisplay = true
  }
  private func reportZoom() {
    let value = Double(zoom)
    if abs(state.zoom - value) > 0.0001 {
      DispatchQueue.main.async { [weak self] in self?.state.zoom = value }
    }
  }
  private func setZoom(_ value: CGFloat, at point: CGPoint) {
    let documentPoint = toDocument(point)
    zoom = min(128, max(0.005, value))
    offset = CGPoint(x: point.x - documentPoint.x * zoom, y: point.y - documentPoint.y * zoom)
    reportZoom()
    needsDisplay = true
  }
  private func smoothZoom(by factor: CGFloat, at point: CGPoint) {
    guard factor.isFinite, factor > 0, factor != 1 else { return }
    zoomAnimator.animate(from: zoom, to: (zoomAnimator.target ?? zoom) * factor, at: point)
  }
  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    if window == nil { zoomAnimator.stop() }
  }
  func toDocument(_ point: CGPoint) -> CGPoint {
    CGPoint(x: (point.x - offset.x) / zoom, y: (point.y - offset.y) / zoom)
  }
  func toView(_ point: CGPoint) -> CGPoint {
    CGPoint(x: point.x * zoom + offset.x, y: point.y * zoom + offset.y)
  }
  func viewRect(_ rect: CGRect) -> CGRect {
    CGRect(
      x: rect.minX * zoom + offset.x, y: rect.minY * zoom + offset.y, width: rect.width * zoom,
      height: rect.height * zoom)
  }
  private func eventPoint(_ event: NSEvent) -> CGPoint {
    convert(event.locationInWindow, from: nil)
  }
  private var selectionBounds: CGRect {
    displayedSelection.compactMap(displayedDrawing.node).reduce(CGRect.null) {
      $0.union($1.bounds)
    }
  }

  override func draw(_ dirtyRect: NSRect) {
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    context.saveGState()
    defer { context.restoreGState() }
    context.clip(to: bounds)
    if !laidOut {
      fit()
      laidOut = true
    }
    WorkspaceTheme.pasteboard.setFill()
    bounds.fill()
    context.saveGState()
    context.translateBy(x: offset.x, y: offset.y)
    context.scaleBy(x: zoom, y: zoom)
    drawScreenshotSlots(context)
    if let target = screenshotDropTarget {
      context.setStrokeColor(WorkspaceTheme.selection.cgColor)
      context.setLineWidth(4 / zoom)
      context.stroke(target.rect)
    }
    for board in drawing.artboards {
      context.setFillColor(CGColor(gray: 1, alpha: 1))
      context.fill(board)
      context.setStrokeColor(NSColor.black.cgColor)
      context.setLineWidth(1 / zoom)
      context.stroke(board)
    }
    if state.gridPresented { drawGrid(context) }
    VectorRenderer.render(
      displayedDrawing, in: context, excluding: textEditor?.nodeID, isolating: state.isolationID,
      clippingScreenshotBoards: state.clipScreenshotArtwork, previewImages: imagePreviews.cache)
    imagePreviews.update(imagePreviews.cache.requests)
    if !pendingAnchors.isEmpty {
      let path = VectorSubpath(anchors: pendingAnchors, closed: false).cgPath
      context.addPath(path)
      context.setStrokeColor(WorkspaceTheme.selection.cgColor)
      context.setLineWidth(1.5 / zoom)
      context.strokePath()
      for anchor in pendingAnchors { drawAnchor(anchor, selected: false, context: context) }
    }
    context.restoreGState()
    if state.rulersPresented { drawRulers(context) }
    drawSnapGuides(context)
    drawSelection(context)
    drawGradient(context)
    reportSelectionBounds()
    if textEditor == nil, displayedSelection.count == 1, let id = displayedSelection.first,
      let node = displayedDrawing.node(id), VectorText.isOverset(node)
    {
      let frame = viewRect(node.bounds)
      NSColor.systemRed.setFill()
      CGRect(x: frame.maxX - 10, y: frame.maxY - 10, width: 9, height: 9).fill()
      ("+" as NSString).draw(
        at: CGPoint(x: frame.maxX - 10, y: frame.maxY - 12),
        withAttributes: [.font: NSFont.boldSystemFont(ofSize: 10), .foregroundColor: NSColor.white])
    }
    if let marquee {
      context.setStrokeColor(WorkspaceTheme.selection.cgColor)
      context.setLineWidth(1)
      context.setLineDash(phase: 0, lengths: [4, 3])
      context.stroke(viewRect(marquee))
      context.setLineDash(phase: 0, lengths: [])
    }
  }

  private func reportSelectionBounds() {
    let selected = selectionBounds
    let rect = selected.isNull ? nil : viewRect(selected)
    guard state.selectionInCanvas != rect else { return }
    // Drawing may run during a SwiftUI update; publish geometry on the next main turn.
    DispatchQueue.main.async { [weak self] in self?.state.selectionInCanvas = rect }
  }

  private func drawSelection(_ context: CGContext) {
    let bounds = selectionBounds
    guard textEditor == nil, !bounds.isNull else { return }
    context.saveGState()
    defer { context.restoreGState() }
    context.setStrokeColor(WorkspaceTheme.selection.cgColor)
    context.setLineWidth(1)
    if state.tool == .gradient {
      for id in displayedSelection {
        if let node = displayedDrawing.node(id) { context.stroke(viewRect(node.bounds)) }
      }
    } else if state.tool == .nodes, displayedSelection.count == 1,
      let id = displayedSelection.first,
      let node = displayedDrawing.node(id), ["path", "compound"].contains(node.type)
    {
      context.translateBy(x: offset.x, y: offset.y)
      context.scaleBy(x: zoom, y: zoom)
      context.setLineWidth(1 / zoom)
      context.addPath(node.cgPath)
      context.strokePath()
      for (si, path) in node.subpaths.enumerated() {
        for (ai, anchor) in path.anchors.enumerated() {
          let selected = state.nodeSelection?.subpath == si && state.nodeSelection?.anchor == ai
          drawAnchor(anchor, selected: selected, context: context)
        }
      }
    } else {
      context.stroke(viewRect(bounds))
      context.setFillColor(NSColor.white.cgColor)
      for handle in ResizeHandle.allCases {
        let p = toView(handle.point(in: bounds))
        let rect = CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6)
        context.fill(rect)
        context.stroke(rect)
      }
    }
  }
  private func drawGrid(_ context: CGContext) {
    let spacing = Snapping.gridSpacing
    let step = max(spacing, spacing * pow(10, ceil(log10(8 / max(zoom * spacing, 0.0001)))))
    let visible = CGRect(
      x: (bounds.minX - offset.x) / zoom, y: (bounds.minY - offset.y) / zoom,
      width: bounds.width / zoom, height: bounds.height / zoom)
    context.saveGState()
    defer { context.restoreGState() }
    context.setStrokeColor(NSColor(white: 0.85, alpha: 1).cgColor)
    context.setLineWidth(0.5 / zoom)
    for board in drawing.artboards {
      let rect = board.intersection(visible)
      guard !rect.isNull else { continue }
      for x in stride(from: ceil(rect.minX / step) * step, through: rect.maxX, by: step) {
        context.move(to: CGPoint(x: x, y: rect.minY))
        context.addLine(to: CGPoint(x: x, y: rect.maxY))
      }
      for y in stride(from: ceil(rect.minY / step) * step, through: rect.maxY, by: step) {
        context.move(to: CGPoint(x: rect.minX, y: y))
        context.addLine(to: CGPoint(x: rect.maxX, y: y))
      }
      context.strokePath()
    }
  }
  private func drawRulers(_ context: CGContext) {
    context.saveGState()
    defer { context.restoreGState() }
    context.setFillColor(NSColor(white: 0.2, alpha: 1).cgColor)
    context.fill(CGRect(x: 0, y: 0, width: bounds.width, height: 20))
    context.fill(CGRect(x: 0, y: 0, width: 20, height: bounds.height))
    let step = pow(10, ceil(log10(45 / zoom)))
    context.setStrokeColor(NSColor(white: 0.55, alpha: 1).cgColor)
    context.setLineWidth(0.5)
    let attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: 9),
      .foregroundColor: NSColor(white: 0.7, alpha: 1),
    ]
    let left = toDocument(.zero).x
    let right = toDocument(CGPoint(x: bounds.maxX, y: 0)).x
    for value in stride(from: ceil(left / step) * step, through: right, by: step) {
      let x = value * zoom + offset.x
      context.move(to: CGPoint(x: x, y: 15))
      context.addLine(to: CGPoint(x: x, y: 20))
      (String(format: "%.0f", value) as NSString).draw(
        at: CGPoint(x: x + 2, y: 2), withAttributes: attributes)
    }
    let top = toDocument(.zero).y
    let bottom = toDocument(CGPoint(x: 0, y: bounds.maxY)).y
    for value in stride(from: ceil(top / step) * step, through: bottom, by: step) {
      let y = value * zoom + offset.y
      context.move(to: CGPoint(x: 15, y: y))
      context.addLine(to: CGPoint(x: 20, y: y))
      (String(format: "%.0f", value) as NSString).draw(
        at: CGPoint(x: 1, y: y + 2), withAttributes: attributes)
    }
    context.strokePath()
  }
  private func drawAnchor(_ anchor: VectorAnchor, selected: Bool, context: CGContext) {
    context.setStrokeColor(WorkspaceTheme.selection.cgColor)
    context.setLineWidth(1 / zoom)
    for handle in [anchor.incoming, anchor.outgoing] where handle != anchor.point {
      context.move(to: anchor.point)
      context.addLine(to: handle)
      context.strokePath()
      let r = CGRect(
        x: handle.x - 3 / zoom, y: handle.y - 3 / zoom, width: 6 / zoom, height: 6 / zoom)
      context.setFillColor(NSColor.white.cgColor)
      context.fillEllipse(in: r)
      context.strokeEllipse(in: r)
    }
    let r = CGRect(
      x: anchor.point.x - 3.5 / zoom, y: anchor.point.y - 3.5 / zoom, width: 7 / zoom,
      height: 7 / zoom)
    context.setFillColor(
      selected ? WorkspaceTheme.selection.cgColor : NSColor.white.cgColor)
    context.fill(r)
    context.stroke(r)
  }

  override func mouseDown(with event: NSEvent) {
    zoomAnimator.stop()
    finishTextEditing()
    window?.makeFirstResponder(self)
    downInView = eventPoint(event)
    down = toDocument(downInView)
    current = down
    snapTargets = Snapping.targets(
      in: drawing, excluding: [.select, .nodes].contains(state.tool) ? state.selection : [],
      within: state.isolationID)
    snapGuides = []
    snapFeedback.begin(at: toView(down), event: event)
    preview = nil
    gradientDrag = nil
    originalSelection = state.selection
    panOffset = offset
    if state.tool == .hand || spaceHeld {
      gesture = .pan
      return
    }
    if state.tool == .select,
      let slot = drawing.screenshotSlots.first(where: { $0.boardID == nil && $0.rect.contains(down) }) {
      command(.screenshot(ScreenshotCommand(.addBoard, row: slot.row, slot: slot.index)))
      endSnapping()
      return
    }
    if event.clickCount >= 2, state.tool == .select {
      let target = hit(down, selectingGroups: true)
      if let target, state.enterIsolation(target, in: drawing) {
        gesture = nil
        endSnapping()
        needsDisplay = true
        return
      }
      if target == nil, state.isolationID != nil {
        state.exitIsolation(in: drawing)
        gesture = nil
        endSnapping()
        needsDisplay = true
        return
      }
    }
    if event.clickCount >= 2, let id = hit(down),
      drawing.node(id)?.type == "text"
    {
      beginTextEditing(id: id, event: event)
      return
    }
    switch state.tool {
    case .gradient:
      if state.selection.isEmpty, let id = hit(down, selectingGroups: true) {
        state.selection = [id]
      }
      beginGradient(at: down, event: event)
    case .text:
      if let id = hit(down), drawing.node(id)?.type == "text" {
        beginTextEditing(id: id, event: event)
        return
      }
      gesture = .textFrame
      down = snapped(down, event: event)
      current = down
    case .zoom:
      fitMode = false
      smoothZoom(by: event.modifierFlags.contains(.option) ? 0.8 : 1.25, at: downInView)
      gesture = nil
    case .eyedropper:
      if let id = hit(down), let node = drawing.node(id) {
        state.loadStyle(node)
        if !state.selection.isEmpty { command(.style(state.selection, state.style)) }
      }
      gesture = nil
    case .rotate:
      let bounds = selectionBounds
      if !bounds.isNull { gesture = .rotate(CGPoint(x: bounds.midX, y: bounds.midY)) }
    case .select:
      let bounds = selectionBounds
      if !bounds.isNull,
        let handle = ResizeHandle.allCases.first(where: {
          $0.point(in: bounds).distance(to: down) < 8 / zoom
        })
      {
        down = handle.point(in: bounds)
        gesture = .resize(handle, bounds)
        return
      }
      if let id = hit(down, selectingGroups: true) {
        var deselectOnClick: Int64?
        if event.modifierFlags.contains(.shift) {
          if state.selection.contains(id) {
            deselectOnClick = id
          } else {
            state.selection.insert(id)
          }
        } else if !state.selection.contains(id) {
          state.selection = [id]
        }
        gesture = .move(deselectOnClick)
        snapTargets = Snapping.targets(
          in: drawing, excluding: state.selection, within: state.isolationID)
        snapFeedback.begin(at: toView(selectionBounds.origin), event: event)
      } else {
        if !event.modifierFlags.contains(.shift) { state.selection = [] }
        gesture = .marquee
      }
    case .nodes:
      if let selected = nearestNode(down) {
        state.nodeSelection = selected
        gesture = .nodes(selected)
      } else if let id = hit(down) {
        state.selection = [id]
        state.nodeSelection = nearestNode(down)
        if let selected = state.nodeSelection { gesture = .nodes(selected) }
      } else {
        state.selection = []
        state.nodeSelection = nil
        gesture = nil
      }
    case .pen:
      down = snapped(down, event: event)
      current = down
      if pendingAnchors.count >= 2, let first = pendingAnchors.first,
        first.point.distance(to: down) < 10 / zoom
      {
        finishPath(closed: true)
        gesture = nil
      } else {
        pendingAnchors.append(VectorAnchor(down))
        gesture = .pen
      }
    case .pencil:
      pencilPoints = [down]
      gesture = .pencil
    case .rectangle, .ellipse, .star, .polygon, .line:
      down = snapped(down, event: event)
      current = down
      gesture = .shape
    case .hand: gesture = .pan
    }
    needsDisplay = true
  }

  override func mouseDragged(with event: NSEvent) {
    current = toDocument(eventPoint(event))
    if gradientDrag != nil {
      moveGradient(to: current, event: event)
      return
    }
    switch gesture {
    case .move:
      let original = state.selection.compactMap(drawing.node).reduce(CGRect.null) {
        $0.union($1.bounds)
      }
      if !original.isNull {
        let delta = snapped(
          CGPoint(x: current.x - down.x, y: current.y - down.y), moving: original, event: event,
          constrainMovement: event.modifierFlags.contains(.shift))
        current = CGPoint(x: down.x + delta.x, y: down.y + delta.y)
      }
    case .nodes(let selected) where selected.handle == nil:
      if let anchor = snapAnchor(selected) {
        let point = CGPoint(
          x: anchor.point.x + current.x - down.x, y: anchor.point.y + current.y - down.y)
        let aligned = snapped(point, event: event)
        current = CGPoint(
          x: down.x + aligned.x - anchor.point.x, y: down.y + aligned.y - anchor.point.y)
      }
    case .shape, .textFrame, .resize, .nodes:
      current = snapped(current, event: event)
    default: break
    }
    switch gesture {
    case .rotate(let center): previewCommand(rotationCommand(center, event: event))
    case .pan:
      let point = eventPoint(event)
      offset = CGPoint(
        x: panOffset.x + point.x - downInView.x, y: panOffset.y + point.y - downInView.y)
      fitMode = false
    case .move:
      previewCommand(moveCommand(event))
    case .resize(let handle, let bounds):
      previewCommand(
        resizeCommand(handle: handle, bounds: bounds, event: event)
      )
    case .nodes(let selection): previewNode(selection)
    case .shape: previewShape(constrain: event.modifierFlags.contains(.shift))
    case .pencil:
      if pencilPoints.count < 10000, (pencilPoints.last?.distance(to: current) ?? 0) > 2 / zoom {
        pencilPoints.append(current)
      }
      previewPath(
        VectorSubpath(anchors: pencilPoints.map { VectorAnchor($0) }, closed: false), open: true)
    case .pen:
      if !pendingAnchors.isEmpty {
        let index = pendingAnchors.count - 1
        pendingAnchors[index].outgoing = current
        pendingAnchors[index].incoming = CGPoint(
          x: 2 * down.x - current.x, y: 2 * down.y - current.y)
        pendingAnchors[index].smooth = down.distance(to: current) > 2 / zoom
      }
    case .marquee, .textFrame: marquee = rect(down, current)
    case nil: break
    }
    needsDisplay = true
  }

  override func mouseUp(with event: NSEvent) {
    if gradientDrag != nil {
      finishGradient(at: toDocument(eventPoint(event)), event: event)
      return
    }
    // Recompute through the exact preview path, including release modifiers/location.
    switch gesture {
    case .move, .resize, .rotate, .nodes, .shape, .textFrame, .marquee: mouseDragged(with: event)
    default: current = toDocument(eventPoint(event))
    }
    let moved = eventPoint(event).distance(to: downInView) > 2
    switch gesture {
    case .textFrame:
      beginTextEditing(origin: down, area: moved ? rect(down, current) : nil)
    case .rotate(let center):
      if moved { command(rotationCommand(center, event: event)) }
    case .move(let deselectOnClick):
      if moved {
        command(moveCommand(event))
      } else if let deselectOnClick {
        state.selection.remove(deselectOnClick)
      }
    case .resize(let handle, let bounds):
      if moved {
        command(resizeCommand(handle: handle, bounds: bounds, event: event))
      }
    case .nodes(let selection):
      if moved, let id = state.selection.first, let node = preview?.drawing.node(id) {
        command(.replacePath(id, node.subpaths))
        state.nodeSelection = selection
      }
    case .shape:
      if !moved { current = CGPoint(x: down.x + 120, y: down.y + 100) }
      command(
        .addPath(
          [shape(constrain: event.modifierFlags.contains(.shift))],
          drawingStyle(open: state.tool == .line), layer: state.insertionContainer(in: drawing)))
    case .pencil:
      if pencilPoints.count >= 2 {
        command(
          .addPath(
            [VectorSubpath(anchors: pencilPoints.map { VectorAnchor($0) }, closed: false)],
            drawingStyle(open: true), layer: state.insertionContainer(in: drawing)))
      }
      pencilPoints = []
    case .marquee:
      if let marquee {
        let selected = drawing.selectableIDs(within: state.isolationID, intersecting: marquee)
        state.selection =
          event.modifierFlags.contains(.shift) ? originalSelection.union(selected) : selected
      }
    default: break
    }
    gesture = nil
    preview = nil
    marquee = nil
    endSnapping()
    needsDisplay = true
  }

  override func mouseMoved(with event: NSEvent) { state.pointer = toDocument(eventPoint(event)) }
  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    for area in trackingAreas { removeTrackingArea(area) }
    addTrackingArea(
      NSTrackingArea(
        rect: .zero, options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect], owner: self,
        userInfo: nil))
  }
  override func scrollWheel(with event: NSEvent) {
    if event.modifierFlags.contains(.option) {
      fitMode = false
      smoothZoom(by: exp(event.scrollingDeltaY * 0.01), at: eventPoint(event))
    } else {
      zoomAnimator.stop()
      fitMode = false
      offset.x += event.scrollingDeltaX
      offset.y += event.scrollingDeltaY
      needsDisplay = true
    }
  }
  override func magnify(with event: NSEvent) {
    fitMode = false
    smoothZoom(by: max(0.1, 1 + event.magnification), at: eventPoint(event))
  }
  override func keyDown(with event: NSEvent) {
    if event.keyCode == 49 {
      spaceHeld = true
      NSCursor.openHand.set()
      return
    }
    if event.keyCode == 53 {
      if gradientDrag != nil {
        cancelGradient()
        return
      }
      let canceling = gesture != nil || preview != nil || !pendingAnchors.isEmpty
      pendingAnchors = []
      preview = nil
      gesture = nil
      marquee = nil
      endSnapping()
      if !canceling, state.isolationID != nil {
        state.exitIsolation(in: drawing)
      } else {
        state.selection = []
      }
      needsDisplay = true
      return
    }
    if event.keyCode == 36 {
      finishPath(closed: false)
      return
    }
    if event.keyCode == 51 || event.keyCode == 117 {
      if let value = state.deletionCommand { command(value) }
      return
    }
    let step: CGFloat = event.modifierFlags.contains(.shift) ? 10 : 1
    let delta: CGPoint?
    switch event.keyCode {
    case 123: delta = CGPoint(x: -step, y: 0)
    case 124: delta = CGPoint(x: step, y: 0)
    case 125: delta = CGPoint(x: 0, y: step)
    case 126: delta = CGPoint(x: 0, y: -step)
    default: delta = nil
    }
    if let delta, !state.selection.isEmpty {
      command(.transform(state.selection, .init(translationX: delta.x, y: delta.y)))
      return
    }
    super.keyDown(with: event)
  }
  override func keyUp(with event: NSEvent) {
    if event.keyCode == 49 {
      spaceHeld = false
      NSCursor.arrow.set()
    } else {
      super.keyUp(with: event)
    }
  }
  override func resignFirstResponder() -> Bool {
    spaceHeld = false
    gesture = nil
    preview = nil
    endSnapping()
    let accepted = super.resignFirstResponder()
    if accepted { state.canvasHasFocus = false }
    return accepted
  }

  private func rect(_ a: CGPoint, _ b: CGPoint) -> CGRect {
    CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
  }
  private func shape(constrain: Bool) -> VectorSubpath {
    var end = current
    if constrain {
      let extent = max(abs(current.x - down.x), abs(current.y - down.y))
      end = CGPoint(
        x: down.x + (current.x >= down.x ? extent : -extent),
        y: down.y + (current.y >= down.y ? extent : -extent))
    }
    let bounds = rect(down, end)
    switch state.tool {
    case .ellipse: return ShapePaths.ellipse(bounds)
    case .star: return ShapePaths.star(bounds)
    case .polygon: return ShapePaths.polygon(bounds)
    case .line:
      return VectorSubpath(anchors: [VectorAnchor(down), VectorAnchor(end)], closed: false)
    default: return ShapePaths.rectangle(bounds)
    }
  }
  private func drawingStyle(open: Bool) -> VectorStyle {
    var style = state.style
    if open {
      style.fill = VectorStyle.none
      if style.stroke["type"].string == "none" || style.width <= 0 {
        style.stroke = VectorStyle.solid(0.12, 0.14, 0.23)
        style.width = 2
      }
    }
    return style
  }
  private func previewCommand(_ value: DrawingCommand) {
    var next = drawing
    do {
      let selection = try next.perform(value, within: state.isolationID)
      preview = (next, selection)
    } catch { preview = nil }
  }
  private func previewShape(constrain: Bool) {
    previewPath(shape(constrain: constrain), open: state.tool == .line)
  }
  private func previewPath(_ path: VectorSubpath, open: Bool) {
    previewCommand(.addPath([path], drawingStyle(open: open), layer: state.insertionContainer(in: drawing)))
  }
  private func moveCommand(_ event: NSEvent) -> DrawingCommand {
    .transform(
      state.selection, .init(translationX: current.x - down.x, y: current.y - down.y),
      copy: event.modifierFlags.contains(.option))
  }
  private func resizeCommand(handle: ResizeHandle, bounds: CGRect, event: NSEvent) -> DrawingCommand
  {
    let transform = TransformGeometry.resize(
      bounds, handle: handle, to: current,
      proportional: event.modifierFlags.contains(.shift),
      fromCenter: event.modifierFlags.contains(.option))
    if state.selection.count == 1, let id = state.selection.first, let node = drawing.node(id),
      VectorText.areaRect(node) != nil, let xf = node.raw["kind"]["xf"].affine,
      xf.b == 0, xf.c == 0, xf.a > 0, xf.d > 0
    {
      return .resizeTextFrame(id, bounds.applying(transform))
    }
    return .transform(state.selection, transform)
  }
  private func rotationCommand(_ center: CGPoint, event: NSEvent) -> DrawingCommand {
    .transform(
      state.selection,
      TransformGeometry.rotation(
        from: down, to: current, around: center, constrained: event.modifierFlags.contains(.shift)),
      copy: event.modifierFlags.contains(.option))
  }
  private func nearestNode(_ point: CGPoint) -> NodeSelection? {
    guard state.selection.count == 1, let id = state.selection.first, let node = drawing.node(id),
      ["path", "compound"].contains(node.type), drawing.canEdit(id),
      drawing.isInside(id, isolation: state.isolationID)
    else { return nil }
    var nearest: NodeSelection?
    var distance = 10 / zoom
    for (si, path) in node.subpaths.enumerated() {
      for (ai, anchor) in path.anchors.enumerated() {
        for (position, handle) in [
          (anchor.incoming, Optional("in")), (anchor.outgoing, Optional("out")),
          (anchor.point, nil),
        ] {
          if handle != nil && position == anchor.point { continue }
          let d = position.distance(to: point)
          if d < distance {
            distance = d
            nearest = NodeSelection(subpath: si, anchor: ai, handle: handle)
          }
        }
      }
    }
    return nearest
  }
  private func previewNode(_ selection: NodeSelection) {
    guard let id = state.selection.first, let node = drawing.node(id) else { return }
    var paths = node.subpaths
    guard paths.indices.contains(selection.subpath),
      paths[selection.subpath].anchors.indices.contains(selection.anchor)
    else { return }
    var anchor = paths[selection.subpath].anchors[selection.anchor]
    if let handle = selection.handle {
      if handle == "in" { anchor.incoming = current } else { anchor.outgoing = current }
      if anchor.smooth {
        let other = handle == "in" ? anchor.outgoing : anchor.incoming
        let length = other.distance(to: anchor.point)
        let distance = current.distance(to: anchor.point)
        if distance > 0.001 {
          let mirrored = CGPoint(
            x: anchor.point.x + (anchor.point.x - current.x) * length / distance,
            y: anchor.point.y + (anchor.point.y - current.y) * length / distance)
          if handle == "in" { anchor.outgoing = mirrored } else { anchor.incoming = mirrored }
        }
      }
    } else {
      let dx = current.x - down.x
      let dy = current.y - down.y
      anchor.point.x += dx
      anchor.point.y += dy
      anchor.incoming.x += dx
      anchor.incoming.y += dy
      anchor.outgoing.x += dx
      anchor.outgoing.y += dy
    }
    paths[selection.subpath].anchors[selection.anchor] = anchor
    previewCommand(.replacePath(id, paths))
  }
  private func finishPath(closed: Bool) {
    guard pendingAnchors.count >= 2 else {
      if !closed {
        pendingAnchors = []
        needsDisplay = true
      }
      return
    }
    command(
      .addPath(
        [VectorSubpath(anchors: pendingAnchors, closed: closed)], drawingStyle(open: !closed),
        layer: state.insertionContainer(in: drawing)))
    pendingAnchors = []
    preview = nil
    needsDisplay = true
  }
}
