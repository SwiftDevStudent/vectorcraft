import AppKit
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import VectorCraftCore
@testable import VectorCraftMac

@MainActor
struct CanvasImagePreviewTests {
  private func resources(red: CGFloat, blue: CGFloat) throws -> JSONValue {
    let context = try bitmap()
    context.setFillColor(CGColor(red: red, green: 0, blue: blue, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
    let bytes = NSMutableData()
    let output = try #require(CGImageDestinationCreateWithData(bytes, UTType.png.identifier as CFString, 1, nil))
    CGImageDestinationAddImage(output, try #require(context.makeImage()), nil)
    #expect(CGImageDestinationFinalize(output))
    return .object(["picture": .object(["mime": .string("image/png"), "data": .string((bytes as Data).base64EncodedString())])])
  }
  private func bitmap() throws -> CGContext {
    try #require(CGContext(data: nil, width: 64, height: 64, bitsPerComponent: 8,
      bytesPerRow: 256, space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
  }
  private var node: VectorNode {
    VectorNode(raw: .object(["id": .integer(2), "kind": .object([
      "type": .string("image"), "key": .string("picture"), "width": .number(64),
      "height": .number(64), "xf": CGAffineTransform.identity.json])]))
  }
  @Test func pendingViewportWorkCoalescesToTheLatestResourceSnapshot() async throws {
    let view = VectorCanvasView(), loader = view.imagePreviews, context = try bitmap()
    loader.cache.prepare(images: try resources(red: 1, blue: 0), blobs: Data())
    #expect(loader.cache.resolve(node, context: context) == nil)
    loader.update(loader.cache.requests)
    loader.cache.prepare(images: try resources(red: 0, blue: 1), blobs: Data())
    #expect(loader.cache.resolve(node, context: context) == nil)
    loader.update(loader.cache.requests)
    await loader.task?.value
    let image = try #require(loader.cache.resolve(node, context: context))
    let output = try bitmap()
    output.draw(image, in: CGRect(x: 0, y: 0, width: 64, height: 64))
    let pixels = try #require(output.data?.assumingMemoryBound(to: UInt8.self))
    #expect(pixels[0] < 10 && pixels[2] > 240)
    #expect(!view.state.imagePreviewsUnavailable)
    loader.cancel()
  }

  @Test func closingTheCanvasCancelsQueuedDecodeAndStatusUpdates() async throws {
    let view = VectorCanvasView(), loader = view.imagePreviews, context = try bitmap()
    loader.cache.prepare(images: try resources(red: 1, blue: 0), blobs: Data())
    #expect(loader.cache.resolve(node, context: context) == nil)
    loader.update(loader.cache.requests)
    let work = loader.task
    loader.cancel()
    await work?.value
    #expect(loader.cache.resolve(node, context: context) == nil)
    #expect(!view.state.imagePreviewsLoading && !view.state.imagePreviewsUnavailable)
  }

  @Test func failedPreviewDoesNotStayUnavailableAfterItsResourceIsReplaced() async throws {
    let view = VectorCanvasView(), loader = view.imagePreviews, context = try bitmap()
    loader.cache.prepare(images: .object([:]), blobs: Data())
    #expect(loader.cache.resolve(node, context: context) == nil)
    loader.update(loader.cache.requests)
    await loader.task?.value
    #expect(view.state.imagePreviewsUnavailable && !view.state.imagePreviewsLoading)
    loader.cache.prepare(images: try resources(red: 1, blue: 0), blobs: Data())
    #expect(loader.cache.resolve(node, context: context) == nil)
    loader.update(loader.cache.requests)
    await loader.task?.value
    #expect(loader.cache.resolve(node, context: context) != nil && !view.state.imagePreviewsLoading)
    #expect(!view.state.imagePreviewsUnavailable)
    loader.cancel()
  }
}
