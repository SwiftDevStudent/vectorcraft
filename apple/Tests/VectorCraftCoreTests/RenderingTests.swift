import CoreGraphics
import Foundation
import ImageIO
import Testing

@testable import VectorCraftCore

struct RenderingTests {
  @Test func unsupportedTextLayoutIsDisclosedAndPreserved() throws {
    var drawing = Drawing()
    let ids = try drawing.perform(
      .addText(
        "Styled text", CGPoint(x: 30, y: 60), font: "Helvetica", size: 32,
        fill: VectorStyle.solid(0, 0, 0), layer: 1))
    let id = try #require(ids.first)
    drawing.updateNode(id) { raw in
      raw["kind"]["para"]["justify"] = .string("Center")
      var run = raw["kind"]["runs"].array[0]
      run["style"]["small_caps"] = .number(80)
      raw["kind"]["runs"] = .array([run])
    }
    #expect(drawing.renderingWarnings.contains("paragraph formatting"))
    #expect(drawing.renderingWarnings.contains("advanced text styling"))
    #expect(throws: DrawingError.self) { try SVGExport.encode(drawing) }
    let reopened = try NativeFormat.decode(NativeFormat.encode(drawing))
    #expect(reopened.node(id)?.raw == drawing.node(id)?.raw)
  }
  @Test func bitmapTextGlyphsRequireAVisiblePreviewWarning() throws {
    var drawing = Drawing()
    try drawing.perform(
      .addText(
        "😀", CGPoint(x: 30, y: 60), font: "Helvetica", size: 32, fill: VectorStyle.solid(0, 0, 0),
        layer: 1))
    #expect(drawing.renderingWarnings.contains("bitmap glyphs"))
    #expect(throws: DrawingError.self) { try SVGExport.encode(drawing) }
  }
  @Test func placedGradientFollowsMovedArtwork() throws {
    var drawing = Drawing(width: 240, height: 100)
    let red: JSONValue = .object([
      "model": .string("rgb"), "r": .number(1), "g": .number(0), "b": .number(0),
    ])
    let blue: JSONValue = .object([
      "model": .string("rgb"), "r": .number(0), "g": .number(0), "b": .number(1),
    ])
    let paint: JSONValue = .object([
      "type": .string("gradient"),
      "gradient": .object([
        "kind": .string("Linear"),
        "stops": .array([
          .object(["offset": .number(0), "color": red]),
          .object(["offset": .number(1), "color": blue]),
        ]),
      ]),
      "geom": .object([
        "start": CGPoint(x: 10, y: 0).json(version: 1),
        "end": CGPoint(x: 90, y: 0).json(version: 1),
      ]),
    ])
    let ids = try drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 10, y: 10, width: 80, height: 80))],
        VectorStyle(fill: paint, stroke: VectorStyle.none), layer: 1))
    let before = try pixel(decodePNG(VectorRenderer.png(drawing)), x: 30, y: 50)
    try drawing.perform(.transform(ids, .init(translationX: 120, y: 0)))
    let after = try pixel(decodePNG(VectorRenderer.png(drawing)), x: 150, y: 50)
    #expect(abs(Int(before.r) - Int(after.r)) < 3 && abs(Int(before.b) - Int(after.b)) < 3)
  }
  @Test func gzipDocumentsDecodeAndDamagedStreamsFail() throws {
    let encoded =
      "H4sIAAAAAAAC/3WQMY/CMAyF/0qV+Yb2bmM7sTKgWxGqQmIgoomRa06tqvx3bB+HWJhqf6/v2c7ijkjZs1s17hcCIwXyR3Yf2tKYsIjyJV3EcMtQ9MflRepE4sQDaMAa85VgHCE24Qzhoim3knhUcYupSCUo4IDUZ4xm+jkdFBaYuE9RyKd0nviAnqI6d4szrqOKz2b6fuhNp16SxW2vqZVPK2T+L6ZOna2xR1nrXrrBz3LEm/iNin/Zl1SiZfN8Nc2MzzNM2srRoBu0Vfk5DZFAX2e3l2HKUvYn0GlLrXe9UeUWcwEAAA=="
    let data = try #require(Data(base64Encoded: encoded))
    #expect(try NativeFormat.decode(data).title == "Compressed check")
    #expect(throws: DrawingError.self) { try NativeFormat.decode(Data(data.dropLast(8))) }
  }

  @Test func strokePaintsOverFillAndObjectOpacityCompositesOnce() throws {
    var drawing = Drawing(width: 100, height: 100)
    let style = VectorStyle(
      fill: VectorStyle.solid(0, 0, 1), stroke: VectorStyle.solid(1, 0, 0), width: 10)
    let ids = try drawing.perform(
      .addPath([ShapePaths.rectangle(CGRect(x: 10, y: 10, width: 80, height: 80))], style, layer: 1)
    )
    let image = try decodePNG(VectorRenderer.png(drawing))
    let edge = try pixel(image, x: 12, y: 50)
    let center = try pixel(image, x: 50, y: 50)
    #expect(edge.r > 240 && edge.b < 10)
    #expect(center.r < 10 && center.b > 240)
    var translucent = style
    translucent.opacity = 0.5
    try drawing.perform(.style(ids, translucent))
    let blended = try pixel(decodePNG(VectorRenderer.png(drawing)), x: 50, y: 50)
    #expect(
      (120...135).contains(blended.r) && (120...135).contains(blended.g) && blended.b > 240,
      "Pixel: \(blended)")
  }

  @Test func pointTextShapesEditsTransformsAndExportsAsVectors() throws {
    var drawing = Drawing(width: 600, height: 400)
    let ids = try drawing.perform(
      .addText(
        "Swift VectorCraft", CGPoint(x: 70, y: 120), font: "Helvetica", size: 32,
        fill: VectorStyle.solid(0, 0, 0), layer: 1))
    let id = try #require(ids.first)
    let before = try #require(drawing.node(id)?.bounds)
    #expect(before.width > 150 && before.height > 15)
    #expect(drawing.renderingWarnings.isEmpty)
    try drawing.perform(.transform(ids, .init(translationX: 10, y: 20)))
    let bounds = try #require(drawing.node(id)?.bounds)
    #expect(abs(bounds.minX - before.minX - 10) < 0.001)
    #expect(abs(bounds.minY - before.minY - 20) < 0.001)
    try drawing.perform(.editText(id, "Native Mac", font: "Helvetica", size: 40))
    let decoded = try NativeFormat.decode(NativeFormat.encode(drawing))
    #expect(decoded.node(id)?.raw["kind"]["runs"].array.first?["text"].string == "Native Mac")
    let svg = String(decoding: try SVGExport.encode(decoded), as: UTF8.self)
    #expect(svg.contains("<path") && (svg.contains("C ") || svg.contains("Q ")))
    _ = try VectorRenderer.png(decoded)
    _ = try PDFExport.encode(decoded)
  }

  @Test func groupStylesPaintTheirChildrenWithoutAddingUnsupportedContainerAppearance() throws {
    var drawing = Drawing()
    let a = try drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 10, y: 10, width: 80, height: 80))], VectorStyle(), layer: 1
      ))
    let b = try drawing.perform(
      .addPath(
        [ShapePaths.ellipse(CGRect(x: 120, y: 10, width: 80, height: 80))], VectorStyle(), layer: 1)
    )
    let ids = try drawing.perform(.group(a.union(b)))
    let style = VectorStyle(fill: VectorStyle.solid(1, 0, 0), stroke: VectorStyle.none)
    try drawing.perform(.style(ids, style))
    let id = try #require(ids.first)
    let group = try #require(drawing.node(id))
    #expect(group.raw["appearance"]["items"].array.isEmpty)
    #expect(group.children.allSatisfy { VectorStyle(node: $0).fill == style.fill })
    #expect(drawing.renderingWarnings.isEmpty)
  }

  @Test func interoperableDocumentAndExportsPersistToDisk() throws {
    var drawing = Drawing(width: 600, height: 400)
    try drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 40, y: 40, width: 180, height: 130))],
        VectorStyle(fill: VectorStyle.solid(0.2, 0.35, 0.95)), layer: 1))
    try drawing.perform(
      .addPath(
        [ShapePaths.ellipse(CGRect(x: 260, y: 60, width: 150, height: 150))],
        VectorStyle(fill: VectorStyle.solid(1, 0.5, 0.1)), layer: 1))
    try drawing.perform(
      .addText(
        "Native Swift", CGPoint(x: 50, y: 300), font: "Helvetica", size: 40,
        fill: VectorStyle.solid(0.1, 0.1, 0.15), layer: 1))
    drawing.envelope["document"]["title"] = .string("Swift Verification")
    let path = ProcessInfo.processInfo.environment["VECTORCRAFT_TEST_ARTIFACTS"]
    let folder =
      path.map { URL(fileURLWithPath: $0) }
      ?? FileManager.default.temporaryDirectory.appending(path: "VectorCraft-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let file = folder.appending(path: "swift-verification.vectorcraft")
    try NativeFormat.encode(drawing).write(to: file, options: .atomic)
    let reopened = try NativeFormat.decode(Data(contentsOf: file))
    #expect(reopened.envelope["document"] == drawing.envelope["document"])
    try VectorRenderer.png(reopened).write(to: folder.appending(path: "swift-verification.png"))
    try SVGExport.encode(reopened).write(to: folder.appending(path: "swift-verification.svg"))
    try PDFExport.encode(reopened).write(to: folder.appending(path: "swift-verification.pdf"))
  }

  private func decodePNG(_ data: Data) throws -> CGImage {
    let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
    return try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
  }
  private func pixel(_ image: CGImage, x: Int, y: Int) throws -> (r: UInt8, g: UInt8, b: UInt8) {
    var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
    try bytes.withUnsafeMutableBytes { buffer in
      let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
      let context = try #require(
        CGContext(
          data: buffer.baseAddress, width: image.width, height: image.height, bitsPerComponent: 8,
          bytesPerRow: image.width * 4, space: space,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
      context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    }
    let offset = (y * image.width + x) * 4
    return (bytes[offset], bytes[offset + 1], bytes[offset + 2])
  }
}
