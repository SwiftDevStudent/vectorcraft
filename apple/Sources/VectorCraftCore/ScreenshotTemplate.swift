import CoreGraphics
import Foundation

public struct ScreenshotTemplate: Identifiable, Sendable {
  public let id: String
  public let name: String
  public static let all: [Self] = [
    .init(id: "headline", name: "Headline"), .init(id: "minimal", name: "Minimal"),
    .init(id: "split", name: "Split"), .init(id: "top-crop", name: "Phone Off Top"),
    .init(id: "bottom-crop", name: "Phone Off Bottom"),
  ]
  static func deviceRect(_ template: String, in rect: CGRect) -> CGRect {
    let w = rect.width, h = rect.height
    let local: CGRect
    switch template {
    case "minimal": local = CGRect(x: w * 0.1, y: h * 0.08, width: w * 0.8, height: h * 0.84)
    case "split": local = CGRect(x: w * 0.25, y: h * 0.35, width: w * 0.68, height: h * 0.60)
    case "top-crop": local = CGRect(x: w * 0.05, y: -h * 0.35, width: w * 0.9, height: h * 0.96)
    case "bottom-crop": local = CGRect(x: w * 0.05, y: h * 0.39, width: w * 0.9, height: h * 0.96)
    default: local = CGRect(x: w * 0.12, y: h * 0.28, width: w * 0.76, height: h * 0.65)
    }
    return local.offsetBy(dx: rect.minX, dy: rect.minY)
  }
  /// Shared by the real command and lightweight layout chooser schematics.
  public static func deviceFrame(_ template: String, source: CGSize, in rect: CGRect) -> CGRect {
    guard source.width > 0, source.height > 0 else { return .null }
    let target = deviceRect(template, in: rect)
    let cropped = ["top-crop", "bottom-crop"].contains(template)
    let scale = cropped ? target.width / source.width : min(target.width / source.width, target.height / source.height)
    let width = source.width * scale, height = source.height * scale
    return CGRect(x: target.midX - width / 2,
      y: template == "top-crop" ? target.maxY - height : target.minY, width: width, height: height)
  }
  public static func textRect(_ template: String, in rect: CGRect) -> CGRect {
    CGRect(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * (template == "top-crop" ? 0.74 : 0.055),
      width: rect.width * 0.84, height: rect.height * 0.18)
  }
}

extension Drawing {
  mutating func applyScreenshotTemplate(_ board: ScreenshotBoard, template: String, rect: CGRect) throws {
    guard ScreenshotTemplate.all.contains(where: { $0.id == template }), let device = node(board.device) else {
      throw DrawingError.invalid("Choose a screenshot layout.")
    }
    let version = version
    let source = device.bounds
    guard source.width > 0, source.height > 0, !source.isNull else { throw DrawingError.invalid("The device artwork is missing.") }
    let target = ScreenshotTemplate.deviceFrame(template, source: source.size, in: rect)
    let scale = target.width / source.width
    let xf = CGAffineTransform(translationX: -source.minX, y: -source.minY)
      .concatenating(.init(scaleX: scale, y: scale))
      .concatenating(.init(translationX: target.minX, y: target.minY))
    try updateNode(board.device) { try Self.transformNode(&$0, xf, version: version) }
    var headline = node(board.content)?.children.first(where: { $0.type == "text" })
    if headline == nil, board.content == board.device, template != "minimal" {
      let selected = try perform(.addAreaText("Find Every\nBusiness", ScreenshotTemplate.textRect(template, in: rect),
        font: "Helvetica", size: rect.width * 0.07, fill: VectorStyle.solid(1, 1, 1), layer: board.layer))
      if let text = selected.first {
        let group = try perform(.group([board.device, text])).first ?? board.content
        updateScreenshotBoard(board.id) { $0["content"] = .integer(group); $0["used"] = board.raw["used"] }
        headline = node(text)
      }
    }
    if let headline {
      let frame = ScreenshotTemplate.textRect(template, in: rect)
      updateNode(headline.id) { raw in
        raw["visible"] = .bool(template != "minimal")
        raw["kind"]["xf"] = CGAffineTransform(translationX: frame.minX, y: frame.minY).json
        raw["kind"]["kind"] = .object(["kind": .string("area"), "frame": .object([
          "subpaths": .array([ShapePaths.rectangle(CGRect(origin: .zero, size: frame.size)).json(version: version)])])])
      }
    }
    updateScreenshotBoard(board.id) { $0["template"] = .string(template) }
  }
}
