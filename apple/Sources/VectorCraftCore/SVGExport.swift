import CoreGraphics
import Foundation

public enum SVGExport {
  public static func encode(_ drawing: Drawing, artboard index: Int = 0) throws -> Data {
    guard drawing.renderingWarnings.isEmpty, drawing.artboards.indices.contains(index) else {
      throw DrawingError.invalid(
        "SVG export requires a valid artboard and fully supported artwork. Native saving preserves unsupported features."
      )
    }
    let board = drawing.artboards[index]
    var defs = ""
    var body = ""
    var counter = 0
    func number(_ n: Double) -> String { String(n) }
    func rgb(_ color: JSONValue) -> String {
      let components = VectorRenderer.color(color).components ?? [0, 0, 0, 1]
      return
        "rgb(\(Int((components.first ?? 0)*255)),\(Int((components.dropFirst().first ?? 0)*255)),\(Int((components.dropFirst(2).first ?? 0)*255)))"
    }
    func paint(_ value: JSONValue, bounds: CGRect) -> String {
      if value["type"].string == "none" { return "none" }
      if value["type"].string == "solid" { return rgb(value["color"]) }
      counter += 1
      let id = "gradient\(counter)"
      let radial = value["gradient"]["kind"].string == "Radial"
      let geometry = GradientGeometry(paint: value, bounds: bounds)
      let start = geometry.start
      let end = geometry.end
      let tag = radial ? "radialGradient" : "linearGradient"
      let attributes =
        radial
        ? "cx=\"0\" cy=\"0\" r=\"\(start.distance(to:end))\" gradientTransform=\"translate(\(start.x) \(start.y)) rotate(\(atan2(end.y-start.y,end.x-start.x)*180 / .pi)) scale(1 \(geometry.aspect))\""
        : "x1=\"\(start.x)\" y1=\"\(start.y)\" x2=\"\(end.x)\" y2=\"\(end.y)\""
      let stops = value["gradient"]["stops"].array.map {
        "<stop offset=\"\($0["offset"].double ?? 0)\" stop-color=\"\(rgb($0["color"]))\" stop-opacity=\"\($0["opacity"].double ?? 1)\"/>"
      }.joined()
      defs +=
        "<\(tag) id=\"\(id)\" gradientUnits=\"userSpaceOnUse\" \(attributes)>\(stops)</\(tag)>"
      return "url(#\(id))"
    }
    func pathData(_ node: VectorNode) -> String {
      if node.type == "compound" { return node.children.map(pathData).joined(separator: " ") }
      return node.subpaths.map { path in
        guard let first = path.anchors.first else { return "" }
        var d = "M \(first.point.x) \(first.point.y)"
        func segment(_ a: VectorAnchor, _ b: VectorAnchor) -> String {
          if a.outgoing == a.point && b.incoming == b.point {
            return " L \(b.point.x) \(b.point.y)"
          }
          return
            " C \(a.outgoing.x) \(a.outgoing.y) \(b.incoming.x) \(b.incoming.y) \(b.point.x) \(b.point.y)"
        }
        for (a, b) in zip(path.anchors, path.anchors.dropFirst()) { d += segment(a, b) }
        if path.closed, let last = path.anchors.last { d += segment(last, first) + " Z" }
        return d
      }.joined(separator: " ")
    }
    func glyphPath(_ path: CGPath) -> String {
      var d = ""
      path.applyWithBlock { element in
        let e = element.pointee
        switch e.type {
        case .moveToPoint: d += "M \(e.points[0].x) \(e.points[0].y) "
        case .addLineToPoint: d += "L \(e.points[0].x) \(e.points[0].y) "
        case .addQuadCurveToPoint:
          d += "Q \(e.points[0].x) \(e.points[0].y) \(e.points[1].x) \(e.points[1].y) "
        case .addCurveToPoint:
          d +=
            "C \(e.points[0].x) \(e.points[0].y) \(e.points[1].x) \(e.points[1].y) \(e.points[2].x) \(e.points[2].y) "
        case .closeSubpath: d += "Z "
        @unknown default: break
        }
      }
      return d
    }
    func render(_ nodes: [VectorNode]) -> String {
      var result = ""
      for node in nodes where node.visible && node.raw["kind"]["guide"].boolean != true {
        result += "<g opacity=\"\(number(node.opacity))\">"
        if ["layer", "group"].contains(node.type) {
          var children = node.children
          if node.raw["kind"]["clip"].boolean == true, let clip = children.first {
            counter += 1
            let id = "clip\(counter)"
            defs += "<clipPath id=\"\(id)\"><path d=\"\(pathData(clip))\"/></clipPath>"
            result += "<g clip-path=\"url(#\(id))\">"
            children = Array(children.dropFirst())
            result += render(children) + "</g>"
          } else {
            result += render(children)
          }
        } else if node.type == "image" {
          result += VectorImage.svg(node, images: drawing.envelope["images"], blobs: drawing.nativeBlobData)
        } else if node.type == "text" {
          for part in VectorText.parts(node) {
            let style = part.style
            let fill =
              style["fill"]["type"].string == "solid" ? rgb(style["fill"]["color"]) : "none"
            let stroke =
              style["stroke"]["type"].string == "solid" ? rgb(style["stroke"]["color"]) : "none"
            result +=
              "<path d=\"\(glyphPath(part.path))\" fill=\"\(fill)\" stroke=\"\(stroke)\" stroke-width=\"\(style["stroke_width"].double ?? 0)\"/>"
          }
        } else {
          if node.bounds.isNull {
            result += "</g>"
            continue
          }
          for item in node.raw["appearance"]["items"].array where item["visible"].boolean != false {
            let fill = item["kind"].string == "fill"
            let width = max(0, item["width"].double ?? 1)
            let bounds = fill ? node.bounds : node.bounds.insetBy(dx: -width / 2, dy: -width / 2)
            let p = paint(item["paint"], bounds: bounds)
            let lengths = item["dash"]["pattern"].array.compactMap(\.double)
            let dashed = lengths.allSatisfy({ $0 >= 0 }) && lengths.contains(where: { $0 > 0 })
            let dash = dashed ? lengths.map { String($0) }.joined(separator: ",") : "none"
            let cap =
              item["cap"].string == "Round"
              ? "round" : item["cap"].string == "Square" ? "square" : "butt"
            let join =
              item["join"].string == "Round"
              ? "round" : item["join"].string == "Bevel" ? "bevel" : "miter"
            let attributes =
              fill
              ? "fill=\"\(p)\" stroke=\"none\""
              : "fill=\"none\" stroke=\"\(p)\" stroke-width=\"\(max(0,item["width"].double ?? 1))\" stroke-linecap=\"\(cap)\" stroke-linejoin=\"\(join)\" stroke-miterlimit=\"\(min(10000,max(1,item["miter_limit"].double ?? 10)))\" stroke-dasharray=\"\(dash)\" stroke-dashoffset=\"\(item["dash"]["offset"].double ?? 0)\""
            result +=
              "<path d=\"\(pathData(node))\" \(attributes) fill-rule=\"\(node.raw["kind"]["rule"].string == "EvenOdd" ? "evenodd" : "nonzero")\" opacity=\"\(item["opacity"].double ?? 1)\"/>"
          }
        }
        result += "</g>"
      }
      return result
    }
    body = render(drawing.layers)
    return Data(
      "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(board.width)pt\" height=\"\(board.height)pt\" viewBox=\"\(board.minX) \(board.minY) \(board.width) \(board.height)\"><defs>\(defs)</defs>\(body)</svg>"
        .utf8)
  }
}
