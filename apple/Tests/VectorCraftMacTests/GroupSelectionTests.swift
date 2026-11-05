import AppKit
import Testing
import VectorCraftCore

@testable import VectorCraftMac

@MainActor
struct GroupSelectionTests {
  @Test func selectionClickAndDragMoveTheWholeGroupWithOneUndo() throws {
    let f = try Fixture()
    let original = f.document.drawing
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, CGPoint(x: 100, y: 90)))
    #expect(f.state.selection == [f.group])
    f.canvas.mouseUp(with: try f.event(.leftMouseUp, CGPoint(x: 120, y: 105)))
    #expect(
      (f.document.drawing.node(f.first)?.bounds.origin.distance(to: CGPoint(x: 70, y: 65)) ?? 1)
        < 0.000001)
    #expect(
      (f.document.drawing.node(f.second)?.bounds.origin.distance(to: CGPoint(x: 240, y: 65)) ?? 1)
        < 0.000001)
    #expect(f.document.drawing.node(f.outside) == original.node(f.outside))
    #expect(f.document.drawing.node(f.first)?.raw["unknown"]["keep"].string == "inside")
    f.undo.undo()
    #expect(f.document.drawing == original)
  }

  @Test(arguments: [false, true])
  func marqueeTouchingOneMemberSelectsTheWholeGroup(_ dragEvent: Bool) throws {
    let f = try Fixture()
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, CGPoint(x: 40, y: 40)))
    if dragEvent {
      f.canvas.mouseDragged(with: try f.event(.leftMouseDragged, CGPoint(x: 55, y: 55)))
    }
    f.canvas.mouseUp(with: try f.event(.leftMouseUp, CGPoint(x: 60, y: 60)))
    #expect(f.state.selection == [f.group])
  }

  @Test func directSelectionCanStillEditAConstituentAnchor() throws {
    let f = try Fixture()
    f.state.tool = .nodes
    let original = f.document.drawing
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, CGPoint(x: 51, y: 51)))
    #expect(f.state.selection == [f.first])
    f.canvas.mouseUp(with: try f.event(.leftMouseUp, CGPoint(x: 71, y: 61)))
    #expect(
      f.document.drawing.node(f.first)?.subpaths.first?.anchors.first?.point
        == CGPoint(x: 70, y: 60))
    #expect(f.document.drawing.node(f.second) == original.node(f.second))
    #expect(f.document.drawing.node(f.group)?.children.count == 2)
  }

  @Test func nestedIsolationScopesCreationUndoAndEscapeWithoutChangingNativeCoordinates() throws {
    let f = try Fixture()
    let nestedIDs = try f.document.drawing.perform(.group([f.first, f.second]))
    let nested = try #require(nestedIDs.first)
    f.refresh()
    for expected in [[f.group], [f.group, nested]] {
      f.canvas.mouseDown(with: try f.event(.leftMouseDown, CGPoint(x: 100, y: 90), clicks: 2))
      f.canvas.mouseUp(with: try f.event(.leftMouseUp, CGPoint(x: 100, y: 90), clicks: 2))
      #expect(f.state.isolationStack == expected)
      f.refresh()
    }
    f.canvas.selectAll(nil)
    #expect(f.state.selection == [f.first, f.second])
    let outside = f.document.drawing.node(f.outside)
    f.state.tool = .rectangle
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, CGPoint(x: 300, y: 100)))
    f.canvas.mouseUp(with: try f.event(.leftMouseUp, CGPoint(x: 400, y: 180)))
    let created = try #require(f.state.selection.first)
    #expect(f.document.drawing.node(nested)?.children.count == 3)
    #expect(
      f.document.drawing.node(created)?.bounds == CGRect(x: 300, y: 100, width: 100, height: 80))
    #expect(f.document.drawing.node(f.outside) == outside)
    f.undo.undo()
    #expect(f.document.drawing.node(created) == nil)
    f.undo.redo()
    f.refresh()
    let saved = f.document.drawing
    let reopened = try NativeFormat.decode(NativeFormat.encode(saved))
    #expect(reopened.envelope["document"] == saved.envelope["document"])
    f.canvas.keyDown(with: try escape())
    #expect(f.state.isolationStack == [f.group])
    #expect(f.state.selection == [nested])
    f.refresh()
    f.canvas.keyDown(with: try escape())
    #expect(f.state.isolationStack.isEmpty && f.state.selection == [f.group])
    #expect(f.document.drawing == saved)
  }

  @Test func inlineTextIsInsertedInsideIsolationAndOutsideCommandsCannotRegisterUndo() throws {
    let f = try Fixture()
    #expect(f.state.enterIsolation(f.group, in: f.document.drawing))
    f.refresh()
    let original = f.document.drawing
    #expect(throws: DrawingError.self) {
      try f.document.execute(.delete([f.outside]), undoManager: f.undo, within: f.state.isolationID)
    }
    #expect(f.document.drawing == original && !f.undo.canUndo)
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, CGPoint(x: 550, y: 340)))
    f.canvas.mouseUp(with: try f.event(.leftMouseUp, CGPoint(x: 550, y: 340)))
    #expect(f.state.selection.isEmpty && f.state.isolationID == f.group)
    f.state.tool = .text
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, CGPoint(x: 300, y: 200)))
    f.canvas.mouseUp(with: try f.event(.leftMouseUp, CGPoint(x: 300, y: 200)))
    let editor = try #require(f.canvas.textEditor?.textView)
    editor.insertText("Scoped text", replacementRange: editor.selectedRange())
    let id = try #require(f.state.selection.first)
    #expect(f.document.drawing.isInside(id, isolation: f.group))
    #expect(
      f.document.drawing.node(id)?.raw["kind"]["runs"].array.first?["text"].string == "Scoped text")
    #expect(f.document.drawing.node(f.outside) == original.node(f.outside))
    f.canvas.finishTextEditing()
  }

  @Test func invalidIsolationScopesReconcileAfterDocumentChanges() throws {
    let f = try Fixture()
    let nested = try #require(try f.document.drawing.perform(.group([f.first, f.second])).first)
    #expect(f.state.enterIsolation(f.group, in: f.document.drawing))
    #expect(f.state.enterIsolation(nested, in: f.document.drawing))
    f.state.selection = [f.outside]
    f.state.reconcileIsolation(in: f.document.drawing)
    #expect(f.state.selection.isEmpty)
    try f.document.drawing.perform(.ungroup(nested))
    f.state.reconcileIsolation(in: f.document.drawing)
    #expect(f.state.isolationStack == [f.group])
    try f.document.drawing.perform(.lock(f.group, true))
    f.state.reconcileIsolation(in: f.document.drawing)
    #expect(f.state.isolationStack.isEmpty)
  }

  private func escape() throws -> NSEvent {
    try #require(
      NSEvent.keyEvent(
        with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0,
        context: nil, characters: "\u{1b}", charactersIgnoringModifiers: "\u{1b}", isARepeat: false,
        keyCode: 53))
  }

  @MainActor private final class Fixture {
    let document: CanvasDocument
    let state = EditorState()
    let undo = UndoManager()
    let canvas = VectorCanvasView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
    let first: Int64
    let second: Int64
    let group: Int64
    let outside: Int64
    init() throws {
      var drawing = Drawing()
      let a = try drawing.perform(
        .addPath(
          [ShapePaths.rectangle(CGRect(x: 50, y: 50, width: 100, height: 80))], VectorStyle(),
          layer: 1))
      let b = try drawing.perform(
        .addPath(
          [ShapePaths.rectangle(CGRect(x: 220, y: 50, width: 40, height: 40))], VectorStyle(),
          layer: 1))
      first = try #require(a.first)
      second = try #require(b.first)
      drawing.updateNode(first) { $0["unknown"]["keep"] = .string("inside") }
      let grouped = try drawing.perform(.group(a.union(b)))
      group = try #require(grouped.first)
      let external = try drawing.perform(
        .addPath(
          [ShapePaths.rectangle(CGRect(x: 500, y: 300, width: 100, height: 80))], VectorStyle(),
          layer: 1))
      outside = try #require(external.first)
      document = CanvasDocument(drawing: drawing)
      state.smartGuides = false
      undo.groupsByEvent = false
      refresh()
      canvas.layout()
    }
    func refresh() {
      state.reconcileIsolation(in: document.drawing)
      canvas.update(drawing: document.drawing, state: state) { [weak self] command in
        guard let self else { return }
        do {
          undo.beginUndoGrouping()
          defer { undo.endUndoGrouping() }
          state.selection = try document.execute(
            command, undoManager: undo, coalescingTextSession: state.textEditingSession,
            within: state.isolationID)
        } catch { Issue.record(error) }
      }
    }
    func event(_ type: NSEvent.EventType, _ point: CGPoint, clicks: Int = 1) throws -> NSEvent {
      try #require(
        NSEvent.mouseEvent(
          with: type, location: canvas.convert(canvas.toView(point), to: nil), modifierFlags: [],
          timestamp: 0, windowNumber: 0, context: nil, eventNumber: 0, clickCount: clicks,
          pressure: 1))
    }
  }
}
