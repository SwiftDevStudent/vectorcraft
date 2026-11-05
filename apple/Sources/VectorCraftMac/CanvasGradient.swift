import AppKit
import VectorCraftCore

struct CanvasGradientDrag {
  enum Handle {
    case origin, end
    case stop(Int)
    case newRamp
  }
  var handle: Handle
  var start: CGPoint
  var end: CGPoint
  var drawing: Drawing
  var selection: Set<Int64>
  var target: PaintTarget
  var command: DrawingCommand?
  var selectedStop: Int?
}

extension VectorCanvasView {
  private func selectedGradient(in drawing: Drawing) -> GradientPaint? {
    guard let node = (try? drawing.gradientTargets(state.selection))?.first else { return nil }
    return try? GradientPaint(
      GradientPaint.paint(of: node, target: state.gradientTarget), bounds: node.bounds)
  }

  func beginGradient(at point: CGPoint, event: NSEvent) {
    do {
      let targets = try drawing.gradientTargets(state.selection)
      guard let node = targets.first else { return }
      let raw = GradientPaint.paint(of: node, target: state.gradientTarget)
      let paint =
        raw["type"].string == "gradient" ? try GradientPaint(raw, bounds: node.bounds) : nil
      var handle: CanvasGradientDrag.Handle = .newRamp
      if let paint {
        let projection = gradientProjection(point, start: paint.start, end: paint.end)
        let onRamp = gradientPoint(projection, start: paint.start, end: paint.end)
        if event.clickCount >= 2, onRamp.distance(to: point) < 8 / zoom {
          let edit = GradientEdit.insertStop(projection)
          let result = try GradientPaint.editing(
            raw, bounds: node.bounds, with: edit, selecting: state.gradientStop)
          let value = DrawingCommand.gradient(state.selection, state.gradientTarget, edit)
          var candidate = drawing
          try candidate.perform(value, within: state.isolationID)
          command(value)
          state.gradientStop = result.selectedStop ?? 0
          endSnapping()
          needsDisplay = true
          return
        }
        if point.distance(to: paint.start) < 8 / zoom {
          handle = .origin
        } else if point.distance(to: paint.end) < 8 / zoom {
          handle = .end
        } else if let index = paint.stops.indices.first(where: {
          let stop = gradientPoint(
            paint.stops[$0]["offset"].double ?? 0, start: paint.start, end: paint.end)
          let marker = CGPoint(x: toView(stop).x, y: toView(stop).y + 12)
          return marker.distance(to: toView(point)) < 8
        }) {
          state.gradientStop = index
          handle = .stop(index)
        }
      }
      gradientDrag = CanvasGradientDrag(
        handle: handle, start: paint?.start ?? point, end: paint?.end ?? point, drawing: drawing,
        selection: state.selection, target: state.gradientTarget)
      if case .newRamp = handle { gradientDrag?.start = snapped(point, event: event) }
    } catch {
      state.error = error.localizedDescription
      endSnapping()
    }
    needsDisplay = true
  }

  func moveGradient(to rawPoint: CGPoint, event: NSEvent) {
    guard var drag = gradientDrag else { return }
    guard drawing == drag.drawing, state.selection == drag.selection,
      state.gradientTarget == drag.target, state.tool == .gradient
    else {
      cancelGradient()
      return
    }
    let edit: GradientEdit
    switch drag.handle {
    case .stop(let index):
      edit = .stopOffset(index, gradientProjection(rawPoint, start: drag.start, end: drag.end))
    case .origin, .end, .newRamp:
      let anchor: CGPoint
      if case .origin = drag.handle { anchor = drag.end } else { anchor = drag.start }
      let delta = CGPoint(x: rawPoint.x - anchor.x, y: rawPoint.y - anchor.y)
      let aligned = snapped(
        delta, moving: CGRect(origin: anchor, size: .zero), event: event,
        constrainMovement: event.modifierFlags.contains(.shift))
      let point = CGPoint(x: anchor.x + aligned.x, y: anchor.y + aligned.y)
      if case .origin = drag.handle {
        edit = .geometry(point, drag.end)
      } else {
        edit = .geometry(drag.start, point)
      }
    }
    let value = DrawingCommand.gradient(drag.selection, drag.target, edit)
    var candidate = drawing
    do {
      let selection = try candidate.perform(value, within: state.isolationID)
      if let node = try drawing.gradientTargets(drag.selection).first {
        drag.selectedStop = try GradientPaint.editing(
          GradientPaint.paint(of: node, target: drag.target), bounds: node.bounds, with: edit,
          selecting: state.gradientStop
        ).selectedStop
      }
      preview = (candidate, selection)
      drag.command = value
    } catch {
      preview = nil
      drag.command = nil
    }
    gradientDrag = drag
    needsDisplay = true
  }

  func finishGradient(at point: CGPoint, event: NSEvent) {
    moveGradient(to: point, event: event)
    let value = gradientDrag?.command
    let selectedStop = gradientDrag?.selectedStop
    gradientDrag = nil
    preview = nil
    endSnapping()
    if let value { command(value) }
    if let selectedStop { state.gradientStop = selectedStop }
    needsDisplay = true
  }
  func cancelGradient() {
    gradientDrag = nil
    preview = nil
    endSnapping()
    needsDisplay = true
  }

  func drawGradient(_ context: CGContext) {
    guard state.tool == .gradient, let paint = selectedGradient(in: displayedDrawing) else {
      return
    }
    context.saveGState()
    defer { context.restoreGState() }
    let start = toView(paint.start)
    let end = toView(paint.end)
    context.setStrokeColor(NSColor.white.cgColor)
    context.setLineWidth(3)
    context.move(to: start)
    context.addLine(to: end)
    context.strokePath()
    context.setStrokeColor(WorkspaceTheme.selection.cgColor)
    context.setLineWidth(1)
    context.move(to: start)
    context.addLine(to: end)
    context.strokePath()
    context.setFillColor(NSColor.white.cgColor)
    for point in [start, end] {
      let r = CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)
      context.fillEllipse(in: r)
      context.strokeEllipse(in: r)
    }
    for (index, stop) in paint.stops.enumerated() {
      let point = toView(
        gradientPoint(stop["offset"].double ?? 0, start: paint.start, end: paint.end))
      let rect = CGRect(x: point.x - 4, y: point.y + 8, width: 8, height: 8)
      context.setFillColor(
        VectorRenderer.color(stop["color"], opacity: stop["opacity"].double ?? 1))
      context.setLineWidth((gradientDrag?.selectedStop ?? state.gradientStop) == index ? 2 : 1)
      context.fill(rect)
      context.stroke(rect)
    }
  }
  private func gradientProjection(_ point: CGPoint, start: CGPoint, end: CGPoint) -> Double {
    let dx = end.x - start.x
    let dy = end.y - start.y
    let length = dx * dx + dy * dy
    guard length.isFinite, length > 0.000000000001 else { return 0 }
    return min(1, max(0, ((point.x - start.x) * dx + (point.y - start.y) * dy) / length))
  }
  private func gradientPoint(_ offset: Double, start: CGPoint, end: CGPoint) -> CGPoint {
    CGPoint(x: start.x + (end.x - start.x) * offset, y: start.y + (end.y - start.y) * offset)
  }
}
