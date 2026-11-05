import CoreGraphics
import Testing

@testable import VectorCraftCore

struct TransformGeometryTests {
  @Test func constrainedSnapsStayOnTheirLineAndShowOnlyActualAlignments() {
    let moving = CGRect(x: 53, y: 67, width: 100, height: 80)
    let horizontal = Snapping.position(
      CGPoint(x: 40, y: 7), moving: moving, targets: [], grid: true, guides: false,
      tolerance: 6, constraint: .nearest(to: CGPoint(x: 40, y: 7)))
    #expect(horizontal.point == CGPoint(x: 37, y: 0))
    let vertical = Snapping.position(
      CGPoint(x: 5, y: 40), moving: moving, targets: [], grid: true, guides: false,
      tolerance: 6, constraint: .vertical)
    #expect(vertical.point == CGPoint(x: 0, y: 43))
    let diagonal = Snapping.position(
      CGPoint(x: 40, y: 35), moving: moving, targets: [], grid: true, guides: false,
      tolerance: 6, constraint: .diagonalDown)
    #expect(diagonal.point == CGPoint(x: 37, y: 37))
    let guided = Snapping.position(
      CGPoint(x: 50, y: 50), moving: moving,
      targets: [CGRect(x: 202, y: 199, width: 20, height: 20)], grid: false, guides: true,
      tolerance: 6, constraint: .diagonalDown)
    #expect(guided.point == CGPoint(x: 49, y: 49))
    #expect(guided.guides.count == 1)
    #expect(guided.guides.first?.axis == .vertical)
    #expect(guided.guides.first?.value == 202)
    let free = Snapping.position(
      CGPoint(x: -40, y: 35), moving: moving, targets: [], grid: false, guides: false,
      tolerance: 6, constraint: .nearest(to: CGPoint(x: -40, y: 35)))
    #expect(free.point == CGPoint(x: -37.5, y: 37.5))
  }

  @Test func allEightHandlesResizeOnlyTheirAxesAndHonorCenterAndProportions() {
    let bounds = CGRect(x: 0, y: 0, width: 100, height: 50)
    let cases: [(ResizeHandle, CGPoint, CGRect)] = [
      (.topLeft, CGPoint(x: -20, y: -10), CGRect(x: -20, y: -10, width: 120, height: 60)),
      (.top, CGPoint(x: 80, y: -10), CGRect(x: 0, y: -10, width: 100, height: 60)),
      (.topRight, CGPoint(x: 120, y: -10), CGRect(x: 0, y: -10, width: 120, height: 60)),
      (.right, CGPoint(x: 120, y: 99), CGRect(x: 0, y: 0, width: 120, height: 50)),
      (.bottomRight, CGPoint(x: 120, y: 60), CGRect(x: 0, y: 0, width: 120, height: 60)),
      (.bottom, CGPoint(x: 80, y: 60), CGRect(x: 0, y: 0, width: 100, height: 60)),
      (.bottomLeft, CGPoint(x: -20, y: 60), CGRect(x: -20, y: 0, width: 120, height: 60)),
      (.left, CGPoint(x: -20, y: 99), CGRect(x: -20, y: 0, width: 120, height: 50)),
    ]
    for (handle, point, expected) in cases {
      let transform = TransformGeometry.resize(
        bounds, handle: handle, to: point, proportional: false, fromCenter: false)
      expectRect(bounds.applying(transform), expected)
    }
    let centered = TransformGeometry.resize(
      bounds, handle: .bottomRight, to: CGPoint(x: 120, y: 60),
      proportional: false, fromCenter: true)
    expectRect(bounds.applying(centered), CGRect(x: -20, y: -10, width: 140, height: 70))
    let proportional = TransformGeometry.resize(
      bounds, handle: .right, to: CGPoint(x: 80, y: 25),
      proportional: true, fromCenter: false)
    expectRect(bounds.applying(proportional), CGRect(x: 0, y: 5, width: 80, height: 40))
  }

  @Test func copiedHierarchyRetainsOriginalsMetadataPaintAndDistinctIDsAtomically() throws {
    var drawing = Drawing()
    let a = try drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 10, y: 20, width: 100, height: 50))],
        VectorStyle(fill: VectorStyle.solid(1, 0, 0)), layer: 1))
    let b = try drawing.perform(
      .addPath(
        [ShapePaths.ellipse(CGRect(x: 150, y: 20, width: 50, height: 50))],
        VectorStyle(fill: VectorStyle.solid(0, 0, 1)), layer: 1))
    let child = try #require(a.first)
    drawing.updateNode(child) { $0["unknown"]["keep"] = .string("nested metadata") }
    let grouped = try drawing.perform(.group(a.union(b)))
    let groupID = try #require(grouped.first)
    let original = try #require(drawing.node(groupID))
    let ids = try drawing.perform(
      .transform(grouped.union(a), .init(translationX: 30, y: 40), copy: true))
    let copied = try #require(ids.first.flatMap(drawing.node))
    #expect(ids.count == 1)
    #expect(drawing.node(groupID) == original)
    #expect(drawing.layers.first?.children.map(\.id) == [groupID, copied.id])
    #expect(Set(copied.children.map(\.id)).isDisjoint(with: a.union(b)))
    #expect(copied.children.first?.raw["unknown"]["keep"].string == "nested metadata")
    #expect(copied.children.first?.raw["appearance"] == original.children.first?.raw["appearance"])
    expectRect(copied.bounds, CGRect(x: 40, y: 60, width: 190, height: 50))
    let reopened = try NativeFormat.decode(NativeFormat.encode(drawing))
    #expect(reopened.envelope["document"] == drawing.envelope["document"])
    let svg = String(decoding: try SVGExport.encode(drawing), as: UTF8.self)
    #expect(svg.contains("<path"))
    let saved = drawing
    drawing.updateNode(groupID) { $0["locked"] = .bool(true) }
    let locked = drawing
    #expect(throws: DrawingError.self) {
      try drawing.perform(.transform(grouped, .init(translationX: 1, y: 1), copy: true))
    }
    #expect(drawing == locked)
    drawing = saved
    #expect(throws: DrawingError.self) {
      try drawing.perform(.transform(grouped, .init(translationX: .nan, y: 0), copy: true))
    }
    #expect(drawing == saved)
  }

  private func expectRect(_ actual: CGRect, _ expected: CGRect) {
    #expect(abs(actual.minX - expected.minX) < 0.000001)
    #expect(abs(actual.minY - expected.minY) < 0.000001)
    #expect(abs(actual.width - expected.width) < 0.000001)
    #expect(abs(actual.height - expected.height) < 0.000001)
  }
}
