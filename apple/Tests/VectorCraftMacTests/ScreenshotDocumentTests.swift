import Foundation
import Testing
import CoreGraphics
@testable import VectorCraftCore
@testable import VectorCraftMac

struct ScreenshotDocumentTests {
  @Test @MainActor func undoingTheSelectedLastSlotRestoresAUsableBoardAndInsertionTarget() throws {
    let document = CanvasDocument(), state = EditorState(), manager = UndoManager()
    manager.groupsByEvent = false
    try document.execute(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")), undoManager: nil)
    let row = try #require(document.drawing.screenshotRows.first), first = try #require(row.boards.first)
    let original = document.drawing
    manager.beginUndoGrouping()
    try document.execute(.screenshot(ScreenshotCommand(.addBoard, row: row.id, slot: 1)), undoManager: manager)
    manager.endUndoGrouping()
    let added = try #require(document.drawing.screenshotRows.first?.boards.last)
    state.selectedArtboard = try #require(document.drawing.artboardIndex(id: added.id))
    state.activeLayer = added.content
    manager.undo()
    #expect(document.drawing.screenshotBoard(at: state.selectedArtboard) == nil)
    state.reconcileArtboard(in: document.drawing)
    #expect(document.drawing.screenshotBoard(at: state.selectedArtboard)?.id == first.id)
    #expect(state.insertionContainer(in: document.drawing) == first.content)
    #expect(state.canvasAction == .fit && document.drawing == original)
    state.canvasAction = nil
    state.activeLayer = first.layer
    state.reconcileArtboard(in: document.drawing)
    #expect(state.activeLayer == first.layer && state.canvasAction == nil)
  }
  @Test @MainActor func visualLayoutCommandsRetainArtworkAndHaveOneNativeUndoStep() throws {
    let document = CanvasDocument(), manager = UndoManager()
    manager.groupsByEvent = false
    try document.execute(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")), undoManager: nil)
    let board = try #require(document.drawing.screenshotRows.first?.boards.first)
    let bytes = try #require(Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII="))
    try document.execute(.screenshot(ScreenshotCommand(.replaceScreenshot, board: board.id, data: bytes)), undoManager: nil)
    document.drawing.envelope["workflowForeign"] = .object(["retained": .bool(true)])
    let original = document.drawing
    for layout in ScreenshotTemplate.all where layout.id != "headline" {
      manager.beginUndoGrouping()
      try document.execute(.screenshot(ScreenshotCommand(.setTemplate, board: board.id, template: layout.id)), undoManager: manager)
      manager.endUndoGrouping()
      let edited = document.drawing
      #expect(edited.screenshotBoard(board.id)?.raw["template"].string == layout.id)
      #expect(edited.envelope["images"] == original.envelope["images"])
      #expect(edited.nativeBlobData == original.nativeBlobData)
      let reopened = try NativeFormat.decode(NativeFormat.encode(edited))
      #expect(reopened.envelope["workflowForeign"] == original.envelope["workflowForeign"])
      let image = try #require(reopened.node(board.screen)?.children.first { $0.type == "image" })
      #expect(VectorImage.data(image, images: reopened.envelope["images"], blobs: reopened.nativeBlobData) == bytes)
      manager.undo(); #expect(document.drawing == original)
      manager.redo(); #expect(document.drawing == edited)
      manager.undo(); #expect(document.drawing == original)
    }
  }
  @Test @MainActor func slotLayoutDisplayAndExportStateUndoTogether() throws {
    let document = CanvasDocument(), manager = UndoManager()
    manager.groupsByEvent = false
    try document.execute(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-duo")), undoManager: nil)
    let row = try #require(document.drawing.screenshotRows.first)
    let original = document.drawing
    manager.beginUndoGrouping()
    try document.execute(.screenshot(ScreenshotCommand(.addBoard, row: row.id, slot: 8)), undoManager: manager)
    let board = try #require(document.drawing.screenshotRows.first?.boards.last)
    try document.execute(.screenshot(ScreenshotCommand(.setDisplay, preset: "duo-outer", board: board.id)), undoManager: manager)
    try document.execute(.screenshot(ScreenshotCommand(.setTemplate, board: board.id, template: "top-crop")), undoManager: manager)
    try document.execute(.screenshot(ScreenshotCommand(.setExport, board: board.id, included: true)), undoManager: manager)
    manager.endUndoGrouping()
    let final = document.drawing
    #expect(final.includedScreenshotBoards.map(\.id) == [board.id])
    manager.undo(); #expect(document.drawing == original)
    manager.redo(); #expect(document.drawing == final)
  }
  @Test @MainActor func screenshotInsertionKeepsIsolationAndOrdinaryLayerOwnership() throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let board = try #require(drawing.screenshotRows.first?.boards.first)
    let state = EditorState()
    state.activeLayer = board.layer
    #expect(state.insertionContainer(in: drawing) == board.content)
    #expect(state.enterIsolation(board.screen, in: drawing))
    #expect(state.insertionContainer(in: drawing) == board.screen)
    state.exitIsolation(in: drawing)
    state.activeLayer = 1
    #expect(state.insertionContainer(in: drawing) == 1)
  }

  @Test @MainActor func nativeUndoRedoRestoresEntireScreenshotRow() throws {
    let document = CanvasDocument(), manager = UndoManager()
    manager.groupsByEvent = false
    let original = document.drawing
    manager.beginUndoGrouping()
    try document.execute(.screenshot(ScreenshotCommand(.addRow, preset: "duo-inner")), undoManager: manager)
    manager.endUndoGrouping()
    let edited = document.drawing
    #expect(edited.screenshotRows.count == 1)
    manager.undo(); #expect(document.drawing == original)
    manager.redo(); #expect(document.drawing == edited)
  }
  @Test @MainActor func ordinaryTextCommandRemainsBoardOwnedThroughRotationAndUndo() throws {
    let document = CanvasDocument(), manager = UndoManager()
    manager.groupsByEvent = false
    try document.execute(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")), undoManager: nil)
    let board = try #require(document.drawing.screenshotRows.first?.boards.first)
    let state = EditorState()
    // Match the existing Layers action: the outer layer becomes active, not the content group.
    state.activeLayer = board.layer
    #expect(state.insertionContainer(in: document.drawing) == board.content)
    manager.beginUndoGrouping()
    let selected = try document.execute(.addText("Native Type Tool", CGPoint(x: 200, y: 700),
      font: "Helvetica", size: 48, fill: VectorStyle.solid(1, 1, 1),
      layer: state.insertionContainer(in: document.drawing)), undoManager: manager)
    manager.endUndoGrouping()
    let textID = try #require(selected.first), oldBounds = try #require(document.drawing.node(textID)?.bounds)
    manager.beginUndoGrouping()
    try document.execute(.screenshot(ScreenshotCommand(.rotateBoard, board: board.id)), undoManager: manager)
    manager.endUndoGrouping()
    #expect(document.drawing.node(textID)?.bounds != oldBounds)
    #expect(document.drawing.artboards[0].contains(try #require(document.drawing.node(textID)?.bounds)))
    manager.undo(); #expect(document.drawing.node(textID)?.bounds == oldBounds)
    manager.undo(); #expect(document.drawing.node(textID) == nil)
  }
}
