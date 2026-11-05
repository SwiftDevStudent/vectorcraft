import AppKit
import Testing
import VectorCraftCore

@testable import VectorCraftMac

@MainActor
struct CanvasSnappingTests {
  @Test func artworkGridMovesPreviewAndCommitTogetherAndKeepsUndoAndSave() throws {
    let fixture = try Fixture()
    fixture.state.snapToGrid = true
    fixture.state.smartGuides = false
    let start = CGPoint(x: 103, y: 107)
    let end = CGPoint(x: 117, y: 126)
    fixture.canvas.mouseDown(with: try fixture.event(.leftMouseDown, start))
    fixture.canvas.mouseDragged(with: try fixture.event(.leftMouseDragged, end))
    let expected = CGRect(x: 70, y: 90, width: 100, height: 80)
    #expect(fixture.document.drawing.node(fixture.id)?.bounds.minX == 53)
    #expect(fixture.canvas.displayedDrawing.node(fixture.id)?.bounds == expected)
    fixture.canvas.mouseUp(with: try fixture.event(.leftMouseUp, end))
    #expect(fixture.document.drawing.node(fixture.id)?.bounds == expected)
    let reopened = try NativeFormat.decode(NativeFormat.encode(fixture.document.drawing))
    #expect(reopened.node(fixture.id)?.bounds == expected)
    fixture.undo.undo()
    #expect(
      fixture.document.drawing.node(fixture.id)?.bounds
        == CGRect(x: 53, y: 67, width: 100, height: 80))
    fixture.undo.redo()
    #expect(fixture.document.drawing.node(fixture.id)?.bounds == expected)
  }

  @Test func controlOnReleaseBypassesBothGridAndGuides() throws {
    let fixture = try Fixture()
    fixture.state.snapToGrid = true
    fixture.canvas.mouseDown(with: try fixture.event(.leftMouseDown, CGPoint(x: 103, y: 107)))
    fixture.canvas.mouseDragged(with: try fixture.event(.leftMouseDragged, CGPoint(x: 117, y: 126)))
    fixture.canvas.mouseUp(
      with: try fixture.event(.leftMouseUp, CGPoint(x: 117, y: 126), modifiers: .control))
    try expectRect(
      fixture.document.drawing.node(fixture.id)?.bounds,
      CGRect(x: 67, y: 86, width: 100, height: 80))
    #expect(fixture.canvas.snapGuides.isEmpty)
  }

  @Test func smartGuidesAlignToAnotherObjectAndClearAfterRelease() throws {
    let fixture = try Fixture()
    try fixture.document.drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 300, y: 200, width: 80, height: 70))], VectorStyle(),
        layer: 1))
    fixture.refresh()
    fixture.canvas.mouseDown(with: try fixture.event(.leftMouseDown, CGPoint(x: 103, y: 107)))
    let end = CGPoint(x: 248, y: 239)
    fixture.canvas.mouseDragged(with: try fixture.event(.leftMouseDragged, end))
    #expect(fixture.canvas.snapGuides.count == 2)
    #expect(
      fixture.canvas.displayedDrawing.node(fixture.id)?.bounds
        == CGRect(x: 200, y: 200, width: 100, height: 80))
    fixture.canvas.mouseUp(with: try fixture.event(.leftMouseUp, end))
    #expect(
      fixture.document.drawing.node(fixture.id)?.bounds
        == CGRect(x: 200, y: 200, width: 100, height: 80))
    #expect(fixture.canvas.snapGuides.isEmpty)
  }

  @Test func shapeAndNodeAndResizeUseGridCoordinates() throws {
    let fixture = try Fixture()
    fixture.state.snapToGrid = true
    fixture.state.smartGuides = false
    fixture.state.tool = .rectangle
    fixture.canvas.mouseDown(with: try fixture.event(.leftMouseDown, CGPoint(x: 216, y: 224)))
    fixture.canvas.mouseUp(with: try fixture.event(.leftMouseUp, CGPoint(x: 332, y: 348)))
    let id = try #require(fixture.state.selection.first)
    #expect(
      fixture.document.drawing.node(id)?.bounds == CGRect(x: 220, y: 220, width: 110, height: 130))
    fixture.state.tool = .nodes
    fixture.refresh()
    fixture.canvas.mouseDown(with: try fixture.event(.leftMouseDown, CGPoint(x: 222, y: 222)))
    fixture.canvas.mouseUp(with: try fixture.event(.leftMouseUp, CGPoint(x: 236, y: 239)))
    let anchor = try #require(fixture.document.drawing.node(id)?.subpaths.first?.anchors.first)
    #expect(anchor.point.distance(to: CGPoint(x: 230, y: 240)) < 0.000001)
    fixture.state.tool = .select
    fixture.refresh()
    fixture.canvas.mouseDown(with: try fixture.event(.leftMouseDown, CGPoint(x: 330, y: 350)))
    fixture.canvas.mouseUp(with: try fixture.event(.leftMouseUp, CGPoint(x: 368, y: 383)))
    try expectRect(
      fixture.document.drawing.node(id)?.bounds, CGRect(x: 220, y: 220, width: 150, height: 160))
  }

  @Test func floatingPaletteGridCanBeBypassedDisabledAndDocked() {
    let state = EditorState()
    state.movePanel(.tools, to: CGPoint(x: 103, y: 117))
    #expect(state.toolsPosition == CGPoint(x: 104, y: 120))
    #expect(state.toolsFloating)
    state.movePanel(.tools, to: CGPoint(x: 103, y: 117), bypassSnapping: true)
    #expect(state.toolsPosition == CGPoint(x: 103, y: 117))
    state.snapPalettes = false
    state.movePanel(.properties, to: CGPoint(x: 501, y: 137))
    #expect(state.propertiesPosition == CGPoint(x: 501, y: 137))
    state.dockPanel(.tools)
    #expect(!state.toolsFloating)
    state.resetWorkspace()
    #expect(!state.propertiesFloating)
  }

  @Test func snappingMultipleObjectsPreservesTheirRelativePositions() throws {
    let fixture = try Fixture()
    let second = try fixture.document.drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 200, y: 200, width: 40, height: 40))],
        VectorStyle(), layer: 1))
    let secondID = try #require(second.first)
    fixture.state.selection.formUnion(second)
    fixture.state.snapToGrid = true
    fixture.state.smartGuides = false
    fixture.refresh()
    fixture.canvas.mouseDown(with: try fixture.event(.leftMouseDown, CGPoint(x: 103, y: 107)))
    fixture.canvas.mouseUp(with: try fixture.event(.leftMouseUp, CGPoint(x: 117, y: 126)))
    try expectRect(
      fixture.document.drawing.node(fixture.id)?.bounds,
      CGRect(x: 70, y: 90, width: 100, height: 80))
    try expectRect(
      fixture.document.drawing.node(secondID)?.bounds,
      CGRect(x: 217, y: 223, width: 40, height: 40))
  }

  private func expectRect(_ actual: CGRect?, _ expected: CGRect) throws {
    let actual = try #require(actual)
    #expect(abs(actual.minX - expected.minX) < 0.000001)
    #expect(abs(actual.minY - expected.minY) < 0.000001)
    #expect(abs(actual.width - expected.width) < 0.000001)
    #expect(abs(actual.height - expected.height) < 0.000001)
  }

  @MainActor private final class Fixture {
    let document: CanvasDocument
    let state = EditorState()
    let undo = UndoManager()
    let canvas = VectorCanvasView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
    let id: Int64
    init() throws {
      var drawing = Drawing()
      id = try #require(
        try drawing.perform(
          .addPath(
            [ShapePaths.rectangle(CGRect(x: 53, y: 67, width: 100, height: 80))], VectorStyle(),
            layer: 1)
        ).first)
      document = CanvasDocument(drawing: drawing)
      state.selection = [id]
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
    func event(_ type: NSEvent.EventType, _ point: CGPoint, modifiers: NSEvent.ModifierFlags = [])
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
