import Foundation

struct SVGStyle {
  static let inherited: Set<String> = [
    "color", "fill", "fill-opacity", "fill-rule", "stroke", "stroke-width", "stroke-opacity",
    "stroke-linecap", "stroke-linejoin", "stroke-miterlimit", "stroke-dasharray",
    "stroke-dashoffset", "visibility", "font-family", "font-size", "font-weight", "font-style",
    "text-anchor", "letter-spacing", "xml:space",
  ]
  static let unchangedDefaults: [String: Set<String>] = [
    "filter": ["none"], "mask": ["none"], "clip-path": ["none"], "clip": ["auto"],
    "marker-start": ["none"], "marker-mid": ["none"], "marker-end": ["none"],
    "mix-blend-mode": ["normal"], "isolation": ["auto", "isolate"],
    "font-variant": ["normal"], "font-stretch": ["normal"], "font-kerning": ["auto"],
    "font-feature-settings": ["normal"], "font-variation-settings": ["normal"],
    "dominant-baseline": ["auto"], "alignment-baseline": ["auto", "baseline"],
    "baseline-shift": ["baseline", "0", "0px"], "text-decoration": ["none"],
    "word-spacing": ["normal", "0", "0px"], "writing-mode": ["horizontal-tb", "lr", "lr-tb"],
    "direction": ["ltr"], "unicode-bidi": ["normal"], "color-interpolation": ["srgb"],
    "shape-rendering": ["auto"], "text-rendering": ["auto"], "kerning": ["auto"],
  ]
  static let supported = inherited.union([
    "opacity", "display", "stop-color", "stop-opacity", "vector-effect", "paint-order",
  ]).union(unchangedDefaults.keys)
  struct Rule {
    var selector: [String]
    var specificity: Int
    var declarations: [(String, String, Bool)]
  }
  var rules: [Rule] = []
  init(root: SVGElement) throws {
    func walk(_ node: SVGElement) throws {
      if node.name == "style" {
        if let type = node.attributes["type"], type != "text/css" {
          throw svgError("Unsupported stylesheet type.")
        }
        try add(node.text)
      }
      if node.name != "metadata" { for child in node.children { try walk(child) } }
    }
    try walk(root)
  }
  private mutating func add(_ source: String) throws {
    var css = source
    while let start = css.range(of: "/*") {
      guard let end = css.range(of: "*/", range: start.upperBound..<css.endIndex) else {
        throw svgError("Unclosed CSS comment.")
      }
      css.removeSubrange(start.lowerBound..<end.upperBound)
    }
    guard !css.contains("@"), !css.contains("\\") else {
      throw svgError("CSS imports, at-rules and escaped selectors are not supported yet.")
    }
    while !css.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      guard let open = css.firstIndex(of: "{"), let close = css[open...].firstIndex(of: "}") else {
        throw svgError("Invalid SVG stylesheet.")
      }
      let declarations = try Self.declarations(String(css[css.index(after: open)..<close]))
      for raw in css[..<open].split(separator: ",", omittingEmptySubsequences: false) {
        let parts = raw.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !parts.isEmpty, parts.count <= 16 else {
          throw svgError("Empty or overly complex CSS selector.")
        }
        var specificity = 0
        for part in parts {
          let tokens = try Self.tokens(part)
          guard tokens.count <= 16 else {
            throw svgError("CSS selector exceeds supported complexity.")
          }
          specificity += tokens.reduce(0) {
            $0 + ($1.first == "#" ? 100 : $1.first == "." ? 10 : $1 == "*" ? 0 : 1)
          }
        }
        rules.append(Rule(selector: parts, specificity: specificity, declarations: declarations))
      }
      css = String(css[css.index(after: close)...])
      guard rules.count <= 10_000 else { throw svgError("Too many CSS rules.") }
    }
  }
  static func declarations(_ source: String) throws -> [(String, String, Bool)] {
    try source.split(separator: ";").map { declaration in
      guard let colon = declaration.firstIndex(of: ":") else {
        throw svgError("Invalid CSS declaration.")
      }
      let key = declaration[..<colon].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      var value = declaration[declaration.index(after: colon)...].trimmingCharacters(
        in: .whitespacesAndNewlines)
      let important = value.lowercased().hasSuffix("!important")
      if important {
        value = String(value.dropLast(10)).trimmingCharacters(in: .whitespacesAndNewlines)
      }
      guard !key.isEmpty, !value.isEmpty else { throw svgError("Empty CSS declaration.") }
      return (key, value, important)
    }
  }
  private static func tokens(_ selector: String) throws -> [String] {
    var tokens: [String] = []
    var token = ""
    for c in selector {
      if c == "." || c == "#" {
        if !token.isEmpty { tokens.append(token) }
        token = String(c)
      } else if c.isASCII && (c.isLetter || c.isNumber || c == "-" || c == "_" || c == "*") {
        token.append(c)
      } else {
        throw svgError("Unsupported CSS selector: \(selector).")
      }
    }
    if !token.isEmpty { tokens.append(token) }
    guard tokens.allSatisfy({ $0 != "." && $0 != "#" }) else {
      throw svgError("Invalid CSS selector.")
    }
    return tokens
  }
  private static func matches(_ selector: String, _ node: SVGElement) -> Bool {
    guard let tokens = try? tokens(selector) else { return false }
    return tokens.allSatisfy { token in
      if token.first == "#" { return node.attributes["id"] == String(token.dropFirst()) }
      if token.first == "." {
        return (node.attributes["class"] ?? "").split(whereSeparator: \.isWhitespace).contains(
          Substring(token.dropFirst()))
      }
      return token == "*" || token == node.name
    }
  }
  func resolved(_ node: SVGElement, inheriting parent: [String: String]) throws -> [String: String]
  {
    var result = parent.filter { Self.inherited.contains($0.key) }
    var ranks: [String: (Bool, Int, Int)] = [:]
    func assign(_ key: String, _ value: String, important: Bool, specificity: Int, order: Int) {
      if let rank = ranks[key],
        rank.0 && !important
          || rank.0 == important
            && (rank.1 > specificity || rank.1 == specificity && rank.2 > order)
      {
        return
      }
      result[key] = value
      ranks[key] = (important, specificity, order)
    }
    for (key, value) in node.attributes where Self.supported.contains(key) {
      assign(key, value, important: false, specificity: 0, order: -1)
    }
    for (index, rule) in rules.enumerated() {
      guard let last = rule.selector.last, Self.matches(last, node) else { continue }
      var ancestor = node.parent
      var matched = true
      for part in rule.selector.dropLast().reversed() {
        while let candidate = ancestor, !Self.matches(part, candidate) {
          ancestor = candidate.parent
        }
        if ancestor == nil {
          matched = false
          break
        }
        ancestor = ancestor?.parent
      }
      if matched {
        for (key, value, important) in rule.declarations {
          assign(key, value, important: important, specificity: rule.specificity, order: index)
        }
      }
    }
    for (key, value, important) in try Self.declarations(node.attributes["style"] ?? "") {
      assign(key, value, important: important, specificity: 1000, order: rules.count)
    }
    for (key, value) in result {
      let keyword = value.lowercased()
      if keyword == "inherit" || keyword == "unset" && Self.inherited.contains(key) {
        result[key] = parent[key]
      } else if keyword == "initial" || keyword == "unset" {
        result[key] = nil
      } else if !Self.supported.contains(key) {
        throw svgError("Unsupported style property: \(key).")
      } else if Self.unchangedDefaults[key] != nil
        || [
          "display", "visibility", "fill-rule", "stroke-linecap", "stroke-linejoin",
          "vector-effect", "paint-order", "font-weight", "font-style", "text-anchor",
        ].contains(key)
      {
        result[key] = keyword
      }
    }
    if result["color"]?.lowercased() == "currentcolor" {
      result["color"] = parent["color"] ?? "black"
    }
    for (key, defaults) in Self.unchangedDefaults {
      if let value = result[key], !defaults.contains(value) {
        throw svgError("\(key): \(value) is not supported yet; the source SVG is unchanged.")
      }
    }
    return result
  }
}
