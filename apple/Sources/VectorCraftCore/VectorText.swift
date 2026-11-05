import CoreGraphics
import CoreText
import Foundation

/// Point and rectangular area text are shaped by Core Text and exported as glyph outlines, without bundling fonts.
public enum VectorText {
  public struct Part {
    public var path: CGPath
    public var style: JSONValue
    public var hasBitmapGlyphs: Bool
  }
  private static let runKey = NSAttributedString.Key("VectorCraftRun")

  public static func parts(_ node: VectorNode) -> [Part] {
    let kind = node.raw["kind"]
    let runs = kind["runs"].array
    guard ["point", "area"].contains(kind["kind"]["kind"].string), kind["vertical"].boolean != true
    else {
      return []
    }
    let text = attributedText(node)
    let full = text.string as NSString
    guard full.length <= 100_000 else { return [] }
    let transform = kind["xf"].affine ?? .identity
    var parts: [Part] = []
    for (line, origin) in lines(text, node: node) {
      let shapedRuns = CTLineGetGlyphRuns(line) as? [CTRun] ?? []
      for shaped in shapedRuns {
        let dictionary = CTRunGetAttributes(shaped)
        let attributes = dictionary as NSDictionary
        guard
          let fontPointer = CFDictionaryGetValue(
            dictionary, Unmanaged.passUnretained(kCTFontAttributeName).toOpaque()),
          let index = attributes[runKey.rawValue] as? NSNumber,
          runs.indices.contains(index.intValue)
        else { continue }
        let fontObject = Unmanaged<CFTypeRef>.fromOpaque(fontPointer).takeUnretainedValue()
        guard CFGetTypeID(fontObject) == CTFontGetTypeID() else { continue }
        let font = Unmanaged<CTFont>.fromOpaque(fontPointer).takeUnretainedValue()
        let style = runs[index.intValue]["style"]
        let count = CTRunGetGlyphCount(shaped)
        guard count <= 100_000 else { continue }
        var glyphs = [CGGlyph](repeating: 0, count: count)
        var positions = [CGPoint](repeating: .zero, count: count)
        CTRunGetGlyphs(shaped, CFRange(location: 0, length: 0), &glyphs)
        CTRunGetPositions(shaped, CFRange(location: 0, length: 0), &positions)
        let path = CGMutablePath()
        var bitmapGlyphs = false
        for (glyph, position) in zip(glyphs, positions) {
          if let outline = CTFontCreatePathForGlyph(font, glyph, nil) {
            let placement = CGAffineTransform(
              a: 1, b: 0, c: 0, d: -1, tx: origin.x + position.x,
              ty: origin.y - position.y - (style["baseline_shift"].double ?? 0)
            ).concatenating(transform)
            path.addPath(outline, transform: placement)
          } else {
            var value = glyph
            let bounds = CTFontGetBoundingRectsForGlyphs(font, .default, &value, nil, 1)
            if !bounds.isEmpty && !bounds.isNull { bitmapGlyphs = true }
          }
        }
        parts.append(Part(path: path, style: style, hasBitmapGlyphs: bitmapGlyphs))
      }
    }
    return parts
  }

  private static func attributedText(_ node: VectorNode) -> NSAttributedString {
    let runs = node.raw["kind"]["runs"].array
    let text = NSMutableAttributedString(string: "")
    for (index, run) in runs.enumerated() {
      let style = run["style"]
      let size = style["size"].double ?? 32
      guard size.isFinite, (0.1...10000).contains(size) else { continue }
      var string = run["text"].string
      if style["all_caps"].boolean == true { string = string.uppercased() }
      let font = font(style)
      let tracking = (style["tracking"].double ?? 0) * size / 1000
      let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTKernAttributeName as String): tracking,
        runKey: NSNumber(value: index),
      ]
      text.append(NSAttributedString(string: string, attributes: attributes))
    }
    return text
  }

  public static func isOverset(_ node: VectorNode) -> Bool {
    guard let rect = areaRect(node) else { return false }
    let text = attributedText(node)
    return CTFrameGetVisibleStringRange(areaFrame(text, rect: rect)).length < text.length
  }

  private static func areaFrame(_ text: NSAttributedString, rect: CGRect) -> CTFrame {
    let path = CGPath(
      rect: CGRect(x: rect.minX, y: 0, width: rect.width, height: rect.height), transform: nil)
    return CTFramesetterCreateFrame(
      CTFramesetterCreateWithAttributedString(text), CFRange(location: 0, length: 0), path, nil)
  }

  private static func lines(_ text: NSAttributedString, node: VectorNode) -> [(CTLine, CGPoint)] {
    if let rect = areaRect(node) {
      let frame = areaFrame(text, rect: rect)
      let lines = CTFrameGetLines(frame) as? [CTLine] ?? []
      guard lines.count <= 100_000 else { return [] }
      var origins = [CGPoint](repeating: .zero, count: lines.count)
      if !origins.isEmpty {
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), &origins)
      }
      return zip(lines, origins).map { ($0.0, CGPoint(x: $0.1.x, y: rect.maxY - $0.1.y)) }
    }
    guard node.raw["kind"]["kind"]["kind"].string == "point" else { return [] }
    let full = text.string as NSString
    let runs = node.raw["kind"]["runs"].array
    let size = runs.map { $0["style"]["size"].double ?? 32 }.max() ?? 32
    var result: [(CTLine, CGPoint)] = []
    var offset = 0
    var baseline = 0.0
    while offset < full.length {
      let newline = full.range(
        of: "\n", options: [], range: NSRange(location: offset, length: full.length - offset))
      let end = newline.location == NSNotFound ? full.length : newline.location
      result.append(
        (
          CTLineCreateWithAttributedString(
            text.attributedSubstring(from: NSRange(location: offset, length: end - offset))),
          CGPoint(x: 0, y: baseline)
        ))
      baseline += runs.first?["style"]["leading"].double ?? size * 1.2
      if newline.location == NSNotFound { break }
      offset = end + 1
    }
    return result
  }

  public static func warnings(_ node: VectorNode) -> Set<String> {
    var warnings = Set<String>()
    let kind = node.raw["kind"]
    let runs = kind["runs"].array
    if parts(node).contains(where: { $0.hasBitmapGlyphs }) { warnings.insert("bitmap glyphs") }
    if !["point", "area"].contains(kind["kind"]["kind"].string) || kind["vertical"].boolean == true
      || (kind["kind"]["kind"].string == "area" && areaRect(node) == nil)
    {
      warnings.insert("area, path, or vertical text")
    }
    let area = kind["area"]
    if (area["rows"].int ?? 1) != 1 || (area["columns"].int ?? 1) != 1
      || (area["inset"].double ?? 0) != 0 || (area["firstBaselineMin"].double ?? 0) != 0
      || !["", "Ascent"].contains(area["firstBaseline"].string) || !kind["wrap"].array.isEmpty
    {
      warnings.insert("advanced area text")
    }
    let paragraph = kind["para"]
    if !["", "Left"].contains(paragraph["justify"].string)
      || ["left_indent", "right_indent", "first_line_indent", "space_before", "space_after"]
        .contains(where: { (paragraph[$0].double ?? 0) != 0 })
      || paragraph["hyphenate"].boolean == true || !paragraph["tabs"].array.isEmpty
      || runs.contains(where: { $0["text"].string.contains("\t") })
    {
      warnings.insert("paragraph formatting")
    }
    if !node.raw["appearance"]["items"].array.isEmpty { warnings.insert("text appearance") }
    for run in kind["runs"].array {
      let style = run["style"]
      let requested = style["font_family"].string
      let resolved = CTFontCopyFamilyName(font(style)) as String
      if requested.caseInsensitiveCompare(resolved) != .orderedSame {
        warnings.insert("substituted fonts")
      }
      if (style["h_scale"].double ?? 100) != 100 || (style["v_scale"].double ?? 100) != 100
        || (style["rotation"].double ?? 0) != 0
        || style["underline"].boolean == true || style["strikethrough"].boolean == true
        || !style["features"].array.isEmpty
        || style["kerning"] != .null || style["position"]["kind"].string == "superscript"
        || style["position"]["kind"].string == "subscript"
        || style["small_caps"] != .null || style["overprint_fill"].boolean == true
        || style["overprint_stroke"].boolean == true || style["stroke_dash"] != .null
        || !["", "Butt"].contains(style["stroke_cap"].string)
        || !["", "Miter"].contains(style["stroke_join"].string)
        || (style["stroke_miter_limit"].double ?? 10) != 10
        || ((style["stroke_width"].double ?? 0) > 0
          && !["", "none"].contains(style["stroke"]["type"].string))
      {
        warnings.insert("advanced text styling")
      }
      if !["none", "solid"].contains(style["fill"]["type"].string)
        || !["", "none", "solid"].contains(style["stroke"]["type"].string)
      {
        warnings.insert("complex text paints")
      }
    }
    return warnings
  }

  public static func font(_ style: JSONValue) -> CTFont {
    let family = style["font_family"].string.isEmpty ? "Helvetica" : style["font_family"].string
    let base = CTFontCreateWithName(
      family as CFString, min(10000, max(0.1, style["size"].double ?? 32)), nil)
    var traits: CTFontSymbolicTraits = []
    if style["font_style"].string.localizedCaseInsensitiveContains("bold") {
      traits.insert(.traitBold)
    }
    if style["font_style"].string.localizedCaseInsensitiveContains("italic") {
      traits.insert(.traitItalic)
    }
    return traits.isEmpty
      ? base : CTFontCreateCopyWithSymbolicTraits(base, 0, nil, traits, traits) ?? base
  }
}

extension JSONValue {
  public var affine: CGAffineTransform? {
    let values = array.compactMap(\.double)
    guard array.count == 6, values.count == 6, values.allSatisfy(\.isFinite) else { return nil }
    return CGAffineTransform(
      a: values[0], b: values[1], c: values[2], d: values[3], tx: values[4], ty: values[5])
  }
}

extension CGAffineTransform {
  public var json: JSONValue { .array([a, b, c, d, tx, ty].map { .number($0) }) }
}
