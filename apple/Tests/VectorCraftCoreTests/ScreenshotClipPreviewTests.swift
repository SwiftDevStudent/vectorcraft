import CoreGraphics
import Testing
@testable import VectorCraftCore

struct ScreenshotClipPreviewTests {
  @Test func clippedPreviewHidesOutsideDeviceArtworkWithoutChangingTheDocument() throws {
    var drawing = Drawing(width: 100, height: 100)
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let board = try #require(drawing.screenshotRows.first?.boards.first)
    try drawing.perform(.addPath([ShapePaths.rectangle(CGRect(x: -100, y: 40, width: 200, height: 80))],
      VectorStyle(fill: VectorStyle.solid(1,0,0), stroke: VectorStyle.none, width: 0), layer: board.content))
    let before = drawing
    func pixel(clipped: Bool) throws -> [UInt8] {
      let context = try #require(CGContext(data: nil, width: 220, height: 160, bitsPerComponent: 8, bytesPerRow: 880,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
      context.setFillColor(CGColor(gray: 0.5, alpha: 1)); context.fill(CGRect(x:0,y:0,width:220,height:160))
      context.translateBy(x: 110, y: 0)
      VectorRenderer.render(drawing, in: context, clippingScreenshotBoards: clipped)
      let data = try #require(context.data?.assumingMemoryBound(to: UInt8.self))
      let offset = 60 * 880 + 50 * 4
      return Array(UnsafeBufferPointer(start: data.advanced(by: offset), count: 4))
    }
    let unclipped = try pixel(clipped: false), clipped = try pixel(clipped: true)
    #expect(unclipped[0] > 240 && unclipped[1] < 10)
    #expect(clipped[0] > 100 && clipped[1] == clipped[0] && clipped[2] == clipped[0])
    #expect(drawing == before)
    #expect(try #require(drawing.node(board.content)).bounds.minX == -100)
  }
}
