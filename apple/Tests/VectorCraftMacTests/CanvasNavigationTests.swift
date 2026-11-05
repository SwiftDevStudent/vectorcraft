import AppKit
import Testing
import VectorCraftCore

@testable import VectorCraftMac

@MainActor
struct CanvasNavigationTests {
  @Test func loadedArtboardFitsAfterInitialLayoutAndTracksItsGeometryInFitMode() throws {
    let canvas = VectorCanvasView(frame: CGRect(x: 0, y: 0, width: 1200, height: 900))
    let state = EditorState()
    canvas.layout()
    var loaded = Drawing(width: 612, height: 792)
    canvas.update(drawing: loaded, state: state, command: { _ in })
    #expect(center(of: canvas) == CGPoint(x: 306, y: 396))
    #expect(abs(canvas.viewRect(loaded.artboard).height - 840) < 0.000001)
    try loaded.perform(.resizeArtboard(0, CGSize(width: 400, height: 200)))
    canvas.update(drawing: loaded, state: state, command: { _ in })
    #expect(center(of: canvas) == CGPoint(x: 200, y: 100))
    #expect(abs(canvas.viewRect(loaded.artboard).width - 1140) < 0.000001)
    canvas.setFrameSize(CGSize(width: 600, height: 500))
    canvas.layout()
    #expect(center(of: canvas) == CGPoint(x: 200, y: 100))
    #expect(abs(canvas.viewRect(loaded.artboard).width - 540) < 0.000001)
  }

  @Test func manualNavigationSurvivesGeometryEditsAndBoardSelectionFitsOnlyItsOwnView() throws {
    let canvas = VectorCanvasView(frame: CGRect(x: 0, y: 0, width: 1200, height: 900))
    let other = VectorCanvasView(frame: canvas.frame)
    let state = EditorState()
    let otherState = EditorState()
    var drawing = Drawing()
    canvas.update(drawing: drawing, state: state, command: { _ in })
    other.update(drawing: drawing, state: otherState, command: { _ in })
    canvas.layout()
    other.layout()
    state.canvasAction = .actualSize
    canvas.update(drawing: drawing, state: state, command: { _ in })
    state.canvasAction = nil
    canvas.update(drawing: drawing, state: state, command: { _ in })
    let placement = canvas.toView(CGPoint(x: 20, y: 30))
    let otherPlacement = other.toView(CGPoint(x: 20, y: 30))
    try drawing.perform(.resizeArtboard(0, CGSize(width: 612, height: 792)))
    canvas.update(drawing: drawing, state: state, command: { _ in })
    #expect(canvas.zoom == 1 && canvas.toView(CGPoint(x: 20, y: 30)) == placement)
    drawing.envelope["document"]["artboards"] = .array(
      drawing.envelope["document"]["artboards"].array + [
        .object([
          "id": .integer(2),
          "rect": .object([
            "x0": .number(1000), "y0": .number(200), "x1": .number(1400), "y1": .number(400),
          ]),
        ])
      ])
    state.selectedArtboard = 1
    canvas.update(drawing: drawing, state: state, command: { _ in })
    #expect(center(of: canvas) == CGPoint(x: 1200, y: 300))
    #expect(other.toView(CGPoint(x: 20, y: 30)) == otherPlacement)
    #expect(otherState.selectedArtboard == 0)
  }

  private func center(of canvas: VectorCanvasView) -> CGPoint {
    canvas.toDocument(CGPoint(x: canvas.bounds.midX, y: canvas.bounds.midY))
  }
}
