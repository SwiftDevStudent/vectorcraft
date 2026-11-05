import CoreGraphics
import Foundation

extension VectorText {
  /// Rectangular area frames supported by the Swift editor. Other paths stay intact.
  public static func areaRect(_ node: VectorNode) -> CGRect? {
    let kind = node.raw["kind"]["kind"]
    guard kind["kind"].string == "area" else { return nil }
    let paths = kind["frame"]["subpaths"].array
    guard paths.count == 1, let path = paths.first, path["closed"].boolean == true else {
      return nil
    }
    let anchors = path["anchors"].array.compactMap(VectorAnchor.init)
    guard anchors.count == 4,
      anchors.allSatisfy({ $0.incoming == $0.point && $0.outgoing == $0.point })
    else { return nil }
    let points = anchors.map(\.point)
    let nextPoints = Array(points.dropFirst()) + Array(points.prefix(1))
    guard
      zip(points, nextPoints).allSatisfy({
        ($0.x == $1.x) != ($0.y == $1.y)
      })
    else { return nil }
    let rect = anchors.reduce(CGRect.null) { $0.union(CGRect(origin: $1.point, size: .zero)) }
    guard !rect.isNull, rect.width > 0, rect.height > 0,
      [rect.minX, rect.minY, rect.maxX, rect.maxY].allSatisfy(\.isFinite),
      anchors.allSatisfy({
        ($0.point.x == rect.minX || $0.point.x == rect.maxX)
          && ($0.point.y == rect.minY || $0.point.y == rect.maxY)
      })
    else { return nil }
    return rect
  }

  public static func canEditInline(_ node: VectorNode) -> Bool {
    guard node.type == "text", node.raw["kind"]["runs"].array.count == 1,
      node.raw["kind"]["runs"].array.first?["style"]["all_caps"].boolean != true,
      warnings(node).isEmpty
    else { return false }
    return node.raw["kind"]["kind"]["kind"].string == "point" || areaRect(node) != nil
  }
}
