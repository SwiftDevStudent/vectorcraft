import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import VectorCraftCore

struct BitmapFragmentTests {
  @Test func pngPastePreservesEncodedPixelsThroughNativeSave() throws {
    let bytes = try imageData(.png)
    let fragment = try VectorFragment(bitmapData: bytes)
    var drawing = Drawing()
    let id = try #require(try drawing.perform(.paste(fragment, .center(CGPoint(x: 200, y: 100)),
      container: 1, relativeTo: [])).first)
    let reopened = try NativeFormat.decode(NativeFormat.encode(drawing))
    let node = try #require(reopened.node(id))
    #expect(node.type == "image" && node.bounds == CGRect(x: 198, y: 99, width: 4, height: 2))
    #expect(VectorImage.data(node, images: reopened.envelope["images"], blobs: reopened.nativeBlobData) == bytes)
    #expect(reopened.renderingWarnings.isEmpty)
  }

  @Test func tiffPasteBecomesLosslessPortablePNGAtItsPhysicalSize() throws {
    let original = try imageData(.tiff, dpi: 144)
    let fragment = try VectorFragment(bitmapData: original)
    let node = try #require(fragment.nodes.first)
    #expect(node.bounds == CGRect(x: 0, y: 0, width: 2, height: 1))
    let bytes = try #require(VectorImage.data(node, images: fragment.drawing.envelope["images"]))
    #expect(bytes.starts(with: [137, 80, 78, 71, 13, 10, 26, 10]))
    let image = try #require(VectorImage.resolve(node, images: fragment.drawing.envelope["images"]))
    #expect(image.width == 4 && image.height == 2)
    let context = try bitmap()
    context.draw(image, in: CGRect(x: 0, y: 0, width: 4, height: 2))
    let source = try #require(CGImageSourceCreateWithData(original as CFData, nil))
    let reference = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
    let expected = try bitmap()
    expected.draw(reference, in: CGRect(x: 0, y: 0, width: 4, height: 2))
    let pixels = try #require(context.data?.assumingMemoryBound(to: UInt8.self))
    let referencePixels = try #require(expected.data?.assumingMemoryBound(to: UInt8.self))
    // Device RGB is color-managed: compare with the actual original, not an assumed RGB triplet.
    #expect(Array(UnsafeBufferPointer(start: pixels, count: 32))
      == Array(UnsafeBufferPointer(start: referencePixels, count: 32)))
  }

  @Test func malformedAndOversizedClipboardImagesAreRefused() throws {
    #expect(throws: DrawingError.self) { try VectorFragment(bitmapData: Data("not a picture".utf8)) }
    #expect(throws: DrawingError.self) {
      try VectorFragment(bitmapData: Data(repeating: 0, count: 16 * 1024 * 1024 + 1))
    }
  }

  private func bitmap() throws -> CGContext {
    try #require(CGContext(data: nil, width: 4, height: 2, bitsPerComponent: 8, bytesPerRow: 16,
      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
  }
  private func imageData(_ type: UTType, dpi: Double? = nil) throws -> Data {
    let context = try bitmap()
    context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: 4, height: 2))
    let bytes = NSMutableData()
    let destination = try #require(CGImageDestinationCreateWithData(bytes, type.identifier as CFString, 1, nil))
    let properties = dpi.map { [kCGImagePropertyDPIWidth: $0, kCGImagePropertyDPIHeight: $0] as CFDictionary }
    CGImageDestinationAddImage(destination, try #require(context.makeImage()), properties)
    #expect(CGImageDestinationFinalize(destination))
    return bytes as Data
  }
}
