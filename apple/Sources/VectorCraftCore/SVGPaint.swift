import CoreGraphics
import Foundation

extension SVGImporter {
  func paint(
    _ source: String, bounds: CGRect, transform: CGAffineTransform, viewport: CGSize,
    currentColor: String
  ) throws -> (JSONValue, Double) {
    if source.lowercased() == "none" { return (VectorStyle.none, 1) }
    if source.lowercased().hasPrefix("url(") {
      guard source.hasSuffix(")") else {
        throw svgError("Paint fallback lists are not supported yet.")
      }
      let ref = source.dropFirst(4).dropLast().trimmingCharacters(
        in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"'")))
      guard ref.hasPrefix("#"), let definition = definitions[String(ref.dropFirst())],
        ["linearGradient", "radialGradient"].contains(definition.name)
      else { throw svgError("Missing or unsupported local paint reference: \(ref).") }
      return try gradient(definition, bounds: bounds, transform: transform, viewport: viewport)
    }
    let color = try SVGColor.parse(source.lowercased() == "currentcolor" ? currentColor : source)
    return (.object(["type": .string("solid"), "color": color.value]), color.alpha)
  }
  private func gradient(
    _ node: SVGElement, bounds: CGRect, transform: CGAffineTransform, viewport: CGSize
  ) throws -> (JSONValue, Double) {
    func check(_ gradient: SVGElement) throws {
      var chain: [SVGElement] = []
      var ancestor: SVGElement? = gradient
      while let node = ancestor {
        chain.append(node)
        ancestor = node.parent
      }
      var style: [String: String] = [:]
      for node in chain.reversed() { style = try resolved(node, parent: style) }
      try self.check(gradient, style: style)
      guard
        gradient.children.allSatisfy({ ["stop", "title", "desc", "metadata"].contains($0.name) })
      else { throw svgError("Animated gradients are not supported yet.") }
      for stop in gradient.children where stop.name == "stop" {
        guard stop.children.allSatisfy({ ["title", "desc", "metadata"].contains($0.name) }) else {
          throw svgError("Animated gradient stops are not supported yet.")
        }
      }
    }
    try check(node)
    var attributes = node.attributes
    var stops = node.children.filter { $0.name == "stop" }
    var visited: Set<String> = []
    var ancestor = node
    while let href = ancestor.attributes["href"] ?? ancestor.attributes["xlink:href"] {
      guard href.hasPrefix("#"), visited.insert(href).inserted, visited.count <= 32,
        let base = definitions[String(href.dropFirst())],
        ["linearGradient", "radialGradient"].contains(base.name)
      else { throw svgError("Invalid or cyclic gradient reference.") }
      for (key, value) in base.attributes where attributes[key] == nil { attributes[key] = value }
      if stops.isEmpty { stops = base.children.filter { $0.name == "stop" } }
      ancestor = base
      try check(base)
    }
    guard attributes["spreadMethod"] == nil || attributes["spreadMethod"] == "pad" else {
      throw svgError("Repeating/reflected gradients are not supported yet.")
    }
    guard attributes["color-interpolation"] == nil || attributes["color-interpolation"] == "sRGB"
    else { throw svgError("This gradient color interpolation is not supported yet.") }
    var converted: [JSONValue] = []
    var lastOffset = 0.0
    for stop in stops {
      stopCount += 1
      guard stopCount <= 100_000 else {
        throw svgError("Expanded gradient stops exceed the import limit.")
      }
      var chain: [SVGElement] = []
      var parent = stop.parent
      while let p = parent {
        chain.append(p)
        parent = p.parent
      }
      var inherited: [String: String] = [:]
      for p in chain.reversed() { inherited = try resolved(p, parent: inherited) }
      let style = try resolved(stop, parent: inherited)
      try self.check(stop, style: style)
      let color = try SVGColor.parse(
        style["stop-color"]?.lowercased() == "currentcolor"
          ? style["color"] ?? "black" : style["stop-color"] ?? "black")
      let offset = max(lastOffset, try SVGLength.opacity(stop.attributes["offset"] ?? "0"))
      lastOffset = offset
      converted.append(
        .object([
          "offset": .number(offset), "color": color.value,
          "opacity": .number(try color.alpha * SVGLength.opacity(style["stop-opacity"])),
        ]))
    }
    guard let last = converted.last else { return (VectorStyle.none, 1) }
    if converted.count == 1 {
      return (
        .object(["type": .string("solid"), "color": last["color"]]), last["opacity"].double ?? 1
      )
    }
    let bbox =
      attributes["gradientUnits"] == nil || attributes["gradientUnits"] == "objectBoundingBox"
    guard bbox || attributes["gradientUnits"] == "userSpaceOnUse" else {
      throw svgError("Invalid gradientUnits.")
    }
    guard !bbox || bounds.width > 0 && bounds.height > 0 else {
      throw svgError("Object-bounding-box gradients need nonzero path dimensions.")
    }
    let size = bbox ? CGSize(width: 1, height: 1) : viewport
    func coordinate(_ key: String, fallback: String, axis: Double) throws -> Double {
      try SVGLength.value(attributes[key] ?? fallback, relativeTo: axis)
    }
    let radial = node.name == "radialGradient"
    let start: CGPoint
    let end: CGPoint
    if radial {
      let cx = try coordinate("cx", fallback: "50%", axis: size.width)
      let cy = try coordinate("cy", fallback: "50%", axis: size.height)
      let r = try coordinate("r", fallback: "50%", axis: hypot(size.width, size.height) / sqrt(2))
      let fx = try coordinate("fx", fallback: String(cx), axis: size.width)
      let fy = try coordinate("fy", fallback: String(cy), axis: size.height)
      guard r >= 0, abs(fx - cx) < 0.000001, abs(fy - cy) < 0.000001,
        attributes["fr"] == nil || attributes["fr"] == "0"
      else { throw svgError("Focal radial gradients are not supported yet.") }
      if r == 0 {
        return (
          .object(["type": .string("solid"), "color": last["color"]]), last["opacity"].double ?? 1
        )
      }
      start = CGPoint(x: cx, y: cy)
      end = CGPoint(x: cx + r, y: cy)
    } else {
      start = try CGPoint(
        x: coordinate("x1", fallback: "0%", axis: size.width),
        y: coordinate("y1", fallback: "0%", axis: size.height))
      end = try CGPoint(
        x: coordinate("x2", fallback: "100%", axis: size.width),
        y: coordinate("y2", fallback: "0%", axis: size.height))
      if start == end {
        return (
          .object(["type": .string("solid"), "color": last["color"]]), last["opacity"].double ?? 1
        )
      }
    }
    var paint: JSONValue = .object([
      "type": .string("gradient"),
      "gradient": .object([
        "kind": .string(radial ? "Radial" : "Linear"), "stops": .array(converted),
      ]), "geom": .object(["start": start.json(), "end": end.json()]),
    ])
    let boxTransform =
      bbox
      ? CGAffineTransform(scaleX: bounds.width, y: bounds.height).concatenating(
        CGAffineTransform(translationX: bounds.minX, y: bounds.minY)) : .identity
    let placement = try SVGTransform.parse(attributes["gradientTransform"] ?? "").concatenating(
      boxTransform
    ).concatenating(transform)
    paint["geom"] = try GradientGeometry(paint: paint, bounds: bounds).transformed(
      placement, radial: radial
    ).json()
    return (paint, 1)
  }

  func artwork(
    _ path: CGPath, node: SVGElement, style: [String: String], transform: CGAffineTransform,
    viewport: CGSize
  ) throws -> [JSONValue] {
    let bounds = path.boundingBoxOfPath
    let currentColor = style["color"] ?? "black"
    let (fill, fillAlpha) = try paint(
      style["fill"] ?? "black", bounds: bounds, transform: transform, viewport: viewport,
      currentColor: currentColor)
    let (stroke, strokeAlpha) = try paint(
      style["stroke"] ?? "none", bounds: bounds, transform: transform, viewport: viewport,
      currentColor: currentColor)
    let diagonal = hypot(viewport.width, viewport.height) / sqrt(2)
    let width = try SVGLength.value(style["stroke-width"] ?? "1", relativeTo: diagonal)
    guard (0...10000).contains(width) else { throw svgError("Invalid or oversized stroke width.") }
    let caps = ["butt": "Butt", "round": "Round", "square": "Square"]
    let joins = ["miter": "Miter", "round": "Round", "bevel": "Bevel"]
    guard let cap = caps[style["stroke-linecap"] ?? "butt"],
      let join = joins[style["stroke-linejoin"] ?? "miter"]
    else { throw svgError("Unsupported stroke cap/join.") }
    var miterScanner = SVGNumbers(style["stroke-miterlimit"] ?? "4")
    let miter = try miterScanner.list()
    guard miter.count == 1, (1...10000).contains(miter[0]) else {
      throw svgError("Invalid stroke miter limit.")
    }
    let dashSource = style["stroke-dasharray"] ?? "none"
    let dash =
      dashSource == "none"
      ? []
      : try dashSource.split { $0 == "," || $0.isWhitespace }.map {
        try SVGLength.value(String($0), relativeTo: diagonal)
      }
    guard dash.count <= 1000, dash.allSatisfy({ $0 >= 0 }) else {
      throw svgError("Invalid stroke dash pattern.")
    }
    let phase = try SVGLength.value(style["stroke-dashoffset"] ?? "0", relativeTo: diagonal)
    let effect = style["vector-effect"] ?? "none"
    guard ["none", "non-scaling-stroke"].contains(effect) else {
      throw svgError("Unsupported vector effect.")
    }
    let order = style["paint-order"] ?? "normal"
    guard
      [
        "normal", "fill", "stroke", "fill stroke", "stroke fill", "fill stroke markers",
        "stroke fill markers",
      ].contains(order)
    else { throw svgError("Unsupported paint order.") }
    let rule = style["fill-rule"] ?? "nonzero"
    guard ["nonzero", "evenodd"].contains(rule) else { throw svgError("Invalid fill rule.") }
    let sx = hypot(transform.a, transform.b)
    let sy = hypot(transform.c, transform.d)
    let uniform =
      abs(sx - sy) < 0.000001 * max(1, sx)
      && abs(transform.a * transform.c + transform.b * transform.d) < 0.000001 * max(1, sx * sy)
    let scale = effect == "non-scaling-stroke" ? 0.75 : sx
    guard scale.isFinite, stroke["type"].string == "none" || width * scale <= 10000 else {
      throw svgError("Transformed stroke exceeds supported limits.")
    }
    if stroke["type"].string != "none", width > 0, dash.contains(where: { $0 > 0 }) {
      var length = 0.0
      for subpath in try PathGeometry.subpaths(path) {
        var pairs = Array(zip(subpath.anchors, subpath.anchors.dropFirst()))
        if subpath.closed, let first = subpath.anchors.first, let last = subpath.anchors.last {
          pairs.append((last, first))
        }
        for (a, b) in pairs {
          length +=
            a.point.distance(to: a.outgoing) + a.outgoing.distance(to: b.incoming)
            + b.incoming.distance(to: b.point)
        }
      }
      guard length / dash.reduce(0, +) * Double(dash.count) <= 100_000 else {
        throw svgError("The dash pattern would create too many stroke segments.")
      }
    }
    let fillItem: JSONValue = .object([
      "kind": .string("fill"), "paint": fill,
      "opacity": .number(try fillAlpha * SVGLength.opacity(style["fill-opacity"])),
    ])
    var strokeItem: JSONValue = .object([
      "kind": .string("stroke"), "paint": stroke, "width": .number(width * scale),
      "cap": .string(cap), "join": .string(join), "miter_limit": .number(miter[0]),
      "opacity": .number(try strokeAlpha * SVGLength.opacity(style["stroke-opacity"])),
    ])
    strokeItem["dash"] = .object([
      "pattern": .array(dash.map { .number($0 * scale) }), "offset": .number(phase * scale),
    ])
    let name = node.attributes["id"] ?? node.name.capitalized
    let opacity = try SVGLength.opacity(style["opacity"])
    let visible =
      !["hidden", "collapse"].contains(style["visibility"] ?? "") && style["display"] != "none"
    var placement = transform
    guard let placed = path.copy(using: &placement) else {
      throw svgError("Could not transform SVG path.")
    }
    if !uniform, effect == "none", width > 0, stroke["type"].string != "none" {
      let dashed =
        dash.contains(where: { $0 > 0 })
        ? path.copy(dashingWithPhase: phase, lengths: dash.map { CGFloat($0) }) : path
      let outline = dashed.copy(
        strokingWithWidth: width,
        lineCap: cap == "Round" ? .round : cap == "Square" ? .square : .butt,
        lineJoin: join == "Round" ? .round : join == "Bevel" ? .bevel : .miter, miterLimit: miter[0]
      )
      var matrix = transform
      guard let strokePath = outline.copy(using: &matrix) else {
        throw svgError("Could not transform SVG stroke.")
      }
      var outlined = strokeItem
      outlined["kind"] = .string("fill")
      let fillNode = try pathNode(placed, items: [fillItem], rule: rule, name: name)
      let strokeNode = try pathNode(
        strokePath, items: [outlined], rule: "nonzero", name: "Outlined Stroke")
      var group = try group(
        order.hasPrefix("stroke") ? [strokeNode, fillNode] : [fillNode, strokeNode], name: name,
        opacity: opacity)
      group["visible"] = .bool(visible)
      return [group]
    }
    var raw = try pathNode(
      placed, items: order.hasPrefix("stroke") ? [strokeItem, fillItem] : [fillItem, strokeItem],
      rule: rule, name: name)
    raw["opacity"] = .number(opacity)
    raw["visible"] = .bool(visible)
    return [raw]
  }
  func pathNode(_ path: CGPath, items: [JSONValue], rule: String, name: String) throws -> JSONValue
  {
    let paths = try PathGeometry.subpaths(path)
    pointCount += paths.reduce(0) { $0 + $1.anchors.count }
    guard pointCount <= 100_000 else {
      throw svgError("Expanded path anchors exceed the import limit.")
    }
    return .object([
      "id": .integer(try allocate()), "name": .string(name),
      "appearance": .object(["items": .array(items)]),
      "kind": .object([
        "type": .string("path"), "rule": .string(rule == "evenodd" ? "EvenOdd" : "NonZero"),
        "path": .object(["subpaths": .array(paths.map { $0.json(version: 3) })]),
      ]),
    ])
  }
}
