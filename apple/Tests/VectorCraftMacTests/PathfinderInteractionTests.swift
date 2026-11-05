import AppKit
import Testing
import VectorCraftCore

@testable import VectorCraftMac

@MainActor
struct PathfinderInteractionTests {
  @Test func pathfinderCommandsSaveAndUndoTheWholeOperation() throws {
    var drawing = Drawing()
    let a = try drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 20, y: 20, width: 100, height: 100))], VectorStyle(),
        layer: 1))
    let b = try drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 70, y: 70, width: 100, height: 100))], VectorStyle(),
        layer: 1))
    let original = drawing
    let document = CanvasDocument(drawing: drawing)
    let undo = UndoManager()
    undo.groupsByEvent = false
    undo.beginUndoGrouping()
    let output = try document.execute(.pathfinder(a.union(b), .divide), undoManager: undo)
    undo.endUndoGrouping()
    let divided = document.drawing
    let group = try #require(output.first.flatMap(divided.node))
    #expect(group.children.count == 3)
    let reopened = try NativeFormat.decode(NativeFormat.encode(divided))
    #expect(reopened.envelope["document"] == divided.envelope["document"])
    undo.undo()
    #expect(document.drawing == original)
    undo.redo()
    #expect(document.drawing == divided)
  }

  @Test func compoundConstituentAnchorsEditThroughTheActualCanvas() throws {
    var drawing = Drawing(width: 740, height: 540)
    let outer = try drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 50, y: 50, width: 200, height: 200))], VectorStyle(),
        layer: 1))
    let inner = try drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 100, y: 100, width: 50, height: 50))], VectorStyle(),
        layer: 1))
    let innerID = try #require(inner.first)
    drawing.updateNode(innerID) { $0["unknown"]["nativeNote"] = .string("keep") }
    let compound = try drawing.perform(.makeCompound(outer.union(inner)))
    let state = EditorState()
    state.selection = compound
    state.tool = .nodes
    state.smartGuides = false
    let canvas = VectorCanvasView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
    canvas.update(drawing: drawing, state: state) { command in
      do { state.selection = try drawing.perform(command) } catch { Issue.record(error) }
    }
    canvas.layout()
    func event(_ type: NSEvent.EventType, _ point: CGPoint) throws -> NSEvent {
      let location = canvas.convert(canvas.toView(point), to: nil)
      return try #require(
        NSEvent.mouseEvent(
          with: type, location: location, modifierFlags: [], timestamp: 0, windowNumber: 0,
          context: nil, eventNumber: 0, clickCount: 1, pressure: 1))
    }
    canvas.mouseDown(with: try event(.leftMouseDown, CGPoint(x: 100, y: 100)))
    canvas.mouseDragged(with: try event(.leftMouseDragged, CGPoint(x: 110, y: 120)))
    canvas.mouseUp(with: try event(.leftMouseUp, CGPoint(x: 110, y: 120)))
    let anchor = try #require(drawing.node(innerID)?.subpaths.first?.anchors.first)
    #expect(anchor.point.distance(to: CGPoint(x: 110, y: 120)) < 0.000001)
    #expect(state.selection == compound)
    #expect(drawing.node(innerID)?.raw["unknown"]["nativeNote"].string == "keep")
  }
}
