import AppKit
import Testing
import VectorCraftCore

@testable import VectorCraftMac

@MainActor
struct ScreenshotDropTests {
  private let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=") ?? Data()

  @Test func cardTransferExportsOnlyItsScopedData() async throws {
    let source = ScreenshotBoardDrag(document: UUID(), board: 42)
    let provider = source.itemProvider()
    #expect(provider.registeredTypeIdentifiers == [ScreenshotDropItem.contentType.identifier])
    let imported = try await ScreenshotDropItem.load(provider)
    guard case .board(let value) = imported else {
      Issue.record("A screenshot card must import as a board, not an image file.")
      return
    }
    #expect(value.document == source.document)
    #expect(value.board == source.board)
    let invalid = NSItemProvider()
    invalid.registerDataRepresentation(forTypeIdentifier: ScreenshotDropItem.contentType.identifier, visibility: .all) { completion in
      completion(Data(repeating: 0, count: 4097), nil)
      return nil
    }
    await #expect(throws: (any Error).self) { _ = try await ScreenshotDropItem.load(invalid) }

  }

  @Test func fileProviderLoadsExactImageBytes() async throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("VectorCraft-provider-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
    let file = folder.appendingPathComponent("Screenshot.png")
    try png.write(to: file)
    let provider = try #require(NSItemProvider(contentsOf: file))
    let item = try await ScreenshotDropItem.load(provider)
    guard case .image(let bytes) = item else {
      Issue.record("A PNG file must import as screenshot image bytes.")
      return
    }
    #expect(bytes == png)
  }

  @Test func canvasFileDropAndMoveAreSingleUndoableNativeEdits() throws {
    let document = CanvasDocument(), undo = UndoManager()
    undo.groupsByEvent = false
    try document.execute(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")), undoManager: nil)
    let initial = document.drawing
    let view = VectorCanvasView(frame: CGRect(x: 0, y: 0, width: 1200, height: 900))
    let state = EditorState()
    view.update(drawing: document.drawing, state: state) { command in
      do { try document.execute(command, undoManager: undo) } catch { Issue.record(error) }
    }
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("VectorCraft-drop-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
    let file = folder.appendingPathComponent("Screenshot.png"); try png.write(to: file)
    let target = try #require(document.drawing.screenshotSlots.first { $0.index == 5 })
    undo.beginUndoGrouping()
    #expect(view.acceptScreenshotFiles([file, file], at: CGPoint(x: target.rect.midX, y: target.rect.midY)))
    undo.endUndoGrouping()
    let imported = document.drawing
    #expect(imported.includedScreenshotBoards.count == 2)
    #expect(imported.screenshotSlots.filter { [5,6].contains($0.index) }.allSatisfy { $0.boardID != nil })
    undo.undo(); #expect(document.drawing == initial)
    undo.redo(); #expect(document.drawing == imported)
    let board = try #require(imported.includedScreenshotBoards.first)
    let destination = try #require(imported.screenshotSlots.first { $0.index == 9 })
    let drag = ScreenshotDropItem.board(ScreenshotBoardDrag(document: document.screenshotDragID, board: board.id))
    undo.beginUndoGrouping()
    try document.execute(ScreenshotDropItem.command([drag], document: document.screenshotDragID, target: destination), undoManager: undo)
    undo.endUndoGrouping()
    #expect(document.drawing.screenshotSlots.first { $0.index == 9 }?.boardID == board.id)
    undo.undo(); #expect(document.drawing == imported)
  }

  @Test func crossDocumentDragCannotMoveAnUnrelatedBoardWithTheSameID() throws {
    let document = CanvasDocument()
    try document.execute(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")), undoManager: nil)
    let target = try #require(document.drawing.screenshotSlots.last)
    let foreign = ScreenshotDropItem.board(ScreenshotBoardDrag(document: UUID(), board: 1))
    #expect(throws: DrawingError.self) { try ScreenshotDropItem.command([foreign], document: document.screenshotDragID, target: target) }
    #expect(document.drawing.artboards.count == 1)
  }
}
