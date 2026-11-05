import CoreGraphics

public enum ShapePaths {
  public static func polygon(_ rect: CGRect, sides: Int = 6) -> VectorSubpath {
    let count = min(100, max(3, sides))
    let points = (0..<count).map { index in
      let angle = Double(index) * 2 * .pi / Double(count) - .pi / 2
      return VectorAnchor(
        CGPoint(
          x: rect.midX + cos(angle) * rect.width / 2,
          y: rect.midY + sin(angle) * rect.height / 2))
    }
    return VectorSubpath(anchors: points, closed: true)
  }
  public static func rectangle(_ rect: CGRect) -> VectorSubpath {
    VectorSubpath(
      anchors: [
        CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY),
        CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY),
      ].map { VectorAnchor($0) }, closed: true)
  }
  public static func ellipse(_ rect: CGRect) -> VectorSubpath {
    let x = rect.midX
    let y = rect.midY
    let rx = rect.width / 2
    let ry = rect.height / 2
    let k: CGFloat = 0.5522847498307936
    return VectorSubpath(
      anchors: [
        VectorAnchor(
          CGPoint(x: x, y: y - ry), incoming: CGPoint(x: x - rx * k, y: y - ry),
          outgoing: CGPoint(x: x + rx * k, y: y - ry), smooth: true),
        VectorAnchor(
          CGPoint(x: x + rx, y: y), incoming: CGPoint(x: x + rx, y: y - ry * k),
          outgoing: CGPoint(x: x + rx, y: y + ry * k), smooth: true),
        VectorAnchor(
          CGPoint(x: x, y: y + ry), incoming: CGPoint(x: x + rx * k, y: y + ry),
          outgoing: CGPoint(x: x - rx * k, y: y + ry), smooth: true),
        VectorAnchor(
          CGPoint(x: x - rx, y: y), incoming: CGPoint(x: x - rx, y: y + ry * k),
          outgoing: CGPoint(x: x - rx, y: y - ry * k), smooth: true),
      ], closed: true)
  }
  public static func star(_ rect: CGRect) -> VectorSubpath {
    let r = min(rect.width, rect.height) / 2
    return VectorSubpath(
      anchors: (0..<10).map { i in
        let angle = CGFloat(i) * .pi / 5 - .pi / 2
        let radius = i % 2 == 0 ? r : r * 0.45
        return VectorAnchor(
          CGPoint(x: rect.midX + cos(angle) * radius, y: rect.midY + sin(angle) * radius))
      }, closed: true)
  }
}
