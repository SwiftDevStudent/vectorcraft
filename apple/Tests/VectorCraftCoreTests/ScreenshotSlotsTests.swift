import Foundation
import CoreGraphics
import Testing

@testable import VectorCraftCore

struct ScreenshotSlotsTests {
  @Test func duoIsOneDeviceFamily() throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-duo")))
    #expect(drawing.screenshotRows.count == 1)
    #expect(drawing.screenshotRows.first?.name == "iPhone Duo")
    let row = try #require(drawing.screenshotRows.first)
    let board = try #require(row.boards.first)
    try drawing.perform(.screenshot(ScreenshotCommand(.setDisplay, preset: "duo-outer", board: board.id)))
    #expect(drawing.artboards[0].size == CGSize(width: 1398, height: 2034))
    try drawing.perform(.screenshot(ScreenshotCommand(.rotateBoard, board: board.id)))
    try drawing.perform(.screenshot(ScreenshotCommand(.setDisplay, preset: "duo-inner", board: board.id)))
    #expect(drawing.artboards[0].size == CGSize(width: 2853, height: 2007))
    #expect(drawing.screenshotRows.count == 1)
    #expect(drawing.screenshotSlots.count == 10)
    #expect(ScreenshotPreset.all.filter { $0.id.contains("duo") }.count == 1)
  }

  @Test func tenSlotsSupportHolesAndRemainEmptyUntilArtworkIsAdded() throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let row = try #require(drawing.screenshotRows.first)
    #expect(drawing.screenshotSlots.count == 10)
    #expect(drawing.artboards.count == 1)
    #expect(drawing.includedScreenshotBoards.isEmpty)
    try drawing.perform(.screenshot(ScreenshotCommand(.addBoard, row: row.id, slot: 7)))
    let slot = try #require(drawing.screenshotSlots.first { $0.index == 7 })
    #expect(slot.boardID != nil)
    #expect(drawing.artboards.count == 2)
    #expect(abs(drawing.artboards[1].minX - 9562) < 0.000001)
    let before = drawing
    #expect(throws: DrawingError.self) { try drawing.perform(.screenshot(ScreenshotCommand(.addBoard, row: row.id, slot: 7))) }
    #expect(drawing == before)
    let board = try #require(slot.boardID.flatMap(drawing.screenshotBoard))
    try drawing.perform(.addPath([ShapePaths.rectangle(CGRect(x: slot.rect.midX, y: slot.rect.midY, width: 80, height: 80))], VectorStyle(), layer: board.content))
    #expect(drawing.includedScreenshotBoards.map(\.id) == [board.id])
    try drawing.perform(.screenshot(ScreenshotCommand(.setExport, board: board.id, included: false)))
    #expect(drawing.includedScreenshotBoards.isEmpty)
    let reopened = try NativeFormat.decode(NativeFormat.encode(drawing))
    #expect(reopened.screenshotSlots.map(\.boardID) == drawing.screenshotSlots.map(\.boardID))
    #expect(reopened.includedScreenshotBoards.isEmpty)
  }

  @Test func croppedLayoutsPreserveSourcePixelsAndDeviceAspect() throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let board = try #require(drawing.screenshotRows.first?.boards.first)
    let bytes = try #require(Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII="))
    try drawing.perform(.screenshot(ScreenshotCommand(.replaceScreenshot, board: board.id, data: bytes)))
    let frame = try RoundedFrameFixture.frame()
    try drawing.perform(.screenshot(ScreenshotCommand(.setFrame, board: board.id, frame: frame.reference)))
    let before = try #require(drawing.node(board.device)).bounds
    let image = try #require(drawing.node(board.screen)?.children.first { $0.type == "image" })
    for template in ["top-crop", "bottom-crop"] {
      try drawing.perform(.screenshot(ScreenshotCommand(.setTemplate, board: board.id, template: template)))
      let after = try #require(drawing.node(board.device)).bounds
      #expect(abs(after.width / after.height - before.width / before.height) < 0.00001)
      #expect(template == "top-crop" ? after.minY < drawing.artboard.minY : after.maxY > drawing.artboard.maxY)
      let updated = try #require(drawing.node(image.id))
      #expect(VectorImage.data(updated, images: drawing.envelope["images"], blobs: drawing.nativeBlobData) == bytes)
    }
  }

  @Test func batchExportOmitsUnusedSlotsAndIsolatesArtwork() async throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let row = try #require(drawing.screenshotRows.first), first = try #require(row.boards.first)
    try drawing.perform(.screenshot(ScreenshotCommand(.addBoard, row: row.id, slot: 9)))
    let used = try #require(drawing.screenshotRows.first?.boards.last)
    try drawing.perform(.screenshot(ScreenshotCommand(.setExport, board: used.id, included: true)))
    #expect(throws: DrawingError.self) { try drawing.screenshotExportDrawing(first) }
    let isolated = try drawing.screenshotExportDrawing(used)
    #expect(isolated.layers.map(\.id) == [used.layer])
    #expect(isolated.artboards.count == 1)
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("VectorCraft-slot-test-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
    let output = try await ScreenshotExport.write(drawing, format: .svg, to: folder)
    let files = try FileManager.default.contentsOfDirectory(at: output, includingPropertiesForKeys: nil)
    #expect(files.map(\.lastPathComponent) == ["Row-01-Screenshot-10.svg"])
    #expect(try String(contentsOf: files[0], encoding: .utf8).contains("<svg"))
  }
}
