import AppKit
import Testing
import VectorCraftCore

@testable import VectorCraftMac

@MainActor
struct TransformInteractionTests {
  @Test func shiftClickTogglesButShiftDragRetainsAndConstrainsTheSelection() throws {
    let f = try Fixture()
    let start = CGPoint(x: 103, y: 107)
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, start, .shift))
    #expect(f.state.selection == [f.id])
    f.canvas.mouseUp(with: try f.event(.leftMouseUp, start, .shift))
    #expect(f.state.selection.isEmpty)
    f.state.selection = [f.id]
    f.refresh()
    f.state.snapToGrid = true
    let end = CGPoint(x: 143, y: 114)
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, start, .shift))
    f.canvas.mouseDragged(with: try f.event(.leftMouseDragged, end, .shift))
    try expectRect(
      f.canvas.displayedDrawing.node(f.id)?.bounds,
      CGRect(x: 90, y: 67, width: 100, height: 80))
    f.canvas.mouseUp(with: try f.event(.leftMouseUp, end, .shift))
    try expectRect(
      f.document.drawing.node(f.id)?.bounds, CGRect(x: 90, y: 67, width: 100, height: 80))
    #expect(f.state.selection == [f.id])
  }

  @Test func optionDragCopiesInOneUndoStepAndPreviewLeavesTheOriginalInPlace() throws {
    let f = try Fixture()
    let original = f.document.drawing
    let start = CGPoint(x: 103, y: 107)
    let end = CGPoint(x: 143, y: 137)
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, start, .option))
    f.canvas.mouseDragged(with: try f.event(.leftMouseDragged, end, .option))
    #expect(f.document.drawing == original)
    #expect(f.canvas.displayedDrawing.layers.first?.children.count == 2)
    try expectRect(f.canvas.displayedDrawing.node(f.id)?.bounds, f.originalBounds)
    let previewed = f.canvas.displayedSelection.first.flatMap(f.canvas.displayedDrawing.node)
    try expectRect(previewed?.bounds, CGRect(x: 93, y: 97, width: 100, height: 80))
    f.canvas.mouseUp(with: try f.event(.leftMouseUp, end, .option))
    let id = try #require(f.state.selection.first)
    #expect(id != f.id)
    #expect(f.document.drawing.layers.first?.children.map(\.id) == [f.id, id])
    try expectRect(f.document.drawing.node(f.id)?.bounds, f.originalBounds)
    try expectRect(
      f.document.drawing.node(id)?.bounds, CGRect(x: 93, y: 97, width: 100, height: 80))
    #expect(f.document.drawing.node(id)?.raw["unknown"]["keep"].string == "original metadata")
    let copied = f.document.drawing
    let reopened = try NativeFormat.decode(NativeFormat.encode(copied))
    #expect(reopened.envelope["document"] == copied.envelope["document"])
    f.undo.undo()
    #expect(f.document.drawing == original)
    #expect(!f.undo.canUndo)
    f.undo.redo()
    #expect(f.document.drawing == copied)
    let repeatCopy = try #require(f.document.transformAgainCommand(for: [id]))
    f.undo.beginUndoGrouping()
    let repeated = try f.document.execute(repeatCopy, undoManager: f.undo)
    f.undo.endUndoGrouping()
    let repeatedID = try #require(repeated.first)
    try expectRect(
      f.document.drawing.node(repeatedID)?.bounds,
      CGRect(x: 133, y: 127, width: 100, height: 80))
    #expect(f.document.drawing.node(f.id) == original.node(f.id))
    #expect(f.document.drawing.node(id) == copied.node(id))
    f.undo.undo()
    #expect(f.document.drawing == copied)
  }

  @Test func releasingOptionCommitsAMoveInsteadOfThePreviewedCopy() throws {
    let f = try Fixture()
    let start = CGPoint(x: 103, y: 107)
    let end = CGPoint(x: 143, y: 137)
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, start, .option))
    f.canvas.mouseDragged(with: try f.event(.leftMouseDragged, end, .option))
    #expect(f.canvas.displayedDrawing.layers.first?.children.count == 2)
    f.canvas.mouseUp(with: try f.event(.leftMouseUp, end))
    #expect(f.document.drawing.layers.first?.children.count == 1)
    #expect(f.state.selection == [f.id])
    try expectRect(
      f.document.drawing.node(f.id)?.bounds, CGRect(x: 93, y: 97, width: 100, height: 80))
  }

  @Test func centerAndSideHandlesResizeWithTheExpectedReferencePoint() throws {
    let f = try Fixture()
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, CGPoint(x: 153, y: 147)))
    f.canvas.mouseUp(
      with: try f.event(.leftMouseUp, CGPoint(x: 173, y: 167), .option))
    try expectRect(
      f.document.drawing.node(f.id)?.bounds, CGRect(x: 33, y: 47, width: 140, height: 120))
    f.undo.undo()
    f.state.selection = [f.id]
    f.refresh()
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, CGPoint(x: 153, y: 107)))
    f.canvas.mouseUp(with: try f.event(.leftMouseUp, CGPoint(x: 173, y: 140)))
    try expectRect(
      f.document.drawing.node(f.id)?.bounds, CGRect(x: 53, y: 67, width: 120, height: 80))
    f.undo.undo()
    f.state.selection = [f.id]
    f.refresh()
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, CGPoint(x: 153, y: 107)))
    f.canvas.mouseUp(with: try f.event(.leftMouseUp, CGPoint(x: 133, y: 107), .shift))
    try expectRect(
      f.document.drawing.node(f.id)?.bounds, CGRect(x: 53, y: 75, width: 80, height: 64))
  }

  @Test(arguments: [
    (CGPoint(x: 123, y: 157), CGRect(x: 63, y: 57, width: 80, height: 100)),
    (
      CGPoint(x: 143, y: 137),
      CGRect(
        x: 39.36038969321072, y: 43.36038969321072,
        width: 127.27922061357856, height: 127.27922061357856)
    ),
  ])
  func shiftOptionRotationMakesAConstrainedCopyAndUsesReleaseModifiers(
    _ sample: (CGPoint, CGRect)
  ) throws {
    let f = try Fixture()
    f.state.tool = .rotate
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, CGPoint(x: 153, y: 107)))
    f.canvas.mouseDragged(with: try f.event(.leftMouseDragged, sample.0))
    f.canvas.mouseUp(
      with: try f.event(.leftMouseUp, sample.0, [.shift, .option]))
    let id = try #require(f.state.selection.first)
    #expect(id != f.id)
    try expectRect(f.document.drawing.node(f.id)?.bounds, f.originalBounds)
    try expectRect(f.document.drawing.node(id)?.bounds, sample.1)
  }

  @Test func centeredProportionalAreaResizeReflowsWithoutScalingFontSize() throws {
    let f = try Fixture()
    let ids = try f.document.drawing.perform(
      .addAreaText(
        "Area text reflows without scaling its font", f.originalBounds, font: "Helvetica", size: 16,
        fill: VectorStyle.solid(0, 0, 0), layer: 1))
    let id = try #require(ids.first)
    f.state.selection = ids
    f.refresh()
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, CGPoint(x: 153, y: 147)))
    f.canvas.mouseUp(
      with: try f.event(.leftMouseUp, CGPoint(x: 173, y: 167), [.option, .shift]))
    try expectRect(
      f.document.drawing.node(id)?.bounds, CGRect(x: 28, y: 47, width: 150, height: 120))
    #expect(
      f.document.drawing.node(id)?.raw["kind"]["runs"].array.first?["style"]["size"].double == 16)
  }

  @Test func escapeCancelsTheCopyPreviewWithoutAllocatingOrRegisteringUndo() throws {
    let f = try Fixture()
    let original = f.document.drawing
    f.canvas.mouseDown(with: try f.event(.leftMouseDown, CGPoint(x: 103, y: 107), .option))
    f.canvas.mouseDragged(with: try f.event(.leftMouseDragged, CGPoint(x: 143, y: 137), .option))
    #expect(f.canvas.displayedDrawing.layers.first?.children.count == 2)
    let escape = try #require(
      NSEvent.keyEvent(
        with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0,
        context: nil, characters: "\u{1b}", charactersIgnoringModifiers: "\u{1b}",
        isARepeat: false, keyCode: 53))
    f.canvas.keyDown(with: escape)
    #expect(f.document.drawing == original)
    #expect(f.canvas.displayedDrawing == original)
    #expect(!f.undo.canUndo)
  }

  private func expectRect(_ actual: CGRect?, _ expected: CGRect) throws {
    let actual = try #require(actual)
    #expect(abs(actual.minX - expected.minX) < 0.000001)
    #expect(abs(actual.minY - expected.minY) < 0.000001)
    #expect(abs(actual.width - expected.width) < 0.000001)
    #expect(abs(actual.height - expected.height) < 0.000001)
  }

  @MainActor private final class Fixture {
    let originalBounds = CGRect(x: 53, y: 67, width: 100, height: 80)
    let document: CanvasDocument
    let state = EditorState()
    let undo = UndoManager()
    let canvas = VectorCanvasView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
    let id: Int64
    init() throws {
      var drawing = Drawing()
      let ids = try drawing.perform(
        .addPath([ShapePaths.rectangle(originalBounds)], VectorStyle(), layer: 1))
      id = try #require(ids.first)
      drawing.updateNode(id) { $0["unknown"]["keep"] = .string("original metadata") }
      document = CanvasDocument(drawing: drawing)
      state.selection = [id]
      state.smartGuides = false
      undo.groupsByEvent = false
      refresh()
      canvas.layout()
    }
    func refresh() {
      canvas.update(drawing: document.drawing, state: state) { [weak self] command in
        guard let self else { return }
        do {
          undo.beginUndoGrouping()
          defer { undo.endUndoGrouping() }
          state.selection = try document.execute(command, undoManager: undo)
        } catch { Issue.record(error) }
      }
    }
    func event(
      _ type: NSEvent.EventType, _ point: CGPoint, _ modifiers: NSEvent.ModifierFlags = []
    ) throws -> NSEvent {
      try #require(
        NSEvent.mouseEvent(
          with: type, location: canvas.convert(canvas.toView(point), to: nil),
          modifierFlags: modifiers, timestamp: 0, windowNumber: 0, context: nil, eventNumber: 0,
          clickCount: 1, pressure: 1))
    }
  }
}
