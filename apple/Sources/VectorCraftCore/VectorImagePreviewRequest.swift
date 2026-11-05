import CoreGraphics
import Foundation
import ImageIO

/// Immutable source snapshot; decoding never accesses a canvas or its mutable cache.
public struct VectorImagePreviewRequest: Equatable, Sendable {
  let node: VectorNode
  let images: JSONValue
  let blobs: Data
  let identity: [String]
  let pixels: Int
  var key: [String] { identity + [String(pixels)] }

  public func decode() throws -> CGImage? {
    try Task.checkCancellation()
    guard let bytes = VectorImage.data(node, images: images, blobs: blobs),
      let source = CGImageSourceCreateWithData(bytes as CFData,
        [kCGImageSourceShouldCache: false] as CFDictionary) else { return nil }
    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceThumbnailMaxPixelSize: pixels,
      kCGImageSourceCreateThumbnailWithTransform: false,
      // Finish pixel decoding on the worker, rather than deferring it until draw().
      kCGImageSourceShouldCacheImmediately: true,
    ]
    let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
      ?? CGImageSourceCreateImageAtIndex(source, 0,
        [kCGImageSourceShouldCacheImmediately: true] as CFDictionary)
    try Task.checkCancellation()
    return image
  }
}
