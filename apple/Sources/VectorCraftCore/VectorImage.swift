import CoreGraphics
import Foundation
import ImageIO
import CryptoKit

/// Raster image nodes use the existing native image-resource and pixel-space affine schema.
public enum VectorImage {
  public static func bounds(_ node: VectorNode) -> CGRect {
    guard let w = node.raw["kind"]["width"].double, let h = node.raw["kind"]["height"].double,
      w > 0, h > 0, let xf = node.raw["kind"]["xf"].affine else { return .null }
    return CGRect(x: 0, y: 0, width: w, height: h).applying(xf)
  }
  public static func localURL(_ node: VectorNode) -> URL? {
    let metadata = node.raw["kind"]["screenshotLocalFrame"]
    let path = metadata["path"].string
    guard !path.isEmpty else { return nil }
    let fallback = URL(fileURLWithPath: path)
    guard let bytes = Data(base64Encoded: metadata["bookmark"].string), !bytes.isEmpty else { return fallback }
    var stale = false
    return (try? URL(resolvingBookmarkData: bytes, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &stale)) ?? fallback
  }
  public static func data(_ node: VectorNode, images: JSONValue, blobs: Data = Data()) -> Data? {
    let kind = node.raw["kind"]
    if let url = localURL(node) {
      let scoped = url.startAccessingSecurityScopedResource()
      defer { if scoped { url.stopAccessingSecurityScopedResource() } }
      guard let bytes = try? Data(contentsOf: url) else { return nil }
      let hash = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
      return hash == kind["screenshotLocalFrame"]["sha256"].string ? bytes : nil
    }
    return try? NativeBlob.data(images[kind["key"].string], in: blobs)
  }
  public static func resolve(_ node: VectorNode, images: JSONValue, blobs: Data = Data()) -> CGImage? {
    guard let bytes = data(node, images: images, blobs: blobs),
      let source = CGImageSourceCreateWithData(bytes as CFData, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
  }
  public static func render(_ node: VectorNode, images: JSONValue, blobs: Data, context: CGContext,
    previewImages: VectorImagePreviewCache? = nil) {
    let image: CGImage?
    if let previewImages { image = previewImages.resolve(node, context: context) }
    else { image = resolve(node, images: images, blobs: blobs) }
    guard let image, let xf = node.raw["kind"]["xf"].affine,
      let width = node.raw["kind"]["width"].double, let height = node.raw["kind"]["height"].double else { return }
    context.saveGState(); defer { context.restoreGState() }
    context.concatenate(xf)
    context.translateBy(x: 0, y: height); context.scaleBy(x: 1, y: -1)
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
  }
  public static func svg(_ node: VectorNode, images: JSONValue, blobs: Data) -> String {
    let kind = node.raw["kind"]
    guard let xf = kind["xf"].affine else { return "" }
    let local = kind["screenshotLocalFrame"]["path"].string
    let resource = images[kind["key"].string]
    let href: String
    if local.isEmpty {
      guard let bytes = data(node, images: images, blobs: blobs) else { return "" }
      href = "data:\(resource["mime"].string);base64,\(bytes.base64EncodedString())"
    } else { href = localURL(node)?.absoluteString ?? "" }
    return "<image width=\"\(kind["width"].double ?? 0)\" height=\"\(kind["height"].double ?? 0)\" transform=\"matrix(\(xf.a) \(xf.b) \(xf.c) \(xf.d) \(xf.tx) \(xf.ty))\" href=\"\(href.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "\"", with: "&quot;"))\"/>"
  }
}
