import AppKit
import Testing
import VectorCraftCore

@testable import VectorCraftMac

@MainActor
struct EditorTests {
  @Test func penCreatesVisibleCurvesAfterSelectingUnstrokedText() throws {
    let canvas = VectorCanvasView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
    let state = EditorState()
    state.tool = .pen
    state.style = VectorStyle(stroke: VectorStyle.none, width: 0)
    var drawing = Drawing()
    let perform: (DrawingCommand) -> Void = { command in
      do { state.selection = try drawing.perform(command) } catch { Issue.record(error) }
    }
    canvas.update(drawing: drawing, state: state, command: perform)
    canvas.layout()
    func event(_ type: NSEvent.EventType, _ point: CGPoint) throws -> NSEvent {
      try #require(
        NSEvent.mouseEvent(
          with: type, location: point, modifierFlags: [], timestamp: 0, windowNumber: 0,
          context: nil, eventNumber: 0, clickCount: 1, pressure: 1))
    }
    canvas.mouseDown(with: try event(.leftMouseDown, CGPoint(x: 250, y: 250)))
    canvas.mouseDragged(with: try event(.leftMouseDragged, CGPoint(x: 290, y: 210)))
    canvas.mouseUp(with: try event(.leftMouseUp, CGPoint(x: 290, y: 210)))
    canvas.mouseDown(with: try event(.leftMouseDown, CGPoint(x: 450, y: 350)))
    canvas.mouseUp(with: try event(.leftMouseUp, CGPoint(x: 450, y: 350)))
    state.canvasAction = .finishPath
    canvas.update(drawing: drawing, state: state, command: perform)
    let id = try #require(state.selection.first)
    let node = try #require(drawing.node(id))
    let style = VectorStyle(node: node)
    #expect(style.stroke["type"].string == "solid" && style.width > 0)
    let anchor = try #require(node.subpaths.first?.anchors.first)
    #expect(anchor.outgoing != anchor.point)
  }
  @Test func documentCommandsRegisterUndoAndRedo() throws {
    let document = CanvasDocument()
    let undo = UndoManager()
    undo.groupsByEvent = false
    undo.beginUndoGrouping()
    let ids = try document.execute(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 0, y: 0, width: 100, height: 100))], VectorStyle(), layer: 1
      ), undoManager: undo)
    undo.endUndoGrouping()
    let id = try #require(ids.first)
    #expect(document.drawing.node(id) != nil)
    #expect(undo.canUndo)
    undo.undo()
    #expect(document.drawing.node(id) == nil)
    #expect(undo.canRedo)
    undo.redo()
    #expect(document.drawing.node(id)?.bounds == CGRect(x: 0, y: 0, width: 100, height: 100))
  }

  @Test func nativeCanvasMouseEventsCreateMoveAndEditGeometry() throws {
    let canvas = VectorCanvasView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
    let state = EditorState()
    state.tool = .rectangle
    var drawing = Drawing()
    canvas.update(
      drawing: drawing, state: state,
      command: { command in
        do { state.selection = try drawing.perform(command) } catch { Issue.record(error) }
      })
    canvas.layout()
    func mouse(_ type: NSEvent.EventType, _ point: CGPoint) throws -> NSEvent {
      try #require(
        NSEvent.mouseEvent(
          with: type, location: point, modifierFlags: [], timestamp: 0, windowNumber: 0,
          context: nil, eventNumber: 0, clickCount: 1, pressure: 1))
    }
    canvas.mouseDown(with: try mouse(.leftMouseDown, CGPoint(x: 300, y: 240)))
    canvas.mouseDragged(with: try mouse(.leftMouseDragged, CGPoint(x: 450, y: 360)))
    canvas.mouseUp(with: try mouse(.leftMouseUp, CGPoint(x: 450, y: 360)))
    let id = try #require(state.selection.first)
    let original = try #require(drawing.node(id)?.bounds)
    #expect(original.width > 100 && original.height > 100)
    state.tool = .select
    canvas.update(
      drawing: drawing, state: state,
      command: { command in
        do { state.selection = try drawing.perform(command) } catch { Issue.record(error) }
      })
    canvas.mouseDown(with: try mouse(.leftMouseDown, CGPoint(x: 375, y: 300)))
    canvas.mouseDragged(with: try mouse(.leftMouseDragged, CGPoint(x: 395, y: 315)))
    canvas.mouseUp(with: try mouse(.leftMouseUp, CGPoint(x: 395, y: 315)))
    #expect(drawing.node(id)?.bounds.minX != original.minX)
    let anchorsBefore = try #require(drawing.node(id)?.subpaths.first?.anchors.map(\.point))
    state.tool = .nodes
    canvas.update(
      drawing: drawing, state: state,
      command: { command in
        do { state.selection = try drawing.perform(command) } catch { Issue.record(error) }
      })
    canvas.mouseDown(with: try mouse(.leftMouseDown, CGPoint(x: 320, y: 255)))
    canvas.mouseDragged(with: try mouse(.leftMouseDragged, CGPoint(x: 340, y: 230)))
    canvas.mouseUp(with: try mouse(.leftMouseUp, CGPoint(x: 340, y: 230)))
    #expect(drawing.node(id)?.subpaths.first?.anchors.map(\.point) != anchorsBefore)
    let reopened = try NativeFormat.decode(NativeFormat.encode(drawing))
    #expect(reopened.node(id)?.bounds == drawing.node(id)?.bounds)
  }
}
