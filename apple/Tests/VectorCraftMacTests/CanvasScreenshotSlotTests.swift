import AppKit
import Testing
import VectorCraftCore

@testable import VectorCraftMac

@MainActor
struct CanvasScreenshotSlotTests {
  @Test func selectionOpensEmptySlotButZoomDoesNotCreateArtwork() throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let view = VectorCanvasView(frame: CGRect(x: 0, y: 0, width: 1200, height: 900))
    let state = EditorState()
    var edits: [DrawingCommand] = []
    state.canvasAction = .fitWorkspace
    view.update(drawing: drawing, state: state, command: { edits.append($0) })
    view.layout()
    let slot = try #require(drawing.screenshotSlots.first { $0.index == 7 })
    let event = try #require(NSEvent.mouseEvent(with: .leftMouseDown,
      location: view.convert(view.toView(CGPoint(x: slot.rect.midX, y: slot.rect.midY)), to: nil),
      modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, eventNumber: 0,
      clickCount: 1, pressure: 1))
    state.tool = .zoom
    view.mouseDown(with: event)
    #expect(edits.isEmpty)
    state.tool = .select
    view.mouseDown(with: event)
    #expect(edits.count == 1)
    try drawing.perform(try #require(edits.first))
    #expect(drawing.screenshotSlots.first { $0.index == 7 }?.boardID != nil)
  }
}
