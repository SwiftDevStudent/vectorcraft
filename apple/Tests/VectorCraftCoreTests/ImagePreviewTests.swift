import CoreGraphics
import CryptoKit
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import VectorCraftCore

struct ImagePreviewTests {
  private func resources(_ bytes: Data) -> JSONValue {
    .object(["picture": .object(["mime": .string("image/png"), "data": .string(bytes.base64EncodedString())])])
  }
  private func png(_ red: CGFloat, _ blue: CGFloat, width: Int = 32, height: Int? = nil) throws -> Data {
    let height = height ?? width
    let context = try #require(CGContext(data: nil, width: width, height: height,
      bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.setFillColor(CGColor(red: red, green: 0, blue: blue, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let data = NSMutableData()
    let destination = try #require(CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil))
    CGImageDestinationAddImage(destination, try #require(context.makeImage()), nil)
    #expect(CGImageDestinationFinalize(destination))
    return data as Data
  }

  private func node() -> VectorNode {
    VectorNode(raw: .object(["id": .integer(2), "kind": .object([
      "type": .string("image"), "key": .string("picture"), "width": .number(1024),
      "height": .number(1024), "xf": CGAffineTransform.identity.json])]))
  }
  private func context() throws -> CGContext {
    try #require(CGContext(data: nil, width: 64, height: 64, bitsPerComponent: 8,
      bytesPerRow: 256, space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
  }
  private func redBlue(_ image: CGImage) throws -> (UInt8, UInt8) {
    let output = try context()
    output.draw(image, in: CGRect(x: 0, y: 0, width: 64, height: 64))
    let pixels = try #require(output.data?.assumingMemoryBound(to: UInt8.self))
    return (pixels[0], pixels[2])
  }

  @Test func previewsFollowResourceReplacementAndRestoreWithoutChangingSourceResolution() throws {
    let red = try png(1, 0, width: 1024), blue = try png(0, 1, width: 1024)
    let cache = VectorImagePreviewCache(), bitmap = try context(), imageNode = node()
    bitmap.scaleBy(x: 0.0625, y: 0.0625)
    for (bytes, expectedRed) in [(red, true), (blue, false), (red, true)] {
      let images = resources(bytes)
      cache.prepare(images: images, blobs: Data())
      let preview = try #require(cache.resolve(imageNode, context: bitmap))
      #expect(preview.width <= 128 && preview.height <= 128)
      let color = try redBlue(preview)
      #expect(expectedRed ? color.0 > 240 && color.1 < 10 : color.1 > 240 && color.0 < 10)
      #expect(VectorImage.resolve(imageNode, images: images)?.width == 1024)
      #expect(VectorImage.data(imageNode, images: images) == bytes)
    }
  }

  @Test func changedLinkedImageCannotReuseAnEarlierVerifiedPreview() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("VectorCraft-preview-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
    let file = folder.appendingPathComponent("Frame.png"), red = try png(1, 0), blue = try png(0, 1)
    try red.write(to: file)
    var imageNode = node()
    imageNode.raw["kind"]["screenshotLocalFrame"] = .object([
      "path": .string(file.path), "sha256": .string(SHA256.hash(data: red).map { String(format: "%02x", $0) }.joined())])
    let cache = VectorImagePreviewCache(), bitmap = try context()
    cache.prepare(images: .object([:]), blobs: Data())
    #expect(try redBlue(#require(cache.resolve(imageNode, context: bitmap))).0 > 240)
    try blue.write(to: file, options: .atomic)
    #expect(cache.resolve(imageNode, context: bitmap) == nil)
    #expect(VectorImage.resolve(imageNode, images: .object([:])) == nil)
    imageNode.raw["kind"]["screenshotLocalFrame"]["sha256"] = .string(SHA256.hash(data: blue).map { String(format: "%02x", $0) }.joined())
    #expect(try redBlue(#require(cache.resolve(imageNode, context: bitmap))).1 > 240)
  }

  @Test func deferredLookupQueuesOnceAndKeepsAnAvailableResolutionDuringZoom() throws {
    let bytes = try png(1, 0, width: 1024), imageNode = node()
    let cache = VectorImagePreviewCache(deferred: true), small = try context()
    small.scaleBy(x: 0.0625, y: 0.0625)
    cache.prepare(images: resources(bytes), blobs: Data())
    #expect(cache.resolve(imageNode, context: small) == nil)
    #expect(cache.resolve(imageNode, context: small) == nil)
    #expect(cache.requests.count == 1)
    let request = try #require(cache.requests.first)
    let decoded = try #require(try request.decode())
    #expect(cache.store(decoded, for: request))
    let low = try #require(cache.resolve(imageNode, context: small))
    #expect(low.width <= 128)
    cache.prepare(images: resources(bytes), blobs: Data())
    let largeContext = try context()
    let zoomed = try #require(cache.resolve(imageNode, context: largeContext))
    #expect(zoomed === low)
    let larger = try #require(cache.requests.first)
    let decodedLarge = try #require(try larger.decode())
    #expect(cache.store(decodedLarge, for: larger))
    let high = try #require(cache.resolve(imageNode, context: largeContext))
    #expect(high.width == 1024)
    #expect(try redBlue(high).0 > 240)
    #expect(VectorImage.data(imageNode, images: resources(bytes)) == bytes)
  }

  @Test func staleEmbeddedCompletionCannotReplaceNewerPixelsOrUndoResources() throws {
    let red = try png(1, 0), blue = try png(0, 1), imageNode = node()
    let cache = VectorImagePreviewCache(deferred: true), bitmap = try context()
    cache.prepare(images: resources(red), blobs: Data())
    _ = cache.resolve(imageNode, context: bitmap)
    let old = try #require(cache.requests.first), oldPixels = try #require(try old.decode())
    cache.prepare(images: resources(blue), blobs: Data())
    #expect(!cache.store(oldPixels, for: old))
    #expect(cache.resolve(imageNode, context: bitmap) == nil)
    let current = try #require(cache.requests.first)
    let decoded = try #require(try current.decode())
    #expect(cache.store(decoded, for: current))
    #expect(!cache.store(oldPixels, for: old))
    #expect(try redBlue(#require(cache.resolve(imageNode, context: bitmap))).1 > 240)
    cache.prepare(images: resources(red), blobs: Data())
    #expect(cache.store(oldPixels, for: old))
    #expect(try redBlue(#require(cache.resolve(imageNode, context: bitmap))).0 > 240)
  }

  @Test func linkedCompletionIsDiscardedWhenTheFileChangesDuringDecode() throws {
    let file = FileManager.default.temporaryDirectory.appendingPathComponent("VectorCraft-deferred-" + UUID().uuidString + ".png")
    let red = try png(1, 0), blue = try png(0, 1)
    try red.write(to: file)
    var imageNode = node()
    imageNode.raw["kind"]["screenshotLocalFrame"] = .object([
      "path": .string(file.path), "sha256": .string(SHA256.hash(data: red).map { String(format: "%02x", $0) }.joined())])
    let cache = VectorImagePreviewCache(deferred: true), bitmap = try context()
    cache.prepare(images: .object([:]), blobs: Data())
    _ = cache.resolve(imageNode, context: bitmap)
    let old = try #require(cache.requests.first), pixels = try #require(try old.decode())
    try blue.write(to: file, options: .atomic)
    #expect(!cache.isCurrent(old))
    #expect(!cache.store(pixels, for: old))
    #expect(cache.resolve(imageNode, context: bitmap) == nil)
  }

  @Test func offscreenImagesDoNotRequestDecoding() throws {
    var imageNode = node()
    imageNode.raw["kind"]["xf"] = CGAffineTransform(translationX: 2000, y: 2000).json
    let cache = VectorImagePreviewCache(deferred: true)
    cache.prepare(images: resources(try png(1, 0)), blobs: Data())
    let bitmap = try context()
    #expect(cache.resolve(imageNode, context: bitmap) == nil)
    #expect(cache.requests.isEmpty)
  }

  @Test func deferredProxyLimitDoesNotReduceTheOriginalImage() throws {
    let bytes = try png(1, 0, width: 8192, height: 1)
    var imageNode = node()
    imageNode.raw["kind"]["width"] = .integer(8192)
    imageNode.raw["kind"]["height"] = .integer(1)
    let images = resources(bytes), cache = VectorImagePreviewCache(deferred: true)
    cache.prepare(images: images, blobs: Data())
    let bitmap = try context()
    #expect(cache.resolve(imageNode, context: bitmap) == nil)
    let request = try #require(cache.requests.first)
    let proxy = try #require(try request.decode())
    #expect(proxy.width <= 4096)
    #expect(VectorImage.resolve(imageNode, images: images)?.width == 8192)
    #expect(VectorImage.data(imageNode, images: images) == bytes)
  }
}
