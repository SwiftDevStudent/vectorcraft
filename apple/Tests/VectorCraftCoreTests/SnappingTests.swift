import CoreGraphics
import Testing

@testable import VectorCraftCore

struct SnappingTests {
  @Test func gridHandlesNegativeCoordinatesAndBypass() {
    #expect(Snapping.grid(CGPoint(x: 16, y: -26), spacing: 10) == CGPoint(x: 20, y: -30))
    #expect(Snapping.grid(CGPoint(x: 19, y: 27), spacing: 8) == CGPoint(x: 16, y: 24))
    let raw = CGPoint(x: 17, y: 23)
    #expect(
      Snapping.position(raw, targets: [], grid: false, guides: false, tolerance: 6).point == raw)
  }

  @Test func movingBoundsAlignByEdgesAndCentersWithinScreenTolerance() {
    let moving = CGRect(x: 0, y: 0, width: 40, height: 20)
    let target = CGRect(x: 100, y: 100, width: 60, height: 40)
    let snapped = Snapping.position(
      CGPoint(x: 87, y: 98), moving: moving, targets: [target], grid: false, guides: true,
      tolerance: 6)
    #expect(snapped.point == CGPoint(x: 90, y: 100))
    #expect(snapped.guides.count == 2)
    // At 2x zoom, a four-document-point miss is outside the six-screen-point radius.
    #expect(
      Snapping.position(
        CGPoint(x: 84, y: 94), moving: moving, targets: [target], grid: false, guides: true,
        tolerance: 3
      ).point == CGPoint(x: 84, y: 94))
  }

  @Test func targetsExcludeMovingDescendantsAndHiddenAncestors() throws {
    var drawing = Drawing()
    let one = try drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 20, y: 20, width: 30, height: 30))], VectorStyle(), layer: 1
      ))
    let two = try drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 200, y: 200, width: 40, height: 40))], VectorStyle(),
        layer: 1))
    let ids = one.union(two)
    let group = try drawing.perform(.group(ids))
    #expect(Snapping.targets(in: drawing, excluding: group) == drawing.artboards)
    let visible = Snapping.targets(in: drawing, excluding: one)
    #expect(visible.contains(CGRect(x: 200, y: 200, width: 40, height: 40)))
    #expect(!visible.contains(CGRect(x: 20, y: 20, width: 30, height: 30)))
    let hidden = try #require(two.first)
    drawing.updateNode(hidden) { $0["visible"] = .bool(false) }
    #expect(
      Snapping.targets(in: drawing, excluding: []).contains(
        CGRect(x: 20, y: 20, width: 30, height: 30)))
    #expect(
      !Snapping.targets(in: drawing, excluding: []).contains(
        CGRect(x: 200, y: 200, width: 40, height: 40)))
    drawing.updateNode(1) { $0["visible"] = .bool(false) }
    #expect(Snapping.targets(in: drawing, excluding: []) == drawing.artboards)
  }
}
