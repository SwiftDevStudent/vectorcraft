import CoreGraphics
import Foundation
import Testing

@testable import VectorCraftCore

struct SVGImportTests {
  @Test func pathGrammarKeepsSubpathsControlsAndCompactArcFlags() throws {
    let smooth = try PathGeometry.subpaths(SVGPath.parse("M0 0C0 10 10 10 10 0S20-10 20 0"))
    #expect(smooth[0].anchors[1].outgoing == CGPoint(x: 10, y: -10))
    #expect(smooth[0].anchors[2].incoming == CGPoint(x: 20, y: -10))
    let quadratic = try PathGeometry.subpaths(SVGPath.parse("m1e1 2e1q6 6 12 0t12 0"))
    #expect(quadratic[0].anchors.last?.point == CGPoint(x: 34, y: 20))
    #expect(quadratic[0].anchors[1].outgoing == CGPoint(x: 26, y: 16))
    let closed = try PathGeometry.subpaths(SVGPath.parse("M0 0h10v10h-10z m20 0 10 0"))
    #expect(closed.count == 2 && closed[0].closed && !closed[1].closed)
    #expect(closed[1].anchors.first?.point == CGPoint(x: 20, y: 0))
    let arc = try SVGPath.parse("M0 50A50 50 0 01100 50")
    #expect(abs(arc.boundingBoxOfPath.minY) < 0.00001)
    #expect(abs(arc.boundingBoxOfPath.width - 100) < 0.00001)
    #expect(arc.currentPoint == CGPoint(x: 100, y: 50))
    let fallback = try SVGPath.parse("M1 2a0 10 0 0 1 5 6")
    #expect(fallback.currentPoint == CGPoint(x: 6, y: 8))
  }

  @Test func transformOrderAndViewBoxAlignmentHaveAnalyticBounds() throws {
    let transform = try SVGTransform.parse("translate(30 40) scale(2)")
    #expect(CGPoint(x: 1, y: 2).applying(transform) == CGPoint(x: 32, y: 44))
    let drawing = try decode(
      "<g transform='translate(30 40) scale(2)'><rect id='box' x='1' y='2' width='10' height='6'/></g>",
      box: "10 20 200 100", width: "200pt", height: "100pt")
    #expect(near(try named("box", drawing).bounds, CGRect(x: 22, y: 24, width: 20, height: 12)))
    let meet = try decode(
      "<rect width='100' height='100'/>", box: "0 0 100 100", width: "200pt", height: "100pt")
    #expect(near(meet.layers[0].children[0].bounds, CGRect(x: 50, y: 0, width: 100, height: 100)))
    let none = try SVGImport.decode(
      Data(
        "<svg width='200pt' height='100pt' viewBox='0 0 100 100' preserveAspectRatio='none'><rect width='100' height='100'/></svg>"
          .utf8))
    #expect(near(none.layers[0].children[0].bounds, CGRect(x: 0, y: 0, width: 200, height: 100)))
  }

  @Test func extremeFiniteArcInputsNeverProduceNonfiniteGeometry() throws {
    for (endpoint, large) in [("1e-150", "0"), ("1e-150", "1"), ("1e-310", "0"), ("1e-310", "1")] {
      let path = try SVGPath.parse("M0 0A100000 100000 0 \(large) 1 \(endpoint) 0")
      #expect(path.currentPoint == CGPoint(x: Double(endpoint) ?? 0, y: 0))
      let paths = try PathGeometry.subpaths(path)
      #expect(
        paths.flatMap(\.anchors).allSatisfy { anchor in
          [anchor.point, anchor.incoming, anchor.outgoing].allSatisfy {
            $0.x.isFinite && $0.y.isFinite
          }
        })
      if large == "1" { #expect(path.boundingBoxOfPath.width > 199_999) }
    }
    #expect(throws: DrawingError.self) { try SVGPath.parse("M0 0A1e-310 1 0 0 1 100 100") }
  }

  @Test func physicalUnitsAndExporterRoundTripPreserveDocumentSize() throws {
    let physical = try SVGImport.decode(
      Data("<svg width='1in' height='25.4mm'><rect width='96' height='96'/></svg>".utf8))
    #expect(abs(physical.artboard.width - 72) < 0.000001)
    #expect(abs(physical.artboard.height - 72) < 0.000001)
    #expect(physical.layers[0].children[0].bounds.width == 72)
    var source = Drawing(width: 612, height: 792)
    try source.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 20, y: 30, width: 40, height: 50))],
        VectorStyle(fill: VectorStyle.solid(1, 0, 0), stroke: VectorStyle.none), layer: 1))
    let reopened = try SVGImport.decode(SVGExport.encode(source))
    #expect(near(reopened.artboard, source.artboard))
    #expect(near(reopened.layers[0].bounds, source.layers[0].bounds))
  }

  @Test func cssCascadeCurrentColorAndHiddenArtworkSurviveNativeRoundTrip() throws {
    let drawing = try decode(
      """
      <style>rect{fill:yellow}.box{fill:blue}g .box{stroke:currentColor;stroke-width:2}#important{fill:green!important}</style>
      <g id='container' color='rebeccapurple' fill='red' opacity='.5'>
      <rect id='box' class='box' width='20' height='20' style='fill:#f00'/>
      <rect id='important' x='30' width='20' height='20' style='fill:red'/>
      <rect id='hidden' x='60' width='20' height='20' visibility='hidden'/>
      </g>
      """)
    let group = try named("container", drawing)
    #expect(group.opacity == 0.5 && group.children.count == 3)
    #expect(
      try named("box", drawing).raw["appearance"]["items"].array.first?["paint"]
        == VectorStyle.solid(1, 0, 0))
    #expect(
      try named("important", drawing).raw["appearance"]["items"].array.first?["paint"]
        == VectorStyle.solid(0, 128.0 / 255, 0))
    #expect(try named("hidden", drawing).visible == false)
    let reopened = try NativeFormat.decode(NativeFormat.encode(drawing))
    #expect(reopened.layers == drawing.layers)
  }

  @Test func solidAlphaAndGradientStopsRenderWithObjectOpacity() throws {
    let drawing = try decode(
      """
      <defs><linearGradient id='base'><stop offset='0' stop-color='hsl(0 100% 50%)'/><stop offset='100%' stop-color='blue'/></linearGradient><linearGradient id='linked' href='#base'/></defs>
      <rect id='gradient' width='100' height='40' fill='url(#linked)'/>
      <g opacity='.5'><rect x='0' y='50' width='100' height='40' fill='#ff000080' fill-opacity='.5'/></g>
      """)
    let left = try pixel(drawing, x: 2, y: 20)
    let right = try pixel(drawing, x: 97, y: 20)
    #expect(left.0 > 240 && left.2 < 15 && right.2 > 240 && right.0 < 15)
    let alpha = try pixel(drawing, x: 50, y: 70)
    #expect(alpha.0 > 250 && (220...225).contains(alpha.1) && alpha.1 == alpha.2)
    #expect(drawing.renderingWarnings.isEmpty)
  }

  @Test func nonuniformStrokesBecomeEditableOutlinesWithCorrectThickness() throws {
    let drawing = try decode(
      "<path id='line' d='M10 20H40' transform='scale(2 1)' fill='none' stroke='blue' stroke-width='10'/>"
    )
    let group = try named("line", drawing)
    #expect(group.type == "group" && group.children.count == 2)
    #expect(near(group.children[1].bounds, CGRect(x: 20, y: 15, width: 60, height: 10)))
    #expect(try pixel(drawing, x: 30, y: 16).2 > 250)
    #expect(try pixel(drawing, x: 30, y: 14).0 > 250)
  }

  @Test func localUseReferencesAndSimpleTextRemainEditable() throws {
    let drawing = try decode(
      """
      <defs><path id='source' d='M0 0h10v10z'/></defs>
      <use id='copy' href='#source' x='20' y='30' fill='coral'/>
      <text id='caption' x='50' y='70' font-family='Helvetica' font-size='16' text-anchor='middle'> Hello &amp; SVG </text>
      """)
    #expect(near(try named("copy", drawing).bounds, CGRect(x: 20, y: 30, width: 10, height: 10)))
    let text = try named("caption", drawing)
    #expect(text.type == "text")
    #expect(text.raw["kind"]["runs"].array.first?["text"].string == "Hello & SVG")
    #expect(abs(text.bounds.midX - 50) < 2 && text.bounds.maxY <= 71)
    #expect(try NativeFormat.decode(NativeFormat.encode(drawing)).layers == drawing.layers)
  }

  @Test func unsupportedInputEntitiesAndMalformedGeometryAreRejected() throws {
    for body in [
      "<image href='https://example.com/private.png'/>", "<script>ignored()</script>",
      "<rect width='10' height='10' filter='url(#f)'/>", "<text><tspan>Styled</tspan></text>",
      "<use id='cycle' href='#cycle'/>", "<style>rect:hover{fill:red}</style><rect/>",
    ] {
      #expect(throws: DrawingError.self) { try decode(body) }
    }
    for path in ["M0", "L0 0", "M0 0A1 1 0 2 0 2 2", "M0 0L1e400 0", "M0 0R1 1", "M0 0L1,,2"] {
      #expect(throws: DrawingError.self) { try SVGPath.parse(path) }
    }
    let entity =
      "<!DOCTYPE svg [<!ENTITY external SYSTEM 'file:///private/etc/passwd'>]><svg><text>&external;</text></svg>"
    for encoding in [String.Encoding.utf8, .utf16, .utf16BigEndian, .utf32, .utf32LittleEndian] {
      #expect(throws: DrawingError.self) {
        try SVGImport.decode(try #require(entity.data(using: encoding)))
      }
    }
    #expect(throws: DrawingError.self) {
      try SVGImport.decode(Data(repeating: 32, count: SVGImport.maximumBytes + 1))
    }
    let nested =
      "<svg>" + String(repeating: "<g>", count: 65) + String(repeating: "</g>", count: 65)
      + "</svg>"
    #expect(throws: DrawingError.self) { try SVGImport.decode(Data(nested.utf8)) }
  }

  @Test func hiddenComplexityAndAdvancedTextCannotSilentlyChangeAppearance() throws {
    #expect(throws: DrawingError.self) {
      try decode(
        "<style>#linked{color-interpolation:linearRGB}</style><defs><linearGradient id='base'><stop stop-color='red'/><stop offset='1' stop-color='blue'/></linearGradient><linearGradient id='linked' href='#base'/></defs><rect width='10' height='10' fill='url(#linked)'/>"
      )
    }
    #expect(throws: DrawingError.self) {
      try decode(
        "<style>linearGradient{color-interpolation:linearRGB}</style><defs><linearGradient id='g'><stop stop-color='red'/><stop offset='1' stop-color='blue'/></linearGradient></defs><rect width='10' height='10' fill='url(#g)'/>"
      )
    }
    for body in [
      "<text font-variant='small-caps'>Type</text>", "<text textLength='80'>Type</text>",
      "<path d='M0 0h10v10z'><animate attributeName='d' values='M0 0h10;M0 0h20'/></path>",
      "<rect width='10' height='10' style='mix-blend-mode:multiply'/>",
    ] { #expect(throws: DrawingError.self) { try decode(body) } }
    #expect(throws: DrawingError.self) {
      try decode("<path d='M0 0H100' stroke='red' stroke-dasharray='.00000001 .00000001'/>")
    }
    let nested =
      String(repeating: "<g>", count: 33) + "<rect width='1' height='1'/>"
      + String(repeating: "</g>", count: 33)
    #expect(throws: DrawingError.self) { try decode(nested) }
    let valid = try decode(
      String(repeating: "<g>", count: 30) + "<rect width='1' height='1'/>"
        + String(repeating: "</g>", count: 30))
    #expect(try NativeFormat.decode(NativeFormat.encode(valid)).layers == valid.layers)
  }

  private func near(_ a: CGRect, _ b: CGRect) -> Bool {
    abs(a.minX - b.minX) < 0.000001 && abs(a.minY - b.minY) < 0.000001
      && abs(a.width - b.width) < 0.000001 && abs(a.height - b.height) < 0.000001
  }

  private func decode(
    _ body: String, box: String = "0 0 100 100", width: String = "100pt", height: String = "100pt"
  ) throws -> Drawing {
    try SVGImport.decode(
      Data(
        "<svg xmlns='http://www.w3.org/2000/svg' width='\(width)' height='\(height)' viewBox='\(box)'>\(body)</svg>"
          .utf8))
  }
  private func named(_ name: String, _ drawing: Drawing) throws -> VectorNode {
    func find(_ nodes: [VectorNode]) -> VectorNode? {
      for node in nodes {
        if node.name == name { return node }
        if let found = find(node.children) { return found }
      }
      return nil
    }
    return try #require(find(drawing.layers))
  }
  private func pixel(_ drawing: Drawing, x: Int, y: Int) throws -> (Int, Int, Int) {
    let context = try #require(
      CGContext(
        data: nil, width: 100, height: 100, bitsPerComponent: 8, bytesPerRow: 400,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
    context.translateBy(x: 0, y: 100)
    context.scaleBy(x: 1, y: -1)
    VectorRenderer.render(drawing, in: context)
    let bytes = try #require(context.data).assumingMemoryBound(to: UInt8.self)
    let offset = y * 400 + x * 4
    return (Int(bytes[offset]), Int(bytes[offset + 1]), Int(bytes[offset + 2]))
  }
}
