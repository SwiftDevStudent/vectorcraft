import CoreGraphics
import CoreText
import Foundation

extension SVGImporter {
  func text(
    _ node: SVGElement, style: [String: String], transform: CGAffineTransform, viewport: CGSize
  ) throws -> [JSONValue] {
    guard node.children.allSatisfy({ ["title", "desc"].contains($0.name) }) else {
      throw svgError("Positioned/styled text spans and text paths are not supported yet.")
    }
    let content =
      style["xml:space"] == "preserve"
      ? node.text.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(
        of: "\t", with: " ")
      : node.text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    guard !content.isEmpty else { return [] }
    guard content.utf16.count <= 100_000, let size = Double(style["font-size"] ?? "16"),
      (0.1...10000).contains(size)
    else { throw svgError("Text exceeds the supported size or length limits.") }
    guard style["stroke"] == nil || style["stroke"] == "none" else {
      throw svgError("Importing stroked editable text is not supported yet.")
    }
    let (fill, alpha) = try paint(
      style["fill"] ?? "black", bounds: .zero, transform: transform, viewport: viewport,
      currentColor: style["color"] ?? "black")
    guard ["solid", "none"].contains(fill["type"].string) else {
      throw svgError("Gradient-filled editable text is not supported yet.")
    }
    let weight = style["font-weight"] ?? "normal"
    let slant = style["font-style"] ?? "normal"
    guard ["normal", "bold", "400", "700"].contains(weight),
      ["normal", "italic", "oblique"].contains(slant)
    else { throw svgError("This text weight/style is not supported yet.") }
    let family =
      (style["font-family"] ?? "sans-serif").split(separator: ",").first.map(String.init)?
      .trimmingCharacters(
        in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"'")))
      ?? "Helvetica"
    guard family.utf8.count <= 256 else {
      throw svgError("Font family name exceeds the import limit.")
    }
    let generic = [
      "sans-serif": "Helvetica", "serif": "Times", "monospace": "Courier",
      "cursive": "Apple Chancery", "fantasy": "Papyrus",
    ]
    let spacing =
      style["letter-spacing"] == nil || style["letter-spacing"] == "normal"
      ? 0 : try SVGLength.value(style["letter-spacing"] ?? "0", relativeTo: size, font: size)
    let traits =
      (["bold", "700"].contains(weight) ? "Bold" : "") + (slant == "normal" ? "" : " Italic")
    let textStyle: JSONValue = .object([
      "font_family": .string(generic[family] ?? family), "font_style": .string(traits),
      "size": .number(size), "fill": fill, "tracking": .number(spacing * 1000 / size),
    ])
    let anchor = style["text-anchor"] ?? "start"
    guard ["start", "middle", "end"].contains(anchor) else {
      throw svgError("Invalid text anchor.")
    }
    let attributed = NSAttributedString(
      string: content,
      attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): VectorText.font(textStyle),
        NSAttributedString.Key(kCTKernAttributeName as String): spacing,
      ])
    let advance = CTLineGetTypographicBounds(
      CTLineCreateWithAttributedString(attributed), nil, nil, nil)
    let shift = anchor == "middle" ? advance / 2 : anchor == "end" ? advance : 0
    let x =
      try length(node, "x", size: viewport.width, font: size)
      + length(node, "dx", size: viewport.width, font: size)
    let y =
      try length(node, "y", size: viewport.height, font: size)
      + length(node, "dy", size: viewport.height, font: size)
    var scanner = SVGNumbers(node.attributes["rotate"] ?? "0")
    let angles = try scanner.list()
    guard angles.count == 1 else {
      throw svgError("Per-character text rotations are not supported yet.")
    }
    let matrix = CGAffineTransform(translationX: -shift, y: 0).concatenating(
      CGAffineTransform(rotationAngle: angles[0] * .pi / 180)
    ).concatenating(CGAffineTransform(translationX: x, y: y)).concatenating(transform)
    return [
      .object([
        "id": .integer(try allocate()),
        "name": .string(node.attributes["id"] ?? String(content.prefix(40))),
        "opacity": .number(
          try SVGLength.opacity(style["opacity"]) * SVGLength.opacity(style["fill-opacity"]) * alpha
        ),
        "visible": .bool(
          style["display"] != "none" && !["hidden", "collapse"].contains(style["visibility"] ?? "")),
        "kind": .object([
          "type": .string("text"), "kind": .object(["kind": .string("point")]), "xf": matrix.json,
          "runs": .array([.object(["text": .string(content), "style": textStyle])]),
        ]),
      ])
    ]
  }
}
