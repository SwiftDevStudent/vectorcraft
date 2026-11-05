import AppKit
import Testing
import VectorCraftCore

@testable import VectorCraftMac

@MainActor
struct SelectionInteractionTests {
  @Test func nativeSelectAllTargetsEditableTopLevelArtwork() throws {
    var drawing = Drawing()
    func add() throws -> Set<Int64> {
      try drawing.perform(
        .addPath(
          [ShapePaths.rectangle(CGRect(x: 20, y: 20, width: 50, height: 50))], VectorStyle(),
          layer: 1))
    }
    let first = try add()
    let second = try add()
    let group = try drawing.perform(.group(first.union(second)))
    let visible = try add()
    let hidden = try #require(try add().first)
    let locked = try #require(try add().first)
    drawing.updateNode(hidden) { $0["visible"] = .bool(false) }
    drawing.updateNode(locked) { $0["locked"] = .bool(true) }
    let state = EditorState()
    let canvas = VectorCanvasView()
    canvas.update(drawing: drawing, state: state, command: { _ in })
    #expect(canvas.tryToPerform(#selector(NSText.selectAll(_:)), with: nil))
    #expect(state.selection == group.union(visible))
    #expect(canvas.drawing == drawing)
  }

  @Test func selectAllInInlineTextSelectsCharactersAndKeepsArtworkSelection() throws {
    var drawing = Drawing()
    let text = "Select this text"
    let ids = try drawing.perform(
      .addText(
        text, CGPoint(x: 100, y: 100), font: "Helvetica", size: 24,
        fill: VectorStyle.solid(0, 0, 0), layer: 1))
    let state = EditorState()
    state.selection = ids
    let canvas = VectorCanvasView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
    canvas.update(drawing: drawing, state: state, command: { _ in })
    canvas.layout()
    let id = try #require(ids.first)
    canvas.beginTextEditing(id: id)
    let editor = try #require(canvas.textEditor?.textView)
    #expect(editor.tryToPerform(#selector(NSText.selectAll(_:)), with: nil))
    #expect(editor.selectedRange() == NSRange(location: 0, length: text.utf16.count))
    #expect(state.selection == ids)
    #expect(canvas.drawing == drawing)
  }
}
