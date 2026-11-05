import AppKit
import CoreText
import VectorCraftCore

/// The canvas owns this editor. Text changes use the document's normal command path,
/// so Save/autosave never depend on dismissing an entry dialog.
@MainActor
final class CanvasTextEditor: NSObject, NSTextViewDelegate {
  weak var canvas: VectorCanvasView?
  var nodeID: Int64?
  let textView = CanvasTextView()
  private let container = FlippedTextContainer()
  private let transform: CGAffineTransform
  private let area: CGRect?
  private let style: JSONValue
  private let font: NSFont
  private let family: String
  private let size: Double
  private let fill: JSONValue
  private let layer: Int64
  private let session = UUID()

  init(canvas: VectorCanvasView, node: VectorNode?, origin: CGPoint, area: CGRect?) {
    self.canvas = canvas
    nodeID = node?.id
    style = node?.raw["kind"]["runs"].array.first?["style"] ?? .object([:])
    family =
      style["font_family"].string.isEmpty ? canvas.state.textFont : style["font_family"].string
    size = style["size"].double ?? canvas.state.textSize
    let fontStyle =
      style == .object([:])
      ? JSONValue.object(["font_family": .string(family), "size": .number(size)]) : style
    font =
      NSFont(name: CTFontCopyPostScriptName(VectorText.font(fontStyle)) as String, size: size)
      ?? NSFont.systemFont(ofSize: size)
    transform =
      node?.raw["kind"]["xf"].affine ?? CGAffineTransform(translationX: origin.x, y: origin.y)
    self.area =
      node.flatMap(VectorText.areaRect) ?? area.map { CGRect(origin: .zero, size: $0.size) }
    fill =
      node == nil
      ? (canvas.state.fillEnabled ? canvas.state.style.fill : VectorStyle.solid(0, 0, 0))
      : style["fill"]
    layer = canvas.state.insertionContainer(in: canvas.drawing)
    super.init()
    textView.editor = self
    textView.isRichText = false
    textView.importsGraphics = false
    textView.drawsBackground = false
    textView.textContainerInset = .zero
    textView.textContainer?.lineFragmentPadding = 0
    textView.textContainer?.widthTracksTextView = false
    textView.textContainer?.heightTracksTextView = false
    textView.textContainer?.containerSize =
      self.area?.size ?? CGSize(width: 1_000_000, height: 1_000_000)
    textView.isVerticallyResizable = false
    textView.isHorizontallyResizable = false
    textView.allowsUndo = true
    textView.isAutomaticQuoteSubstitutionEnabled = false
    textView.isAutomaticDashSubstitutionEnabled = false
    textView.isAutomaticTextReplacementEnabled = false
    textView.setAccessibilityLabel(self.area == nil ? "Edit Point Text" : "Edit Area Text")
    var attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: NSColor(cgColor: VectorRenderer.color(fill["color"])) ?? .black,
      .kern: (style["tracking"].double ?? 0) * size / 1000,
      .baselineOffset: style["baseline_shift"].double ?? 0,
    ]
    if self.area == nil {
      let paragraph = NSMutableParagraphStyle()
      paragraph.minimumLineHeight = style["leading"].double ?? size * 1.2
      paragraph.maximumLineHeight = paragraph.minimumLineHeight
      attributes[.paragraphStyle] = paragraph
    }
    textView.textStorage?.setAttributedString(
      NSAttributedString(
        string: node?.raw["kind"]["runs"].array.first?["text"].string ?? "", attributes: attributes)
    )
    textView.typingAttributes = attributes
    textView.insertionPointColor = .black
    textView.delegate = self
    container.addSubview(textView)
    canvas.addSubview(container)
    canvas.state.textEditingSession = session
    updateGeometry()
  }

  func focus(event: NSEvent?) {
    canvas?.window?.makeFirstResponder(textView)
    textView.setSelectedRange(NSRange(location: textView.string.utf16.count, length: 0))
    if let event, canvas?.window != nil { textView.mouseDown(with: event) }
  }

  func matches(_ node: VectorNode) -> Bool {
    let runs = node.raw["kind"]["runs"].array
    guard runs.count == 1, let run = runs.first else { return false }
    return run["text"].string == textView.string
      && run["style"]["font_family"].string == family
      && run["style"]["size"].double == size
      && run["style"]["fill"] == fill
      && node.raw["kind"]["xf"].affine == transform
      && VectorText.areaRect(node) == area
  }

  func textDidChange(_ notification: Notification) {
    guard let canvas else { return }
    let text = textView.string
    if let id = nodeID {
      canvas.command(.editText(id, text, font: family, size: size))
    } else if !text.isEmpty {
      if let area {
        canvas.command(
          .addAreaText(
            text, CGRect(origin: CGPoint(x: transform.tx, y: transform.ty), size: area.size),
            font: family, size: size, fill: fill, layer: layer))
      } else {
        canvas.command(
          .addText(
            text, CGPoint(x: transform.tx, y: transform.ty), font: family,
            size: size, fill: fill, layer: layer))
      }
      nodeID = canvas.state.selection.first
    }
    updateGeometry()
    canvas.needsDisplay = true
  }

  func textView(
    _ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange,
    replacementString: String?
  ) -> Bool {
    let count =
      textView.string.utf16.count - affectedCharRange.length + (replacementString?.utf16.count ?? 0)
    guard count <= 100_000 else {
      canvas?.state.error = "Text objects are limited to 100,000 characters."
      return false
    }
    return true
  }

  func updateGeometry() {
    guard let canvas else { return }
    textView.layoutManager?.ensureLayout(for: textView.textContainer ?? NSTextContainer())
    let used = textView.textContainer.flatMap { textView.layoutManager?.usedRect(for: $0) } ?? .zero
    let baseline = textView.layoutManager?.defaultBaselineOffset(for: font) ?? font.ascender
    let local =
      area
      ?? CGRect(
        x: 0, y: -baseline, width: max(size, used.maxX + 4),
        height: max(size * 1.2, used.maxY + 4))
    let scaleX = hypot(transform.a, transform.b)
    let scaleY = hypot(transform.c, transform.d)
    container.frameRotation = 0
    container.frame = CGRect(
      origin: canvas.toView(local.origin.applying(transform)),
      size: CGSize(
        width: local.width * canvas.zoom * scaleX,
        height: local.height * canvas.zoom * scaleY))
    container.bounds = CGRect(origin: .zero, size: local.size)
    container.frameRotation = atan2(transform.b, transform.a) * 180 / .pi
    textView.frame = container.bounds
    container.wantsLayer = true
    container.layer?.masksToBounds = true
    container.layer?.borderWidth = 1 / max(0.005, canvas.zoom * scaleX)
    container.layer?.borderColor = WorkspaceTheme.selection.cgColor
    if let textContainer = textView.textContainer, let manager = textView.layoutManager {
      let visible = manager.characterRange(
        forGlyphRange: manager.glyphRange(for: textContainer), actualGlyphRange: nil)
      container.overset = area != nil && visible.upperBound < textView.string.utf16.count
    }
  }

  func detach() {
    textView.delegate = nil
    if canvas?.window?.firstResponder === textView { canvas?.window?.makeFirstResponder(canvas) }
    container.removeFromSuperview()
  }
}

final class FlippedTextContainer: NSView {
  var overset = false { didSet { needsDisplay = true } }
  override var isFlipped: Bool { true }
  override func draw(_ dirtyRect: NSRect) {
    if overset {
      NSColor.systemRed.setFill()
      CGRect(x: bounds.maxX - 9, y: bounds.maxY - 9, width: 9, height: 9).fill()
      ("+" as NSString).draw(
        at: CGPoint(x: bounds.maxX - 9, y: bounds.maxY - 11),
        withAttributes: [.font: NSFont.boldSystemFont(ofSize: 10), .foregroundColor: NSColor.white])
    }
  }
}

final class CanvasTextView: NSTextView {
  weak var editor: CanvasTextEditor?
  private let typingUndo = UndoManager()
  override var undoManager: UndoManager? { typingUndo }
  override func cancelOperation(_ sender: Any?) {
    let canvas = editor?.canvas
    canvas?.finishTextEditing()
    canvas?.state.tool = .select
  }
  override func keyDown(with event: NSEvent) {
    if event.keyCode == 36 && event.modifierFlags.contains(.command) {
      cancelOperation(nil)
    } else {
      super.keyDown(with: event)
    }
  }
  override func resignFirstResponder() -> Bool {
    let result = super.resignFirstResponder()
    if result { editor?.canvas?.finishTextEditing() }
    return result
  }
}
