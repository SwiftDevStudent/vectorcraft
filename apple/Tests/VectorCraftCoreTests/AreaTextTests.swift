import CoreGraphics
import Foundation
import Testing

@testable import VectorCraftCore

struct AreaTextTests {
  @Test func areaTextWrapsInsideItsFrameAndSurvivesSaveAndEdit() throws {
    var drawing = Drawing()
    let frame = CGRect(x: 50, y: 60, width: 140, height: 220)
    let ids = try drawing.perform(
      .addAreaText(
        "One two three four five six seven eight nine ten", frame,
        font: "Helvetica", size: 24, fill: VectorStyle.solid(0, 0, 0), layer: 1))
    let id = try #require(ids.first)
    let node = try #require(drawing.node(id))
    let ink = VectorText.parts(node).reduce(CGRect.null) { $0.union($1.path.boundingBoxOfPath) }
    #expect(ink.height > 60 && ink.width <= frame.width && ink.minY >= frame.minY)
    #expect(node.bounds == frame)
    #expect(drawing.renderingWarnings.isEmpty)
    try drawing.perform(.editText(id, "Changed\nSecond line", font: "Helvetica", size: 24))
    let reopened = try NativeFormat.decode(NativeFormat.encode(drawing))
    #expect(reopened.node(id)?.bounds == frame)
    #expect(
      reopened.node(id)?.raw["kind"]["runs"].array.first?["text"].string == "Changed\nSecond line")
    #expect(!VectorText.parts(try #require(reopened.node(id))).isEmpty)
    _ = try SVGExport.encode(reopened)
    _ = try PDFExport.encode(reopened)
  }

  @Test func invalidAreaIsAtomicAndAdvancedFrameOptionsStayProtected() throws {
    var drawing = Drawing()
    let before = drawing
    #expect(throws: DrawingError.self) {
      try drawing.perform(
        .addAreaText(
          "Text", CGRect(x: 0, y: 0, width: 0, height: 100),
          font: "Helvetica", size: 24, fill: VectorStyle.solid(0, 0, 0), layer: 1))
    }
    #expect(drawing == before)
    let ids = try drawing.perform(
      .addAreaText(
        "Text", CGRect(x: 10, y: 20, width: 200, height: 100),
        font: "Helvetica", size: 24, fill: VectorStyle.solid(0, 0, 0), layer: 1))
    let id = try #require(ids.first)
    drawing.updateNode(id) { $0["kind"]["area"]["columns"] = .integer(2) }
    #expect(drawing.renderingWarnings.contains("advanced area text"))
    #expect(throws: DrawingError.self) {
      try drawing.perform(.editText(id, "Flattened", font: "Helvetica", size: 24))
    }
    #expect(drawing.node(id)?.raw["kind"]["area"]["columns"].int == 2)
    var malformed = try #require(drawing.node(id))
    var path = try #require(malformed.raw["kind"]["kind"]["frame"]["subpaths"].array.first)
    var anchors = path["anchors"].array
    anchors.swapAt(1, 2)
    path["anchors"] = .array(anchors)
    malformed.raw["kind"]["kind"]["frame"]["subpaths"] = .array([path])
    #expect(VectorText.areaRect(malformed) == nil)
  }

  @Test func resizingAnOversetFrameReflowsWithoutScalingType() throws {
    var drawing = Drawing()
    let ids = try drawing.perform(
      .addAreaText(
        "One two three four five six seven eight nine ten eleven twelve",
        CGRect(x: 20, y: 30, width: 100, height: 40), font: "Helvetica", size: 24,
        fill: VectorStyle.solid(0, 0, 0), layer: 1))
    let id = try #require(ids.first)
    #expect(VectorText.isOverset(try #require(drawing.node(id))))
    try drawing.perform(.resizeTextFrame(id, CGRect(x: 20, y: 30, width: 400, height: 200)))
    let node = try #require(drawing.node(id))
    #expect(!VectorText.isOverset(node))
    #expect(node.raw["kind"]["runs"].array.first?["style"]["size"].double == 24)
    #expect(node.raw["kind"]["xf"].affine == CGAffineTransform(translationX: 20, y: 30))
    #expect(node.bounds == CGRect(x: 20, y: 30, width: 400, height: 200))
  }
}
