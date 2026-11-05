import AppKit
import Testing
import VectorCraftCore

@testable import VectorCraftMac

@MainActor
struct TextInteractionTests {
  @Test func doubleClickStartsAnInlineEditor() throws {
    var drawing = Drawing(width: 740, height: 540)
    try drawing.perform(
      .addText(
        "Edit me", CGPoint(x: 200, y: 200), font: "Helvetica",
        size: 32, fill: VectorStyle.solid(0, 0, 0), layer: 1))
    let canvas = VectorCanvasView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
    canvas.update(drawing: drawing, state: EditorState(), command: { _ in })
    canvas.layout()
    let location = canvas.convert(CGPoint(x: 245, y: 215), to: nil)
    canvas.mouseDown(with: try mouse(.leftMouseDown, location, clicks: 2))
    #expect(
      canvas.subviews.contains { $0 is NSTextView || $0.subviews.contains { $0 is NSTextView } })
  }

  @Test func typeDragCreatesInlineAreaEditor() throws {
    let state = EditorState()
    state.tool = .text
    let canvas = VectorCanvasView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
    canvas.update(drawing: Drawing(width: 740, height: 540), state: state, command: { _ in })
    canvas.layout()
    canvas.mouseDown(with: try mouse(.leftMouseDown, CGPoint(x: 200, y: 200)))
    canvas.mouseDragged(with: try mouse(.leftMouseDragged, CGPoint(x: 400, y: 340)))
    canvas.mouseUp(with: try mouse(.leftMouseUp, CGPoint(x: 400, y: 340)))
    #expect(
      canvas.subviews.contains { $0 is NSTextView || $0.subviews.contains { $0 is NSTextView } })
  }

  @Test func typingSavesLiveAndOneDocumentUndoRestoresTheSession() throws {
    var drawing = Drawing(width: 740, height: 540)
    let ids = try drawing.perform(
      .addText(
        "Original", CGPoint(x: 200, y: 200), font: "Helvetica",
        size: 32, fill: VectorStyle.solid(0, 0, 0), layer: 1))
    let id = try #require(ids.first)
    let document = CanvasDocument(drawing: drawing)
    let undo = UndoManager()
    undo.groupsByEvent = false
    let state = EditorState()
    let canvas = VectorCanvasView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
    canvas.update(
      drawing: drawing, state: state,
      command: { command in
        do {
          state.selection = try document.execute(
            command, undoManager: undo, coalescingTextSession: state.textEditingSession)
        } catch { Issue.record(error) }
      })
    canvas.layout()
    canvas.beginTextEditing(id: id)
    let textView = try #require(canvas.textEditor?.textView)
    textView.setSelectedRange(NSRange(location: 0, length: textView.string.utf16.count))
    undo.beginUndoGrouping()
    textView.insertText("Replacement", replacementRange: textView.selectedRange())
    undo.endUndoGrouping()
    // Later keystrokes update the live snapshot without opening another document undo group.
    textView.insertText(" saved live", replacementRange: textView.selectedRange())
    let reopened = try NativeFormat.decode(NativeFormat.encode(document.drawing))
    #expect(
      reopened.node(id)?.raw["kind"]["runs"].array.first?["text"].string == "Replacement saved live"
    )
    canvas.finishTextEditing()
    undo.undo()
    #expect(
      document.drawing.node(id)?.raw["kind"]["runs"].array.first?["text"].string == "Original")
    undo.redo()
    #expect(
      document.drawing.node(id)?.raw["kind"]["runs"].array.first?["text"].string
        == "Replacement saved live")
  }

  private func mouse(_ type: NSEvent.EventType, _ point: CGPoint, clicks: Int = 1) throws -> NSEvent
  {
    try #require(
      NSEvent.mouseEvent(
        with: type, location: point, modifierFlags: [], timestamp: 0,
        windowNumber: 0, context: nil, eventNumber: 0,
        clickCount: clicks, pressure: 1))
  }
}
