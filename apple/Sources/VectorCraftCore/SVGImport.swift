import CoreGraphics
import Foundation

public enum SVGImport {
  public static let maximumBytes = SVGXML.maximumBytes
  public static func recognizes(_ text: String) -> Bool {
    let prefix = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return prefix.hasPrefix("<?xml")
      || prefix.range(
        of: "^<(?:[A-Za-z_][A-Za-z0-9_.-]*:)?svg(?:[\\s>])", options: .regularExpression) != nil
      || prefix.hasPrefix("<!--") && prefix.contains("<svg") || prefix.hasPrefix("<!DOCTYPE svg")
  }
  public static func fragment(_ data: Data) throws -> VectorFragment {
    let drawing = try decode(data)
    return try VectorFragment(
      copying: Set(drawing.layers.flatMap(\.children).map(\.id)), from: drawing)
  }
  public static func decode(_ data: Data, title: String = "Imported SVG") throws -> Drawing {
    let root = try SVGXML.read(data)
    return try SVGImporter(root: root).drawing(title: title)
  }
}

final class SVGImporter {
  let root: SVGElement
  var styles: SVGStyle
  var definitions: [String: SVGElement] = [:]
  var nextID: Int64 = 2
  var work = 0
  var pointCount = 0
  var stopCount = 0
  var depth = 0
  init(root: SVGElement) throws {
    self.root = root
    styles = try SVGStyle(root: root)
    func index(_ node: SVGElement) throws {
      if node.name == "metadata" { return }
      if let id = node.attributes["id"] {
        guard id.utf8.count <= 512 else {
          throw svgError("SVG identifiers exceed the import limit.")
        }
        guard definitions[id] == nil else { throw svgError("Duplicate SVG ID: \(id).") }
        definitions[id] = node
      }
      for child in node.children { try index(child) }
    }
    try index(root)
  }
  func drawing(title: String) throws -> Drawing {
    let viewport = try SVGViewport.make(attributes: root.attributes)
    let size = CGSize(width: viewport.size.width * 0.75, height: viewport.size.height * 0.75)
    let matrix = try viewport.transform.concatenating(
      SVGTransform.parse(root.attributes["transform"] ?? "")
    ).concatenating(CGAffineTransform(scaleX: 0.75, y: 0.75))
    let userSize = try SVGViewport.userSize(root.attributes, fallback: viewport.size)
    let style = try resolved(root, parent: [:])
    try check(root, style: style)
    var nodes: [JSONValue] = []
    for child in root.children {
      nodes += try convert(child, parent: style, matrix: matrix, viewport: userSize, references: [])
    }
    if try SVGLength.opacity(style["opacity"]) != 1 || style["display"] == "none" {
      var container = try group(
        nodes, name: root.attributes["id"] ?? "SVG", opacity: SVGLength.opacity(style["opacity"]))
      container["visible"] = .bool(style["display"] != "none")
      nodes = [container]
    }
    var drawing = Drawing(width: size.width, height: size.height)
    drawing.envelope["document"]["title"] = .string(
      root.children.first(where: { $0.name == "title" })?.text.trimmingCharacters(
        in: .whitespacesAndNewlines
      ).nonempty ?? title)
    drawing.updateNode(1) { $0["kind"]["children"] = .array(nodes) }
    drawing.envelope["document"]["next_id"] = .integer(nextID)
    try drawing.validate()
    // Imported artwork must fit the native writer's size contract before opening a document.
    _ = try NativeFormat.encode(drawing)
    return drawing
  }
  func resolved(_ node: SVGElement, parent: [String: String]) throws -> [String: String] {
    work += max(1, styles.rules.count)
    guard work <= 1_000_000 else {
      throw svgError("SVG style/reference complexity exceeds the import limit.")
    }
    var result = try styles.resolved(node, inheriting: parent)
    let parentSize = Double(parent["font-size"] ?? "16") ?? 16
    result["font-size"] = String(
      try SVGLength.value(
        result["font-size"] ?? String(parentSize), relativeTo: parentSize, font: parentSize))
    return result
  }
  func check(_ node: SVGElement, style: [String: String]) throws {
    guard node.namespace.isEmpty || node.namespace == "http://www.w3.org/2000/svg" else {
      throw svgError("Unsupported visible namespace: \(node.namespace).")
    }
    for key in node.attributes.keys where key.lowercased().hasPrefix("on") {
      throw svgError("SVG event handlers are not supported.")
    }
    if node.attributes["pathLength"] != nil {
      throw svgError("pathLength calibration is not supported yet.")
    }
    if node.attributes["textLength"] != nil || node.attributes["lengthAdjust"] != nil {
      throw svgError("Text length adjustment is not supported yet.")
    }
    if let visibility = style["visibility"],
      !["visible", "hidden", "collapse"].contains(visibility)
    {
      throw svgError("Unsupported visibility value.")
    }
  }
  func convert(
    _ node: SVGElement, parent: [String: String], matrix: CGAffineTransform, viewport: CGSize,
    references: Set<String>
  ) throws -> [JSONValue] {
    depth += 1
    defer { depth -= 1 }
    guard depth <= 32 else {
      throw svgError("Expanded SVG nesting exceeds the native document limit.")
    }
    if [
      "defs", "style", "title", "desc", "metadata", "linearGradient", "radialGradient", "clipPath",
      "symbol",
    ].contains(node.name) {
      return []
    }
    let style = try resolved(node, parent: parent)
    try check(node, style: style)
    let transform = try SVGTransform.parse(node.attributes["transform"] ?? "").concatenating(matrix)
    let name = node.attributes["id"] ?? node.name.capitalized
    let opacity = try SVGLength.opacity(style["opacity"])
    if node.name == "g" || node.name == "a" {
      var children: [JSONValue] = []
      for child in node.children {
        children += try convert(
          child, parent: style, matrix: transform, viewport: viewport, references: references)
      }
      guard !children.isEmpty else { return [] }
      var container = try group(children, name: name, opacity: opacity)
      container["visible"] = .bool(style["display"] != "none")
      return [container]
    }
    if node.name == "use" {
      guard let href = node.attributes["href"] ?? node.attributes["xlink:href"],
        href.hasPrefix("#"), let target = definitions[String(href.dropFirst())]
      else { throw svgError("Only local, existing SVG use references are supported.") }
      guard references.count < 32, !references.contains(href) else {
        throw svgError("Cyclic or deeply nested SVG use reference.")
      }
      guard !["symbol", "svg", "defs"].contains(target.name) else {
        throw svgError("Referenced symbol/viewports are not supported yet.")
      }
      let placement = CGAffineTransform(
        translationX: try length(node, "x", size: viewport.width),
        y: try length(node, "y", size: viewport.height)
      ).concatenating(transform)
      let children = try convert(
        target, parent: style, matrix: placement, viewport: viewport,
        references: references.union([href]))
      guard !children.isEmpty else { return [] }
      var container = try group(children, name: name, opacity: opacity)
      container["visible"] = .bool(style["display"] != "none")
      return [container]
    }
    if node.name == "text" {
      return try text(node, style: style, transform: transform, viewport: viewport)
    }
    let path = try shape(node, viewport: viewport)
    guard !path.isEmpty else { return [] }
    return try artwork(path, node: node, style: style, transform: transform, viewport: viewport)
  }
  func allocate() throws -> Int64 {
    guard nextID < 100_002 else { throw svgError("Expanded artwork exceeds the object limit.") }
    defer { nextID += 1 }
    return nextID
  }
  func group(_ children: [JSONValue], name: String, opacity: Double = 1) throws -> JSONValue {
    .object([
      "id": .integer(try allocate()), "name": .string(name), "opacity": .number(opacity),
      "kind": .object(["type": .string("group"), "children": .array(children)]),
    ])
  }
  func length(
    _ node: SVGElement, _ key: String, size: Double, fallback: String = "0", font: Double = 16
  ) throws -> Double {
    try SVGLength.value(node.attributes[key] ?? fallback, relativeTo: size, font: font)
  }
}

extension String {
  fileprivate var nonempty: String? { isEmpty ? nil : self }
}
