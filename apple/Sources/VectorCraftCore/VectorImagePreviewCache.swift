import CoreGraphics
import Foundation

/// Owned by one renderer. Deferred consumers decode immutable requests off the drawing thread.
public final class VectorImagePreviewCache {
  private final class Entry: NSObject {
    let image: CGImage
    init(_ image: CGImage) { self.image = image }
  }
  private let cache = NSCache<NSArray, Entry>()
  private let budget = 128 * 1024 * 1024
  private var images: JSONValue = .null
  private var blobs = Data()
  private let deferred: Bool
  public private(set) var requests: [VectorImagePreviewRequest] = []
  private var requestedKeys = Set<[String]>()

  public init(deferred: Bool = false) {
    self.deferred = deferred
    cache.totalCostLimit = budget
    cache.countLimit = 128
  }

  func prepare(images: JSONValue, blobs: Data) {
    requests.removeAll(keepingCapacity: true)
    requestedKeys.removeAll(keepingCapacity: true)
    if self.images != images || self.blobs != blobs {
      cache.removeAllObjects()
      self.images = images
      self.blobs = blobs
    }
  }

  func resolve(_ node: VectorNode, context: CGContext) -> CGImage? {
    guard VectorImage.bounds(node).intersects(context.boundingBoxOfClipPath) else { return nil }
    let kind = node.raw["kind"]
    guard let transform = kind["xf"].affine,
      let width = kind["width"].double, let height = kind["height"].double,
      width > 0, height > 0 else { return nil }
    let device = transform.concatenating(context.ctm)
    let required = max(width, height) * max(hypot(device.a, device.b), hypot(device.c, device.d))
    guard required.isFinite, required > 0 else { return nil }
    // Resolution buckets avoid decoding again for every small zoom animation step.
    var pixels = 64
    let maximumPixels = deferred ? 4096 : 8192
    while Double(pixels) < required && pixels < maximumPixels { pixels *= 2 }
    guard let identity = Self.identity(node) else { return nil }
    let request = VectorImagePreviewRequest(node: node, images: images, blobs: blobs,
      identity: identity, pixels: pixels)
    if let entry = cache.object(forKey: request.key as NSArray) { return entry.image }
    if deferred {
      if requestedKeys.insert(request.key).inserted { requests.append(request) }
      // Keep drawing an available resolution during zoom while its replacement loads.
      var candidate = pixels / 2
      while candidate >= 64 {
        if let entry = cache.object(forKey: (identity + [String(candidate)]) as NSArray) { return entry.image }
        candidate /= 2
      }
      candidate = pixels * 2
      while candidate <= 8192 {
        if let entry = cache.object(forKey: (identity + [String(candidate)]) as NSArray) { return entry.image }
        candidate *= 2
      }
      return nil
    }
    guard let image = try? request.decode() else { return nil }
    _ = store(image, for: request)
    return image
  }

  public func isCurrent(_ request: VectorImagePreviewRequest) -> Bool {
    request.images == images && request.blobs == blobs
      && Self.identity(request.node) == request.identity
  }

  @discardableResult
  public func store(_ image: CGImage, for request: VectorImagePreviewRequest) -> Bool {
    guard isCurrent(request) else { return false }
    let (cost, overflow) = image.bytesPerRow.multipliedReportingOverflow(by: image.height)
    guard !overflow, cost <= budget else { return false }
    cache.setObject(Entry(image), forKey: request.key as NSArray, cost: cost)
    return cache.object(forKey: request.key as NSArray) != nil
  }

  private static func identity(_ node: VectorNode) -> [String]? {
    let kind = node.raw["kind"]
    let url = VectorImage.localURL(node)
    let scoped = url?.startAccessingSecurityScopedResource() ?? false
    defer { if scoped { url?.stopAccessingSecurityScopedResource() } }
    var identity = [kind["key"].string]
    if let url {
      guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
        let modified = attributes[.modificationDate] as? Date,
        let size = attributes[.size] as? NSNumber else { return nil }
      identity += [url.path, kind["screenshotLocalFrame"]["sha256"].string,
        String(modified.timeIntervalSinceReferenceDate), size.stringValue,
        String(describing: attributes[.systemFileNumber] ?? "")]
    }
    return identity
  }
}
