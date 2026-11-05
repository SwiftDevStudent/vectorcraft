import CoreGraphics
import Foundation
import Testing

@testable import VectorCraftCore

struct PathOperationsTests {
  @Test(arguments: PathfinderOperation.allCases)
  func rectangleOperationsHaveTheExpectedRegionsAndPaint(_ operation: PathfinderOperation) throws {
    var drawing = Drawing()
    let back = try add(
      &drawing, CGRect(x: 0, y: 0, width: 100, height: 100), color: VectorStyle.solid(1, 0, 0))
    let front = try add(
      &drawing, CGRect(x: 50, y: 50, width: 100, height: 100), color: VectorStyle.solid(0, 0, 1))
    drawing.updateNode(front) { $0["unknown"]["foreign"] = .string("keep front") }
    drawing.updateNode(back) { $0["unknown"]["foreign"] = .string("keep back") }
    let unrelated = try add(
      &drawing, CGRect(x: 400, y: 400, width: 10, height: 10), color: VectorStyle.solid(0, 1, 0))
    drawing.updateNode(1) {
      var children = $0["kind"]["children"].array
      children.swapAt(1, 2)
      $0["kind"]["children"] = .array(children)
    }
    let ids = try drawing.perform(.pathfinder([back, front], operation))
    #expect(ids.count == 1)
    #expect(drawing.node(back) == nil && drawing.node(front) == nil)
    #expect(drawing.node(unrelated)?.bounds == CGRect(x: 400, y: 400, width: 10, height: 10))
    let output = try #require(ids.first.flatMap(drawing.node))
    #expect(drawing.layers.first?.children.map(\.id) == [unrelated, output.id])
    let expected: [Bool]
    switch operation {
    case .unite, .divide, .trim, .merge: expected = [true, true, true]
    case .minusFront: expected = [true, false, false]
    case .minusBack: expected = [false, false, true]
    case .intersect, .crop: expected = [false, true, false]
    case .exclude: expected = [true, false, true]
    }
    let points = [CGPoint(x: 10, y: 10), CGPoint(x: 75, y: 75), CGPoint(x: 140, y: 140)]
    for (index, point) in points.enumerated() {
      let hit = drawing.hitTest(point, tolerance: 0.01).flatMap(drawing.node)
      #expect((hit != nil) == expected[index])
      if let hit {
        let red =
          operation == .minusFront || operation == .crop
          || (index == 0 && [.divide, .trim, .merge].contains(operation))
        #expect(
          VectorStyle(node: hit).fill
            == (red ? VectorStyle.solid(1, 0, 0) : VectorStyle.solid(0, 0, 1)))
        #expect(hit.raw["unknown"]["foreign"].string == (red ? "keep back" : "keep front"))
      }
    }
    if operation == .divide { #expect(output.type == "group" && output.children.count == 3) }
    if [.trim, .merge, .crop].contains(operation) {
      #expect(
        output.children.allSatisfy {
          $0.raw["appearance"]["items"].array.allSatisfy { $0["kind"].string != "stroke" }
        })
    }
    let reopened = try NativeFormat.decode(NativeFormat.encode(drawing))
    #expect(reopened.envelope["document"] == drawing.envelope["document"])
    #expect(drawing.renderingWarnings.isEmpty)
    _ = try SVGExport.encode(reopened)
    _ = try PDFExport.encode(reopened)
  }

  @Test func mergeCombinesMatchingPaintAndCurvesKeepEditableHandles() throws {
    var drawing = Drawing()
    let one = try drawing.perform(
      .addPath(
        [ShapePaths.ellipse(CGRect(x: 20, y: 20, width: 100, height: 100))], VectorStyle(), layer: 1
      ))
    let two = try drawing.perform(
      .addPath(
        [ShapePaths.ellipse(CGRect(x: 70, y: 20, width: 100, height: 100))], VectorStyle(), layer: 1
      ))
    let ids = try drawing.perform(.pathfinder(one.union(two), .merge))
    let group = try #require(ids.first.flatMap(drawing.node))
    #expect(group.children.count == 1)
    let path = try #require(group.children.first)
    #expect(path.subpaths.allSatisfy { $0.closed })
    #expect(
      path.subpaths.flatMap(\.anchors).contains {
        $0.incoming != $0.point || $0.outgoing != $0.point
      })
    #expect(path.cgPath.contains(CGPoint(x: 40, y: 70)))
    #expect(path.cgPath.contains(CGPoint(x: 150, y: 70)))
    #expect(!path.cgPath.contains(CGPoint(x: 25, y: 25)))
  }

  @Test func compoundRulesEditAndReleasePreserveStyleAndForeignData() throws {
    var drawing = Drawing()
    let back = try add(
      &drawing, CGRect(x: 20, y: 20, width: 200, height: 200), color: VectorStyle.solid(1, 0, 0))
    let front = try add(
      &drawing, CGRect(x: 70, y: 70, width: 100, height: 100), color: VectorStyle.solid(0, 0, 1))
    drawing.updateNode(front) { $0["unknown"]["note"] = .string("inner") }
    let selected = try drawing.perform(.makeCompound([back, front]))
    let id = try #require(selected.first)
    #expect(drawing.node(id)?.type == "compound")
    let compound = try #require(drawing.node(id))
    #expect(VectorStyle(node: compound).fill == VectorStyle.solid(1, 0, 0))
    #expect(drawing.hitTest(CGPoint(x: 100, y: 100), tolerance: 0.01) == id)
    try drawing.perform(.fillRule([id], .evenOdd))
    #expect(drawing.hitTest(CGPoint(x: 100, y: 100), tolerance: 0.01) == nil)
    let svg = String(decoding: try SVGExport.encode(drawing), as: UTF8.self)
    #expect(svg.contains("evenodd"))
    var paths = try #require(drawing.node(id)).subpaths
    paths[1].anchors[0] = VectorAnchor(CGPoint(x: 80, y: 90))
    try drawing.perform(.replacePath(id, paths))
    #expect(drawing.node(front)?.subpaths.first?.anchors.first?.point == CGPoint(x: 80, y: 90))
    #expect(drawing.node(front)?.raw["unknown"]["note"].string == "inner")
    try drawing.perform(.deleteAnchor(id, subpath: 1, anchor: 0))
    #expect(drawing.node(front)?.subpaths.first?.anchors.count == 3)
    let released = try drawing.perform(.releaseCompound([id]))
    #expect(released.count == 2 && drawing.node(id) == nil)
    #expect(
      released.compactMap(drawing.node).allSatisfy {
        $0.type == "path" && VectorStyle(node: $0).fill == VectorStyle.solid(1, 0, 0)
      })
    #expect(
      released.compactMap(drawing.node).contains { $0.raw["unknown"]["note"].string == "inner" })
    let reopened = try NativeFormat.decode(NativeFormat.encode(drawing))
    #expect(reopened.envelope["document"] == drawing.envelope["document"])
  }

  @Test func mixedFillRulesAndEmptyOrLockedOperationsAreAtomic() throws {
    var drawing = Drawing()
    let outer = try add(
      &drawing, CGRect(x: 0, y: 0, width: 200, height: 200), color: VectorStyle.solid(1, 0, 0))
    let inner = try add(
      &drawing, CGRect(x: 50, y: 50, width: 100, height: 100), color: VectorStyle.solid(1, 0, 0))
    let ring = try #require(try drawing.perform(.makeCompound([outer, inner])).first)
    try drawing.perform(.fillRule([ring], .evenOdd))
    let island = try add(
      &drawing, CGRect(x: 80, y: 80, width: 40, height: 40), color: VectorStyle.solid(0, 0, 1))
    try drawing.perform(.pathfinder([ring, island], .unite))
    #expect(drawing.hitTest(CGPoint(x: 10, y: 10), tolerance: 0.01) != nil)
    #expect(drawing.hitTest(CGPoint(x: 60, y: 60), tolerance: 0.01) == nil)
    #expect(drawing.hitTest(CGPoint(x: 100, y: 100), tolerance: 0.01) != nil)
    let far = try add(
      &drawing, CGRect(x: 400, y: 400, width: 50, height: 50), color: VectorStyle.solid(0, 1, 0))
    let other = try add(
      &drawing, CGRect(x: 500, y: 500, width: 50, height: 50), color: VectorStyle.solid(0, 1, 0))
    let before = drawing
    #expect(throws: DrawingError.self) {
      try drawing.perform(.pathfinder([far, other], .intersect))
    }
    #expect(drawing == before)
    try drawing.perform(.lock(far, true))
    let locked = drawing
    #expect(throws: DrawingError.self) { try drawing.perform(.pathfinder([far, other], .unite)) }
    #expect(drawing == locked)
  }

  private func add(_ drawing: inout Drawing, _ bounds: CGRect, color: JSONValue) throws -> Int64 {
    try #require(
      try drawing.perform(
        .addPath(
          [ShapePaths.rectangle(bounds)], VectorStyle(fill: color, stroke: VectorStyle.none),
          layer: 1)
      ).first)
  }

  @Test func deletingNestedFinalContourRemovesEmptyContainers() throws {
    var drawing = Drawing()
    let path = try add(
      &drawing, CGRect(x: 10, y: 10, width: 20, height: 20), color: VectorStyle.solid(1, 0, 0))
    let nested = try #require(try drawing.perform(.makeCompound([path])).first)
    let other = try add(
      &drawing, CGRect(x: 100, y: 100, width: 20, height: 20), color: VectorStyle.solid(0, 0, 1))
    let root = try #require(try drawing.perform(.makeCompound([nested, other])).first)
    for _ in 0..<3 { try drawing.perform(.deleteAnchor(root, subpath: 0, anchor: 0)) }
    #expect(drawing.node(nested) == nil)
    #expect(drawing.node(path) == nil)
    #expect(drawing.node(root)?.children.map(\.id) == [other])
  }

  @Test func legacyGeometryUsesItsOriginalCoordinateFormat() throws {
    var drawing = Drawing()
    drawing.envelope["version"] = .integer(1)
    drawing.envelope["format"] = .string("drawcraft")
    let a = try add(
      &drawing, CGRect(x: 20, y: 20, width: 80, height: 80), color: VectorStyle.solid(1, 0, 0))
    let b = try add(
      &drawing, CGRect(x: 60, y: 60, width: 80, height: 80), color: VectorStyle.solid(0, 0, 1))
    let ids = try drawing.perform(.pathfinder([a, b], .unite))
    let node = try #require(ids.first.flatMap(drawing.node))
    let anchor = try #require(
      node.raw["kind"]["path"]["subpaths"].array.first?["anchors"].array.first)
    #expect(anchor["p"]["x"].double != nil && anchor["p"].array.isEmpty)
    let reopened = try NativeFormat.decode(NativeFormat.encode(drawing))
    #expect(reopened.version == 1 && reopened.envelope["format"].string == "drawcraft")
    #expect(reopened.envelope["document"] == drawing.envelope["document"])
  }

  @Test func unsupportedCompoundContentIsProtected() throws {
    var drawing = Drawing()
    let a = try add(
      &drawing, CGRect(x: 20, y: 20, width: 80, height: 80), color: VectorStyle.solid(1, 0, 0))
    let b = try add(
      &drawing, CGRect(x: 60, y: 60, width: 80, height: 80), color: VectorStyle.solid(0, 0, 1))
    let compound = try #require(try drawing.perform(.makeCompound([a])).first)
    drawing.updateNode(a) { $0["kind"]["type"] = .string("image") }
    let original = drawing
    #expect(!drawing.canUsePathfinder([compound, b]))
    #expect(throws: DrawingError.self) { try drawing.perform(.pathfinder([compound, b], .unite)) }
    #expect(drawing == original)
    #expect(drawing.renderingWarnings.contains("non-path compound content"))
    #expect(throws: DrawingError.self) { try SVGExport.encode(drawing) }
  }
}
