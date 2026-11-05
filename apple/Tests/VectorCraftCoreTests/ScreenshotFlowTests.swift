import CoreGraphics
import Foundation
import ImageIO
import Testing

@testable import VectorCraftCore

struct ScreenshotFlowTests {
  @Test func canceledThumbnailWorkStopsBeforeResolvingItsBoard() async {
    let renderer = ScreenshotPreview(), drawing = Drawing()
    let work = Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return try await renderer.png(drawing, board: -1)
    }
    await #expect(throws: CancellationError.self) { _ = try await work.value }
  }

  @Test func thumbnailInvalidationTracksItsOwnArtworkBoundsAndSharedResources() throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let row = try #require(drawing.screenshotRows.first), first = try #require(row.boards.first)
    try drawing.perform(.screenshot(ScreenshotCommand(.addBoard, row: row.id, slot: 1)))
    let second = try #require(drawing.screenshotRows.first?.boards.last), before = drawing
    try drawing.perform(.addText("Changed", CGPoint(x: 20, y: 30), font: "Helvetica", size: 40,
      fill: VectorStyle.solid(0, 0, 0), layer: second.content))
    #expect(!ScreenshotPreview.isAffected(board: first.id, previous: before, current: drawing))
    #expect(ScreenshotPreview.isAffected(board: second.id, previous: before, current: drawing))
    let edited = drawing
    try drawing.perform(.screenshot(ScreenshotCommand(.rotateBoard, board: first.id)))
    #expect(ScreenshotPreview.isAffected(board: first.id, previous: edited, current: drawing))
    let rotated = drawing
    drawing.envelope["images"]["new"] = .object(["mime": .string("image/png")])
    #expect(ScreenshotPreview.isAffected(board: first.id, previous: rotated, current: drawing))
  }

  @Test func thumbnailShowsOnlyItsOwnClippedCompositionEvenWhenExcludedFromExport() async throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let row = try #require(drawing.screenshotRows.first), first = try #require(row.boards.first)
    try drawing.perform(.screenshot(ScreenshotCommand(.addBoard, row: row.id, slot: 1)))
    let neighbor = try #require(drawing.screenshotRows.first?.boards.last)
    try drawing.perform(.addPath([ShapePaths.rectangle(drawing.artboard)],
      VectorStyle(fill: VectorStyle.solid(1,0,0), stroke: VectorStyle.none, width: 0), layer: neighbor.content))
    #expect(!drawing.screenshotIsIncluded(first))
    let bytes = try await ScreenshotPreview().png(drawing, board: first.id)
    let source = try #require(CGImageSourceCreateWithData(bytes as CFData, nil))
    let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
    #expect(image.width <= 128 && image.height == 128)
    let pixel = try #require(image.cropping(to: CGRect(x: 0, y: 0, width: 1, height: 1)))
    let context = try #require(CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.draw(pixel, in: CGRect(x:0,y:0,width:1,height:1))
    let rgba = try #require(context.data?.assumingMemoryBound(to: UInt8.self))
    #expect(rgba[0] < 50 && rgba[1] > 40 && rgba[2] > 80)
  }
  private let png =
    Data(
      base64Encoded:
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII="
    ) ?? Data()
  private func command(_ value: [String: JSONValue]) throws -> DrawingCommand {
    .screenshot(
      try JSONDecoder().decode(
        ScreenshotCommand.self, from: JSONEncoder().encode(JSONValue.object(value))))
  }
  @Test func movingAndSwappingSlotsPreservesArtworkAndNativeIDs() throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let row = try #require(drawing.screenshotRows.first)
    let first = try #require(row.boards.first)
    try drawing.perform(.screenshot(ScreenshotCommand(.addBoard, row: row.id, slot: 7)))
    let other = try #require(drawing.screenshotRows.first?.boards.last)
    try drawing.perform(
      .screenshot(ScreenshotCommand(.replaceScreenshot, board: first.id, data: png)))
    let IDs = Set(drawing.layers.flatMap { [$0.id] + $0.children.map(\.id) })
    let resources = drawing.envelope["images"]
    try drawing.perform(
      command([
        "action": .string("moveBoard"), "board": .integer(first.id), "row": .string(row.id),
        "slot": .integer(7),
      ]))
    #expect(drawing.screenshotSlots.first { $0.index == 7 }?.boardID == first.id)
    #expect(drawing.screenshotSlots.first { $0.index == 0 }?.boardID == other.id)
    try drawing.perform(
      command([
        "action": .string("moveBoard"), "board": .integer(first.id), "row": .string(row.id),
        "slot": .integer(4),
      ]))
    #expect(drawing.screenshotSlots.first { $0.index == 7 }?.boardID == nil)
    #expect(drawing.screenshotSlots.first { $0.index == 4 }?.boardID == first.id)
    #expect(Set(drawing.layers.flatMap { [$0.id] + $0.children.map(\.id) }) == IDs)
    #expect(drawing.envelope["images"] == resources)
    #expect(drawing.includedScreenshotBoards.map(\.id) == [first.id])
    let reopened = try NativeFormat.decode(NativeFormat.encode(drawing))
    #expect(reopened.screenshotSlots.map(\.boardID) == drawing.screenshotSlots.map(\.boardID))
  }
  @Test func multiImagePlacementSkipsFollowingOccupiedSlotsAndRollsBackErrors() throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let row = try #require(drawing.screenshotRows.first)
    try drawing.perform(.screenshot(ScreenshotCommand(.addBoard, row: row.id, slot: 3)))
    let occupied = try #require(drawing.screenshotRows.first?.boards.last)
    let occupiedLayer = drawing.node(occupied.layer)
    try drawing.perform(
      command([
        "action": .string("placeScreenshots"), "row": .string(row.id), "slot": .integer(2),
        "images": .array([.string(png.base64EncodedString()), .string(png.base64EncodedString())]),
      ]))
    #expect(
      drawing.screenshotSlots.filter { [2, 4].contains($0.index) }.allSatisfy { $0.boardID != nil })
    #expect(drawing.node(occupied.layer) == occupiedLayer)
    #expect(drawing.includedScreenshotBoards.count == 2)
    let before = drawing
    #expect(throws: DrawingError.self) {
      try drawing.perform(
        command([
          "action": .string("placeScreenshots"), "row": .string(row.id), "slot": .integer(8),
          "images": .array([
            .string(png.base64EncodedString()), .string(Data("invalid".utf8).base64EncodedString()),
          ]),
        ]))
    }
    #expect(drawing == before)
    #expect(throws: DrawingError.self) {
      try drawing.perform(
        command([
          "action": .string("placeScreenshots"), "row": .string(row.id), "slot": .integer(9),
          "images": .array([.string(png.base64EncodedString()), .string(png.base64EncodedString())]
          ),
        ]))
    }
    #expect(drawing == before)
  }
}
