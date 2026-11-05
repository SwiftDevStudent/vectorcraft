import Foundation

struct SVGColor {
  var value: JSONValue
  var alpha: Double = 1
  static func parse(_ input: String) throws -> SVGColor {
    let text = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if text == "transparent" { return SVGColor(value: rgb(0, 0, 0), alpha: 0) }
    if let hex = names[text] { return fromHex(hex, alpha: 1) }
    if text.hasPrefix("#") {
      let chars = Array(text.dropFirst())
      guard [3, 4, 6, 8].contains(chars.count), chars.allSatisfy(\.isHexDigit) else {
        throw svgError("Invalid hex color.")
      }
      let expanded = chars.count < 5 ? chars.flatMap { [$0, $0] } : chars
      guard let packed = UInt32(String(expanded), radix: 16) else {
        throw svgError("Invalid hex color.")
      }
      return expanded.count == 8
        ? fromHex(packed >> 8, alpha: Double(packed & 255) / 255) : fromHex(packed, alpha: 1)
    }
    guard let open = text.firstIndex(of: "("), text.last == ")" else {
      throw svgError("Unsupported color: \(text).")
    }
    let name = String(text[..<open])
    let parts = text[text.index(after: open)..<text.index(before: text.endIndex)].split {
      $0.isWhitespace || $0 == "," || $0 == "/"
    }.map(String.init)
    guard ["rgb", "rgba", "hsl", "hsla"].contains(name), (3...4).contains(parts.count) else {
      throw svgError("Unsupported color function.")
    }
    func channel(_ token: String, maximum: Double) throws -> Double {
      let percent = token.hasSuffix("%")
      var scanner = SVGNumbers(percent ? String(token.dropLast()) : token)
      let n = try scanner.number()
      guard scanner.next == nil else { throw svgError("Invalid color component.") }
      return min(1, max(0, n / (percent ? 100 : maximum)))
    }
    let alpha = parts.count == 4 ? try channel(parts[3], maximum: 1) : 1
    if name.hasPrefix("rgb") {
      return SVGColor(
        value: try rgb(
          channel(parts[0], maximum: 255), channel(parts[1], maximum: 255),
          channel(parts[2], maximum: 255)), alpha: alpha)
    }
    var hue = parts[0]
    var multiplier = 1.0
    for (suffix, scale) in [("turn", 360.0), ("grad", 0.9), ("rad", 180 / Double.pi), ("deg", 1.0)]
    where hue.hasSuffix(suffix) {
      hue = String(hue.dropLast(suffix.count))
      multiplier = scale
      break
    }
    var scanner = SVGNumbers(hue)
    let degrees = try scanner.number() * multiplier
    guard scanner.next == nil, parts[1].hasSuffix("%"), parts[2].hasSuffix("%") else {
      throw svgError("Invalid HSL color.")
    }
    let h =
      (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) / 60
    let s = try channel(parts[1], maximum: 1)
    let l = try channel(parts[2], maximum: 1)
    let c = (1 - abs(2 * l - 1)) * s
    let x = c * (1 - abs(h.truncatingRemainder(dividingBy: 2) - 1))
    let m = l - c / 2
    let values: (Double, Double, Double)
    switch h {
    case ..<1: values = (c, x, 0)
    case ..<2: values = (x, c, 0)
    case ..<3: values = (0, c, x)
    case ..<4: values = (0, x, c)
    case ..<5: values = (x, 0, c)
    default: values = (c, 0, x)
    }
    return SVGColor(value: rgb(values.0 + m, values.1 + m, values.2 + m), alpha: alpha)
  }
  static func rgb(_ r: Double, _ g: Double, _ b: Double) -> JSONValue {
    VectorStyle.solid(r, g, b)["color"]
  }
  private static func fromHex(_ value: UInt32, alpha: Double) -> SVGColor {
    SVGColor(
      value: rgb(
        Double((value >> 16) & 255) / 255, Double((value >> 8) & 255) / 255,
        Double(value & 255) / 255), alpha: alpha)
  }
  // CSS named colors are standardized numeric values, not bundled artwork.
  private static let names: [String: UInt32] = {
    let table = """
      aliceblue F0F8FF antiquewhite FAEBD7 aqua 00FFFF aquamarine 7FFFD4 azure F0FFFF beige F5F5DC bisque FFE4C4 black 000000 blanchedalmond FFEBCD blue 0000FF blueviolet 8A2BE2 brown A52A2A burlywood DEB887
      cadetblue 5F9EA0 chartreuse 7FFF00 chocolate D2691E coral FF7F50 cornflowerblue 6495ED cornsilk FFF8DC crimson DC143C cyan 00FFFF darkblue 00008B darkcyan 008B8B darkgoldenrod B8860B darkgray A9A9A9 darkgrey A9A9A9 darkgreen 006400 darkkhaki BDB76B darkmagenta 8B008B darkolivegreen 556B2F darkorange FF8C00 darkorchid 9932CC darkred 8B0000 darksalmon E9967A darkseagreen 8FBC8F darkslateblue 483D8B darkslategray 2F4F4F darkslategrey 2F4F4F darkturquoise 00CED1 darkviolet 9400D3 deeppink FF1493 deepskyblue 00BFFF dimgray 696969 dimgrey 696969 dodgerblue 1E90FF
      firebrick B22222 floralwhite FFFAF0 forestgreen 228B22 fuchsia FF00FF gainsboro DCDCDC ghostwhite F8F8FF gold FFD700 goldenrod DAA520 gray 808080 grey 808080 green 008000 greenyellow ADFF2F honeydew F0FFF0 hotpink FF69B4 indianred CD5C5C indigo 4B0082 ivory FFFFF0 khaki F0E68C lavender E6E6FA lavenderblush FFF0F5 lawngreen 7CFC00 lemonchiffon FFFACD lightblue ADD8E6 lightcoral F08080 lightcyan E0FFFF lightgoldenrodyellow FAFAD2 lightgray D3D3D3 lightgrey D3D3D3 lightgreen 90EE90 lightpink FFB6C1 lightsalmon FFA07A lightseagreen 20B2AA lightskyblue 87CEFA lightslategray 778899 lightslategrey 778899 lightsteelblue B0C4DE lightyellow FFFFE0 lime 00FF00 limegreen 32CD32 linen FAF0E6
      magenta FF00FF maroon 800000 mediumaquamarine 66CDAA mediumblue 0000CD mediumorchid BA55D3 mediumpurple 9370DB mediumseagreen 3CB371 mediumslateblue 7B68EE mediumspringgreen 00FA9A mediumturquoise 48D1CC mediumvioletred C71585 midnightblue 191970 mintcream F5FFFA mistyrose FFE4E1 moccasin FFE4B5 navajowhite FFDEAD navy 000080 oldlace FDF5E6 olive 808000 olivedrab 6B8E23 orange FFA500 orangered FF4500 orchid DA70D6 palegoldenrod EEE8AA palegreen 98FB98 paleturquoise AFEEEE palevioletred DB7093 papayawhip FFEFD5 peachpuff FFDAB9 peru CD853F pink FFC0CB plum DDA0DD powderblue B0E0E6 purple 800080 rebeccapurple 663399 red FF0000 rosybrown BC8F8F royalblue 4169E1
      saddlebrown 8B4513 salmon FA8072 sandybrown F4A460 seagreen 2E8B57 seashell FFF5EE sienna A0522D silver C0C0C0 skyblue 87CEEB slateblue 6A5ACD slategray 708090 slategrey 708090 snow FFFAFA springgreen 00FF7F steelblue 4682B4 tan D2B48C teal 008080 thistle D8BFD8 tomato FF6347 turquoise 40E0D0 violet EE82EE wheat F5DEB3 white FFFFFF whitesmoke F5F5F5 yellow FFFF00 yellowgreen 9ACD32
      """.split(whereSeparator: \.isWhitespace)
    var result: [String: UInt32] = [:]
    for i in stride(from: 0, to: table.count - 1, by: 2) {
      result[String(table[i])] = UInt32(table[i + 1], radix: 16)
    }
    return result
  }()
}
