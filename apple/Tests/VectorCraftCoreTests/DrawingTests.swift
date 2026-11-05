import CoreGraphics
import Foundation
import ImageIO
import Testing

@testable import VectorCraftCore

struct DrawingTests {
  @Test func alignmentUsesTheArtboardOrSelectionAndKeepsFailuresAtomic() throws {
    var drawing = Drawing(width: 400, height: 300)
    let a = try drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 20, y: 30, width: 60, height: 40))], VectorStyle(), layer: 1
      ))
    let b = try drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 200, y: 150, width: 20, height: 80))], VectorStyle(),
        layer: 1))
    let aID = try #require(a.first)
    let bID = try #require(b.first)
    try drawing.perform(.align(a, .right, artboard: 0))
    #expect(drawing.node(aID)?.bounds.minX == 340)
    #expect(drawing.node(bID)?.bounds.minX == 200)
    try drawing.perform(.align(a.union(b), .top, artboard: 0))
    #expect(drawing.node(aID)?.bounds.minY == 30 && drawing.node(bID)?.bounds.minY == 30)
    let group = try drawing.perform(.group(a.union(b)))
    let id = try #require(group.first)
    try drawing.perform(.align(group, .bottom, artboard: 0))
    #expect(drawing.node(id)?.bounds.maxY == 300)
    #expect(drawing.node(aID)?.bounds.minY == 220 && drawing.node(bID)?.bounds.minY == 220)
    let before = drawing
    #expect(throws: DrawingError.self) { try drawing.perform(.align(group, .left, artboard: 99)) }
    #expect(drawing == before)
  }
  @Test func deletingAnchorsChangesOnlyThePathAndRejectsStaleIndices() throws {
    var drawing = Drawing()
    let ids = try drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 10, y: 20, width: 100, height: 80))], VectorStyle(),
        layer: 1))
    let id = try #require(ids.first)
    try drawing.perform(.deleteAnchor(id, subpath: 0, anchor: 1))
    #expect(drawing.node(id)?.subpaths.first?.anchors.count == 3)
    let before = drawing
    #expect(throws: DrawingError.self) {
      try drawing.perform(.deleteAnchor(id, subpath: 0, anchor: 99))
    }
    #expect(drawing == before)
    try drawing.perform(.deleteAnchor(id, subpath: 0, anchor: 0))
    #expect(drawing.node(id)?.subpaths.first?.anchors.count == 2)
    try drawing.perform(.deleteAnchor(id, subpath: 0, anchor: 0))
    #expect(drawing.node(id) == nil)
    #expect(drawing.layers.count == 1)
  }

  @Test func editingDoesNotFlattenUnsupportedRichText() throws {
    var drawing = Drawing()
    let ids = try drawing.perform(
      .addText(
        "First", CGPoint(x: 10, y: 30), font: "Helvetica", size: 20,
        fill: VectorStyle.solid(0, 0, 0), layer: 1))
    let id = try #require(ids.first)
    drawing.updateNode(id) { value in
      var runs = value["kind"]["runs"].array
      var second = runs[0]
      second["text"] = .string("Second")
      second["style"]["size"] = .number(30)
      runs.append(second)
      value["kind"]["runs"] = .array(runs)
    }
    let before = drawing
    #expect(throws: DrawingError.self) {
      try drawing.perform(.editText(id, "Changed", font: "Helvetica", size: 24))
    }
    #expect(drawing == before)
    #expect(
      try NativeFormat.decode(NativeFormat.encode(drawing)).envelope["document"]
        == before.envelope["document"])
  }
  @Test func closedCurvesWithTwoAnchorsRemainEditable() throws {
    var drawing = Drawing()
    let path = VectorSubpath(
      anchors: [
        VectorAnchor(
          CGPoint(x: 10, y: 50), incoming: CGPoint(x: 40, y: 80), outgoing: CGPoint(x: 40, y: 20)),
        VectorAnchor(
          CGPoint(x: 100, y: 50), incoming: CGPoint(x: 70, y: 20), outgoing: CGPoint(x: 70, y: 80)),
      ], closed: true)
    let ids = try drawing.perform(.addPath([path], VectorStyle(), layer: 1))
    let id = try #require(ids.first)
    var changed = path
    changed.anchors[0].point.x = 5
    try drawing.perform(.replacePath(id, [changed]))
    #expect(drawing.node(id)?.subpaths.first?.anchors.count == 2)
    #expect(drawing.node(id)?.subpaths.first?.closed == true)
  }
  @Test func drawingAndTransformRetainUnknownData() throws {
    var drawing = Drawing()
    drawing.envelope["document"]["unknown"] = .object(["foreignPlugin": .string("retain me")])
    drawing.envelope["images"]["unused-but-preserved"] = .object([
      "mime": .string("image/png"), "data": .string("data"),
    ])
    let ids = try drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 10, y: 20, width: 100, height: 80))], VectorStyle(),
        layer: 1))
    let id = try #require(ids.first)
    try drawing.perform(.transform(ids, .init(translationX: 30, y: 40)))
    #expect(drawing.node(id)?.bounds == CGRect(x: 40, y: 60, width: 100, height: 80))
    let reopened = try NativeFormat.decode(NativeFormat.encode(drawing))
    #expect(reopened.envelope["document"]["unknown"] == drawing.envelope["document"]["unknown"])
    #expect(reopened.envelope["images"] == drawing.envelope["images"])
    #expect(reopened.node(id)?.bounds == drawing.node(id)?.bounds)
  }

  @Test func failureLeavesDocumentIntactAndLocksAreInherited() throws {
    var drawing = Drawing()
    let ids = try drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 0, y: 0, width: 100, height: 100))], VectorStyle(), layer: 1
      ))
    try drawing.perform(.lock(1, true))
    let before = drawing
    #expect(throws: DrawingError.self) {
      try drawing.perform(.transform(ids, .init(translationX: 4, y: 0)))
    }
    #expect(drawing == before)
    #expect(drawing.hitTest(CGPoint(x: 50, y: 50), tolerance: 2) == nil)
  }

  @Test func groupingDuplicationAndDeletionPreserveOrderingAndUniqueIDs() throws {
    var drawing = Drawing()
    let a = try drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 0, y: 0, width: 100, height: 100))], VectorStyle(), layer: 1
      ))
    let b = try drawing.perform(
      .addPath(
        [ShapePaths.ellipse(CGRect(x: 20, y: 20, width: 50, height: 50))], VectorStyle(), layer: 1))
    let groupIDs = try drawing.perform(.group(a.union(b)))
    let group = try #require(groupIDs.first)
    #expect(drawing.node(group)?.children.count == 2)
    let copies = try drawing.perform(.duplicate(groupIDs))
    #expect(copies.count == 1)
    #expect(drawing.layers.first?.children.count == 2)
    try drawing.validate()
    try drawing.perform(.delete(groupIDs))
    #expect(drawing.node(group) == nil)
    let copyID = try #require(copies.first)
    let children = try drawing.perform(.ungroup(copyID))
    #expect(children.count == 2)
    #expect(drawing.layers.first?.children.count == 2)
  }

  @Test func movingAnAnchorRetainsCubicHandles() throws {
    var drawing = Drawing()
    let path = ShapePaths.ellipse(CGRect(x: 0, y: 0, width: 100, height: 60))
    let ids = try drawing.perform(.addPath([path], VectorStyle(), layer: 1))
    let id = try #require(ids.first)
    try drawing.perform(.transform(ids, .init(translationX: 15, y: 20)))
    let transformed = try #require(drawing.node(id)?.subpaths.first)
    #expect(
      transformed.anchors.first?.point
        == path.anchors.first?.point.applying(.init(translationX: 15, y: 20)))
    #expect(
      transformed.anchors.first?.outgoing
        == path.anchors.first?.outgoing.applying(.init(translationX: 15, y: 20)))
    #expect(transformed.closed)
  }

  @Test func realUpstreamDocumentsRoundTripWithoutLosingTheirTrees() throws {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    for name in ["dusk-poster", "neon-drive", "ribbons", "feature-sheet"] {
      let drawing = try NativeFormat.decode(
        Data(contentsOf: root.appending(path: "examples/\(name).vectorcraft")))
      let reopened = try NativeFormat.decode(NativeFormat.encode(drawing))
      #expect(reopened.envelope["document"] == drawing.envelope["document"])
      #expect(reopened.envelope["images"] == drawing.envelope["images"])
      #expect(!drawing.layers.isEmpty)
    }
  }

  @Test func legacyVersionOneWritesMapAnchors() throws {
    var drawing = Drawing()
    drawing.envelope["format"] = .string("drawcraft")
    drawing.envelope["version"] = .integer(1)
    let ids = try drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 0, y: 0, width: 30, height: 40))], VectorStyle(), layer: 1))
    let id = try #require(ids.first)
    #expect(
      drawing.node(id)?.raw["kind"]["path"]["subpaths"].array.first?["anchors"].array.first?["p"][
        "x"
      ].double == 0)
    #expect(try NativeFormat.decode(NativeFormat.encode(drawing)).version == 1)
  }

  @Test func rejectsFutureVersionsDeepNestingAndInvalidGeometry() throws {
    var drawing = Drawing()
    drawing.envelope["version"] = .integer(5)
    #expect(throws: DrawingError.self) {
      try NativeFormat.decode(JSONEncoder().encode(drawing.envelope))
    }
    let deep = Data(
      (String(repeating: "[", count: 130) + "0" + String(repeating: "]", count: 130)).utf8)
    #expect(throws: DrawingError.self) { try NativeFormat.decode(deep) }
    var valid = Drawing()
    let before = valid
    #expect(throws: DrawingError.self) {
      try valid.perform(.resizeArtboard(0, CGSize(width: Double.infinity, height: 0)))
    }
    #expect(valid == before)
  }

  @Test func exportProducesReadablePNGVectorSVGAndPDF() throws {
    var drawing = Drawing(width: 100, height: 100)
    try drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 10, y: 10, width: 80, height: 80))],
        VectorStyle(fill: VectorStyle.solid(1, 0, 0), stroke: VectorStyle.none), layer: 1))
    let png = try VectorRenderer.png(drawing)
    let source = try #require(CGImageSourceCreateWithData(png as CFData, nil))
    let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
    #expect(image.width == 100 && image.height == 100)
    let svg = String(decoding: try SVGExport.encode(drawing), as: UTF8.self)
    #expect(svg.contains("<path") && svg.contains("rgb(255,0,0)"))
    let pdf = try PDFExport.encode(drawing)
    let provider = try #require(CGDataProvider(data: pdf as CFData))
    let document = try #require(CGPDFDocument(provider))
    #expect(document.numberOfPages == 1)
  }

  @Test func unsupportedFeaturesBlockLossyExportsButAllowNativeSave() throws {
    var drawing = Drawing()
    drawing.updateNode(1) { $0["mask"] = .object(["unhandled": .bool(true)]) }
    #expect(drawing.renderingWarnings == ["opacity masks"])
    #expect(throws: DrawingError.self) { try SVGExport.encode(drawing) }
    #expect(throws: DrawingError.self) { try VectorRenderer.png(drawing) }
    let reopened = try NativeFormat.decode(NativeFormat.encode(drawing))
    #expect(reopened.envelope["document"] == drawing.envelope["document"])
  }
}
