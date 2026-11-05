import CoreGraphics
import Foundation

extension SVGImporter {
  func shape(_ node: SVGElement, viewport: CGSize) throws -> CGPath {
    guard node.children.allSatisfy({ ["title", "desc", "metadata"].contains($0.name) }) else {
      throw svgError("Animated or nested shape content is not supported yet.")
    }
    let path = CGMutablePath()
    func x(_ key: String, fallback: String = "0") throws -> Double {
      try length(node, key, size: viewport.width, fallback: fallback)
    }
    func y(_ key: String, fallback: String = "0") throws -> Double {
      try length(node, key, size: viewport.height, fallback: fallback)
    }
    switch node.name {
    case "path": return try SVGPath.parse(node.attributes["d"] ?? "")
    case "rect":
      let width = try x("width")
      let height = try y("height")
      guard width >= 0, height >= 0 else { throw svgError("Negative rectangle size.") }
      if width == 0 || height == 0 { return path }
      let rect = try CGRect(x: x("x"), y: y("y"), width: width, height: height)
      let rx = try x("rx", fallback: node.attributes["ry"] ?? "0")
      let ry = try y("ry", fallback: node.attributes["rx"] ?? "0")
      guard rx >= 0, ry >= 0 else { throw svgError("Negative rectangle corner radius.") }
      path.addRoundedRect(
        in: rect, cornerWidth: min(rx, width / 2), cornerHeight: min(ry, height / 2))
    case "circle", "ellipse":
      let diagonal = hypot(viewport.width, viewport.height) / sqrt(2)
      let rx = node.name == "circle" ? try length(node, "r", size: diagonal) : try x("rx")
      let ry = node.name == "circle" ? rx : try y("ry")
      guard rx >= 0, ry >= 0 else { throw svgError("Negative ellipse radius.") }
      if rx > 0 && ry > 0 {
        path.addEllipse(
          in: try CGRect(x: x("cx") - rx, y: y("cy") - ry, width: rx * 2, height: ry * 2))
      }
    case "line":
      path.move(to: try CGPoint(x: x("x1"), y: y("y1")))
      path.addLine(to: try CGPoint(x: x("x2"), y: y("y2")))
    case "polygon", "polyline":
      var scanner = SVGNumbers(node.attributes["points"] ?? "")
      let points = try scanner.list()
      guard points.count.isMultiple(of: 2) else { throw svgError("Polygon points need x/y pairs.") }
      for i in stride(from: 0, to: points.count, by: 2) {
        let p = CGPoint(x: points[i], y: points[i + 1])
        if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
      }
      if node.name == "polygon", points.count >= 4 { path.closeSubpath() }
    default:
      throw svgError("The \(node.name) element is not supported yet; the source SVG is unchanged.")
    }
    return path
  }
}
