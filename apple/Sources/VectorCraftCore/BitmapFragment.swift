import CoreGraphics
import CryptoKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

extension VectorFragment {
  /// Prepare clipboard pixels before entering the document's ordinary paste command.
  /// PNG bytes stay intact; macOS clipboard TIFF becomes a portable lossless PNG.
  public init(bitmapData data: Data) throws {
    guard !data.isEmpty, data.count <= 16 * 1024 * 1024,
      let source = CGImageSourceCreateWithData(data as CFData, nil),
      let type = CGImageSourceGetType(source) as String?,
      [UTType.png.identifier, UTType.tiff.identifier].contains(type),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let width = properties[kCGImagePropertyPixelWidth] as? Int,
      let height = properties[kCGImagePropertyPixelHeight] as? Int,
      (1...16384).contains(width), (1...16384).contains(height), width * height <= 32_000_000
    else {
      throw DrawingError.invalid("Paste a PNG or TIFF up to 16 MB and 32 megapixels (16,384 pixels per side).")
    }
    try Task.checkCancellation()
    guard let image = CGImageSourceCreateImageAtIndex(source, 0,
      [kCGImageSourceShouldCacheImmediately: true] as CFDictionary),
      CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete
    else { throw DrawingError.invalid("The clipboard image is damaged.") }
    let bytes: Data
    if type == UTType.png.identifier { bytes = data }
    else {
      let output = NSMutableData()
      guard let destination = CGImageDestinationCreateWithData(output, UTType.png.identifier as CFString, 1, nil)
      else { throw DrawingError.invalid("Could not prepare the clipboard image.") }
      CGImageDestinationAddImage(destination, image, nil)
      guard CGImageDestinationFinalize(destination), output.length <= 16 * 1024 * 1024 else {
        throw DrawingError.invalid("The prepared clipboard image exceeds the 16 MB limit.")
      }
      bytes = output as Data
    }
    try Task.checkCancellation()
    func scale(_ key: CFString) -> Double {
      guard let dpi = properties[key] as? Double, dpi.isFinite, dpi > 0 else { return 1 }
      return 72 / dpi
    }
    let xf = CGAffineTransform(scaleX: scale(kCGImagePropertyDPIWidth), y: scale(kCGImagePropertyDPIHeight))
    let bounds = CGRect(x: 0, y: 0, width: width, height: height).applying(xf)
    guard bounds.width.isFinite, bounds.height.isFinite,
      bounds.width > 0, bounds.height > 0, bounds.width <= 1_000_000, bounds.height <= 1_000_000
    else { throw DrawingError.invalid("The clipboard image has an invalid physical size.") }
    let key = "clipboard-" + SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    var sourceDrawing = Drawing()
    sourceDrawing.envelope["images"][key] = .object([
      "mime": .string("image/png"), "data": .string(bytes.base64EncodedString()),
    ])
    var layer = sourceDrawing.layers[0].raw
    layer["kind"]["children"] = .array([.object([
      "id": .integer(2), "name": .string("Pasted Image"),
      "kind": .object(["type": .string("image"), "key": .string(key),
        "width": .integer(Int64(width)), "height": .integer(Int64(height)), "xf": xf.json]),
    ])])
    sourceDrawing.envelope["document"]["layers"] = .array([layer])
    sourceDrawing.envelope["document"]["next_id"] = .integer(3)
    try self.init(copying: [2], from: sourceDrawing)
  }
}
