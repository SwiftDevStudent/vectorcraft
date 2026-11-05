import AppKit
import Testing
import VectorCraftCore

@testable import VectorCraftMac

@MainActor
struct GradientInteractionTests {
  @Test func newRampOriginAndEndpointBothUseTheGrid() throws {
    let f = try Fixture()
    f.state.snapToGrid = true
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, CGPoint(x: 103, y: 107)))
    f.canvas.mouseUp(with: try f.event(.leftMouseUp, CGPoint(x: 252, y: 137)))
    let paint = try f.gradient(in: f.document.drawing)
    #expect(paint.start == CGPoint(x: 100, y: 110))
    #expect(paint.end == CGPoint(x: 250, y: 140))
  }
  @Test func constrainedCanvasRampPreviewsWithoutSavingAndCommitsOneUndoStep() throws {
    let f = try Fixture()
    let original = f.document.drawing
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, CGPoint(x: 100, y: 100)))
    f.canvas.mouseDragged(with: try f.event(.leftMouseDragged, CGPoint(x: 200, y: 160), [.shift]))
    #expect(f.document.drawing == original && !f.undo.canUndo)
    let preview = try f.gradient(in: f.canvas.displayedDrawing)
    #expect(preview.start == CGPoint(x: 100, y: 100) && preview.end == CGPoint(x: 180, y: 180))
    f.canvas.mouseUp(with: try f.event(.leftMouseUp, CGPoint(x: 200, y: 160), [.shift]))
    #expect(try f.gradient(in: f.document.drawing).raw == preview.raw)
    #expect(f.undo.undoActionName == "Change Gradient")
    let saved = f.document.drawing
    f.undo.undo()
    f.sync()
    #expect(f.document.drawing == original && !f.undo.canUndo)
    f.undo.redo()
    f.sync()
    #expect(f.document.drawing == saved && !f.undo.canRedo)
    #expect(try NativeFormat.decode(NativeFormat.encode(saved)).layers == saved.layers)
  }

  @Test func endpointDraggingSnapsAndEscapeDiscardsThePreview() throws {
    let f = try Fixture()
    try f.run(.gradient([f.id], .fill, .kind(.linear)))
    try f.run(.gradient([f.id], .fill, .geometry(CGPoint(x: 100, y: 100), CGPoint(x: 200, y: 100))))
    f.undo.removeAllActions()
    f.state.snapToGrid = true
    let original = f.document.drawing
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, CGPoint(x: 200, y: 100)))
    f.canvas.mouseDragged(with: try f.event(.leftMouseDragged, CGPoint(x: 253, y: 137)))
    let preview = try f.gradient(in: f.canvas.displayedDrawing)
    #expect(preview.end == CGPoint(x: 250, y: 140))
    let escape = try #require(
      NSEvent.keyEvent(
        with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0,
        context: nil, characters: "\u{1b}", charactersIgnoringModifiers: "\u{1b}", isARepeat: false,
        keyCode: 53))
    f.canvas.keyDown(with: escape)
    #expect(f.canvas.displayedDrawing == original && f.document.drawing == original)
    #expect(f.state.selection == [f.id] && !f.undo.canUndo)
    f.canvas.mouseUp(with: try f.event(.leftMouseUp, CGPoint(x: 253, y: 137)))
    #expect(f.document.drawing == original && !f.undo.canUndo)
  }

  @Test func stopDraggingAndDeleteRouteToGradientCommandsWithUndo() throws {
    let f = try Fixture()
    try f.run(.gradient([f.id], .fill, .kind(.linear)))
    try f.run(.gradient([f.id], .fill, .geometry(CGPoint(x: 100, y: 100), CGPoint(x: 300, y: 100))))
    try f.run(.gradient([f.id], .fill, .insertStop(0.5)))
    f.undo.removeAllActions()
    // Move the first stop past the middle stop; selection must follow its new index.
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, CGPoint(x: 100, y: 112)))
    f.canvas.mouseDragged(with: try f.event(.leftMouseDragged, CGPoint(x: 250, y: 112)))
    f.canvas.mouseUp(with: try f.event(.leftMouseUp, CGPoint(x: 250, y: 112)))
    #expect(f.state.gradientStop == 1)
    #expect(try f.gradient(in: f.document.drawing).stops[1]["offset"].double == 0.75)
    let moved = f.document.drawing
    let key = try #require(
      NSEvent.keyEvent(
        with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0,
        context: nil, characters: "\u{7f}", charactersIgnoringModifiers: "\u{7f}", isARepeat: false,
        keyCode: 51))
    f.canvas.keyDown(with: key)
    #expect(f.document.drawing.node(f.id) != nil)
    #expect(try f.gradient(in: f.document.drawing).stops.count == 2)
    #expect(f.state.gradientStop == 1)
    f.undo.undo()
    f.sync()
    #expect(f.document.drawing == moved)
    f.state.gradientTarget = .stroke
    #expect(f.state.gradientStop == 0)
  }

  @MainActor private final class Fixture {
    let document: CanvasDocument
    let state = EditorState()
    let canvas = VectorCanvasView(frame: CGRect(x: 0, y: 0, width: 800, height: 800))
    let undo = UndoManager()
    let id: Int64
    init() throws {
      var drawing = Drawing()
      id = try #require(
        try drawing.perform(
          .addPath(
            [ShapePaths.rectangle(CGRect(x: 20, y: 20, width: 400, height: 300))], VectorStyle(),
            layer: 1)
        ).first)
      document = CanvasDocument(drawing: drawing)
      state.selection = [id]
      state.tool = .gradient
      state.smartGuides = false
      state.snapHaptics = false
      undo.groupsByEvent = false
      sync()
      canvas.layout()
      state.canvasAction = .actualSize
      sync()
      state.canvasAction = nil
      sync()
    }
    func sync() {
      if let node = document.drawing.node(id) { state.loadStyle(node) }
      canvas.update(drawing: document.drawing, state: state) { [weak self] command in
        do { try self?.run(command) } catch { Issue.record(error) }
      }
    }
    func run(_ command: DrawingCommand) throws {
      undo.beginUndoGrouping()
      defer { undo.endUndoGrouping() }
      state.selection = try document.execute(command, undoManager: undo)
      sync()
    }
    func gradient(in drawing: Drawing) throws -> GradientPaint {
      let node = try #require(drawing.node(id))
      return try GradientPaint(GradientPaint.paint(of: node, target: .fill), bounds: node.bounds)
    }
    func event(_ type: NSEvent.EventType, _ point: CGPoint, _ modifiers: NSEvent.ModifierFlags = [])
      throws -> NSEvent
    {
      try #require(
        NSEvent.mouseEvent(
          with: type, location: canvas.convert(canvas.toView(point), to: nil),
          modifierFlags: modifiers, timestamp: 0, windowNumber: 0, context: nil, eventNumber: 0,
          clickCount: 1, pressure: 1))
    }
  }
}
