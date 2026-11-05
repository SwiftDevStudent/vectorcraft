import CoreGraphics
import CryptoKit
import Foundation
import ImageIO

public struct ScreenshotFrameChoice: Identifiable, Sendable {
  public let id: String
  public let model: String
  public let name: String
  public let relativePath: String
}

public enum ScreenshotFrameInventory {
  public static func choices(inventory: URL) throws -> [ScreenshotFrameChoice] {
    let source = try JSONDecoder().decode(JSONValue.self, from: Data(contentsOf: inventory))
    return source["packs"].array.flatMap { $0["variants"].array }.compactMap { variant in
      guard variant["format"].string == "PNG", variant["measuredScreenBounds"]["alphaLessOrEqual1"] != .null else { return nil }
      let path = variant["path"].string
      guard let range = path.range(of: "local-use/"), !path.contains("..") else { return nil }
      return ScreenshotFrameChoice(id: path, model: variant["model"].string,
        name: [variant["finish"].string, variant["pose"].string].filter { !$0.isEmpty }.joined(separator: " · "),
        relativePath: String(path[range.lowerBound...]))
    }.sorted { ($0.model, $0.name) < ($1.model, $1.name) }
  }

  public static func reference(png: URL, inventory: URL) throws -> JSONValue {
    let bytes = try Data(contentsOf: png)
    let hash = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    let source = try JSONDecoder().decode(JSONValue.self, from: Data(contentsOf: inventory))
    guard png.pathExtension.lowercased() == "png",
      let match = source["packs"].array.flatMap({ $0["variants"].array }).first(where: {
        $0["format"].string == "PNG" && $0["sha256"].string == hash && $0["measuredScreenBounds"]["alphaLessOrEqual1"] != .null
      }) else { throw DrawingError.invalid("The PNG does not match a measured original in this inventory.") }
    return .object(["path": .string(png.standardizedFileURL.path), "sha256": .string(hash),
      "width": match["width"], "height": match["height"], "screen": match["measuredScreenBounds"]["alphaLessOrEqual1"]])
  }
}
extension Drawing {
  mutating func setScreenshotFrame(_ board: ScreenshotBoard, metadata: JSONValue?) throws -> Set<Int64> {
    guard let metadata, let w = metadata["width"].double, let h = metadata["height"].double,
      let pixelWidth = Int(exactly: w), let pixelHeight = Int(exactly: h),
      let x = metadata["screen"]["x"].double, let y = metadata["screen"]["y"].double,
      let sw = metadata["screen"]["width"].double, let sh = metadata["screen"]["height"].double,
      [w, h, x, y, sw, sh].allSatisfy(\.isFinite), w > 0, h > 0, sw > 0, sh > 0,
      x >= 0, y >= 0, x + sw <= w, y + sh <= h,
      let device = node(board.device), let clip = node(board.screen), let mask = clip.children.first else {
      throw DrawingError.invalid("Choose an original PNG with valid measured screen geometry.")
    }
    let originalBody = device.children.first { $0.raw["screenshotFrameBody"].boolean == true || $0.raw["kind"]["screenshotLocalFrame"] != .null }?.bounds ?? device.bounds
    guard !originalBody.isNull else { throw DrawingError.invalid("The device frame is missing.") }
    let scale = min(originalBody.width / w, originalBody.height / h)
    let origin = CGPoint(x: originalBody.midX - w * scale / 2, y: originalBody.midY - h * scale / 2)
    let sourceScreen = CGRect(x: x, y: y, width: sw, height: sh)
    let frameTransform = CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: origin.x, ty: origin.y)
    let frameID = try allocateID(), key = "local-frame-" + metadata["sha256"].string
    let raw: JSONValue = .object(["id": .integer(frameID), "name": .string(URL(fileURLWithPath: metadata["path"].string).lastPathComponent),
      "kind": .object(["type": .string("image"), "width": .number(w), "height": .number(h), "key": .string(key),
        "xf": frameTransform.json,
        "link": .string(metadata["path"].string), "screenshotLocalFrame": metadata])])
    guard let original = VectorImage.resolve(VectorNode(raw: raw), images: .object([:])), original.width == pixelWidth, original.height == pixelHeight else {
      throw DrawingError.invalid("The original local frame is unavailable, changed, or differs from the measured dimensions.")
    }
    // A transparent proxy preserves the existing native linked-image resource schema. Artwork
    // stays at its original local URL; it is never bundled or copied into the document envelope.
    envelope["images"][key] = .object(["mime": .string("image/png"), "proxy": .bool(true),
      "data": .string("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=")])
    let outline = CGMutablePath()
    outline.addPath(try ScreenCavity.path(in: original, screen: sourceScreen), transform: frameTransform)
    let paths = try PathGeometry.subpaths(outline).map { $0.json(version: version) }
    updateNode(mask.id) { $0["kind"]["path"]["subpaths"] = .array(paths) }
    if let placeholder = clip.children.first(where: { $0.id != mask.id && $0.type == "path" }) {
      updateNode(placeholder.id) { $0["kind"]["path"]["subpaths"] = .array(paths) }
    }
    updateNode(board.device) { value in
      var children = value["kind"]["children"].array.filter {
        $0["screenshotFrameBody"].boolean != true && $0["kind"]["screenshotLocalFrame"] == .null
      }
      children.append(raw); value["kind"]["children"] = .array(children)
      value["name"] = .string(URL(fileURLWithPath: metadata["path"].string).deletingPathExtension().lastPathComponent)
    }
    if let image = node(board.screen)?.children.first(where: { $0.type == "image" }) {
      let crop = image.raw["screenshotCrop"]
      _ = try perform(.screenshot(ScreenshotCommand(.crop, board: board.id,
        scale: crop["scale"].double ?? 1, cropX: crop["x"].double ?? 0, cropY: crop["y"].double ?? 0, fit: crop["fit"].boolean ?? false)))
    }
    return [board.device]
  }
}
