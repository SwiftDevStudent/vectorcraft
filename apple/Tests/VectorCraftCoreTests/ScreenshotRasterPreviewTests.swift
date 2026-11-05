import CoreGraphics
import Foundation
import Testing
@testable import VectorCraftCore

struct ScreenshotRasterPreviewTests {
  private func screenshot(red: CGFloat, blue: CGFloat) throws -> Data {
    let context = try #require(CGContext(data: nil, width: 1024, height: 1024,
      bitsPerComponent: 8, bytesPerRow: 4096, space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.setFillColor(CGColor(red: red, green: 0, blue: blue, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    return try RoundedFrameFixture.png(#require(context.makeImage()))
  }

  @Test func cardPixelsFollowRasterReplacementAndUndoWithoutChangingOriginalExport() async throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let board = try #require(drawing.screenshotRows.first?.boards.first)
    let red = try screenshot(red: 1, blue: 0), blue = try screenshot(red: 0, blue: 1)
    try drawing.perform(.screenshot(ScreenshotCommand(.replaceScreenshot, board: board.id, data: red)))
    let original = drawing, originalBytes = try NativeFormat.encode(drawing)
    let originalExport = try VectorRenderer.png(drawing.screenshotExportDrawing(board))
    try drawing.perform(.screenshot(ScreenshotCommand(.replaceScreenshot, board: board.id, data: blue)))
    let renderer = ScreenshotPreview()
    for (snapshot, expectsRed) in [(original, true), (drawing, false), (original, true)] {
      let imageNode = try #require(snapshot.node(board.screen)?.children.first { $0.type == "image" })
      let center = VectorImage.bounds(imageNode).intersection(snapshot.artboard)
      let bytes = try await renderer.png(snapshot, board: board.id)
      let card = try RoundedFrameFixture.image(bytes)
      #expect(card.width <= 128 && card.height == 128)
      let scale = 128 / snapshot.artboard.height
      let color = try RoundedFrameFixture.pixel(card, at: CGPoint(
        x: (center.midX - snapshot.artboard.minX) * scale,
        y: (center.midY - snapshot.artboard.minY) * scale))
      #expect(expectsRed ? color[0] > 240 && color[2] < 10 : color[2] > 240 && color[0] < 10)
      #expect(VectorImage.data(imageNode, images: snapshot.envelope["images"], blobs: snapshot.nativeBlobData)
        == (expectsRed ? red : blue))
      #expect(VectorImage.resolve(imageNode, images: snapshot.envelope["images"], blobs: snapshot.nativeBlobData)?.width == 1024)
    }
    #expect(try NativeFormat.encode(original) == originalBytes)
    #expect(try VectorRenderer.png(original.screenshotExportDrawing(board)) == originalExport)
  }

  @Test func previewPNGRequestsDisplaySizedPixelsWhileDefaultPNGKeepsItsImages() throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let board = try #require(drawing.screenshotRows.first?.boards.first)
    try drawing.perform(.screenshot(ScreenshotCommand(.replaceScreenshot, board: board.id,
      data: try screenshot(red: 1, blue: 0))))
    let artwork = try drawing.screenshotExportDrawing(board), cache = VectorImagePreviewCache(deferred: true)
    let scale = 128 / artwork.artboard.height
    let pending = try VectorRenderer.png(artwork, scale: scale, previewImages: cache)
    #expect(cache.requests.count == 1)
    let request = try #require(cache.requests.first), image = try #require(try request.decode())
    #expect(image.width <= 256 && image.height <= 256)
    #expect(cache.store(image, for: request))
    let complete = try VectorRenderer.png(artwork, scale: scale, previewImages: cache)
    #expect(pending != complete && cache.requests.isEmpty)
    #expect(try VectorRenderer.png(artwork, scale: scale) != pending)
  }
}
