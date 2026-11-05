import CoreGraphics
import Foundation

enum SVGLength {
  /// SVG user units are CSS px; the document boundary converts 96 px to 72 points.
  static func value(_ text: String, relativeTo extent: Double, font: Double = 16) throws -> Double {
    var scanner = SVGNumbers(text.trimmingCharacters(in: .whitespacesAndNewlines))
    let n = try scanner.number()
    let unit = String(decoding: scanner.bytes.dropFirst(scanner.index), as: UTF8.self)
    let scale: Double
    switch unit {
    case "", "px": scale = 1
    case "%": scale = extent / 100
    case "pt": scale = 96 / 72
    case "pc": scale = 16
    case "in": scale = 96
    case "cm": scale = 96 / 2.54
    case "mm": scale = 96 / 25.4
    case "q": scale = 96 / 101.6
    case "em": scale = font
    default: throw svgError("Unsupported length unit: \(unit).")
    }
    let value = n * scale
    guard value.isFinite, abs(value) <= 1_000_000 else {
      throw svgError("Length exceeds supported limits.")
    }
    return value
  }
  static func opacity(_ text: String?) throws -> Double {
    guard let text else { return 1 }
    let percent = text.hasSuffix("%")
    var scanner = SVGNumbers(percent ? String(text.dropLast()) : text)
    let value = try scanner.number()
    scanner.spaces()
    guard scanner.next == nil else { throw svgError("Invalid opacity.") }
    return min(1, max(0, value / (percent ? 100 : 1)))
  }
}

struct SVGViewport {
  var size: CGSize
  var transform: CGAffineTransform
  static func make(attributes: [String: String], parent: CGSize = CGSize(width: 300, height: 150))
    throws -> SVGViewport
  {
    var box: [Double] = []
    if let text = attributes["viewBox"] {
      var scanner = SVGNumbers(text)
      box = try scanner.list()
      guard box.count == 4, box[2] > 0, box[3] > 0, box.allSatisfy({ abs($0) <= 1_000_000 }) else {
        throw svgError("Invalid viewBox.")
      }
    }
    let width = try SVGLength.value(
      attributes["width"] ?? (box.isEmpty ? String(Double(parent.width)) : String(box[2])),
      relativeTo: parent.width)
    let height = try SVGLength.value(
      attributes["height"] ?? (box.isEmpty ? String(Double(parent.height)) : String(box[3])),
      relativeTo: parent.height)
    guard width > 0, height > 0 else {
      throw svgError("The SVG viewport must have positive dimensions.")
    }
    guard !box.isEmpty else {
      return SVGViewport(size: CGSize(width: width, height: height), transform: .identity)
    }
    let sx = width / box[2]
    let sy = height / box[3]
    let aspect = (attributes["preserveAspectRatio"] ?? "xMidYMid meet").split(
      whereSeparator: \.isWhitespace
    ).map(String.init)
    guard aspect.count <= 2, let align = aspect.first else {
      throw svgError("Invalid preserveAspectRatio.")
    }
    let xScale: Double
    let yScale: Double
    let dx: Double
    let dy: Double
    if align == "none" {
      xScale = sx
      yScale = sy
      dx = 0
      dy = 0
    } else {
      guard
        [
          "xMinYMin", "xMidYMin", "xMaxYMin", "xMinYMid", "xMidYMid", "xMaxYMid", "xMinYMax",
          "xMidYMax", "xMaxYMax",
        ].contains(align), aspect.count < 2 || ["meet", "slice"].contains(aspect[1])
      else { throw svgError("Unsupported preserveAspectRatio.") }
      let scale = aspect.last == "slice" ? max(sx, sy) : min(sx, sy)
      xScale = scale
      yScale = scale
      dx =
        (width - box[2] * scale) * (align.hasPrefix("xMid") ? 0.5 : align.hasPrefix("xMax") ? 1 : 0)
      dy =
        (height - box[3] * scale)
        * (align.hasSuffix("YMid") ? 0.5 : align.hasSuffix("YMax") ? 1 : 0)
    }
    let transform = CGAffineTransform(translationX: -box[0], y: -box[1]).concatenating(
      CGAffineTransform(scaleX: xScale, y: yScale)
    ).concatenating(CGAffineTransform(translationX: dx, y: dy))
    return SVGViewport(size: CGSize(width: width, height: height), transform: transform)
  }
  static func userSize(_ attributes: [String: String], fallback: CGSize) throws -> CGSize {
    guard let text = attributes["viewBox"] else { return fallback }
    var scanner = SVGNumbers(text)
    let values = try scanner.list()
    guard values.count == 4 else { throw svgError("Invalid viewBox.") }
    return CGSize(width: values[2], height: values[3])
  }
}
