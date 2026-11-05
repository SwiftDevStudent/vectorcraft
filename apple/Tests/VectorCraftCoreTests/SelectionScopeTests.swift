import CoreGraphics
import Foundation
import ImageIO
import Testing

@testable import VectorCraftCore

struct SelectionScopeTests {
  @Test func groupAndDirectTargetsRespectScopeVisibilityLocksAndSnapping() throws {
    var f = try Fixture()
    let point = CGPoint(x: 20, y: 20)
    #expect(f.drawing.hitTest(point, tolerance: 2, selectingGroups: true) == f.group)
    #expect(f.drawing.hitTest(point, tolerance: 2) == f.first)
    #expect(
      f.drawing.hitTest(point, tolerance: 2, selectingGroups: true, within: f.group) == f.first)
    #expect(f.drawing.hitTest(CGPoint(x: 110, y: 20), tolerance: 2, within: f.group) == nil)
    #expect(f.drawing.selectableIDs() == [f.group, f.outside])
    #expect(f.drawing.selectableIDs(within: f.group) == [f.first, f.second])
    #expect(
      f.drawing.selectableIDs(intersecting: CGRect(x: 5, y: 5, width: 10, height: 10)) == [f.group])
    #expect(
      !Snapping.targets(in: f.drawing, excluding: [], within: f.group).contains(
        CGRect(x: 100, y: 10, width: 30, height: 30)))
    f.drawing.updateNode(f.second) { $0["visible"] = .bool(false) }
    #expect(f.drawing.selectableIDs(within: f.group) == [f.first])
    f.drawing.updateNode(f.group) { $0["locked"] = .bool(true) }
    #expect(!f.drawing.canIsolate(f.group))
    #expect(f.drawing.selectionRoots(within: f.group).isEmpty)
    #expect(f.drawing.hitTest(point, tolerance: 2, selectingGroups: true) == nil)
  }

  @Test func scopedCommandsInsertInsideAndRejectEveryOutsideTargetAtomically() throws {
    let f = try Fixture()
    let original = f.drawing
    let path = ShapePaths.rectangle(CGRect(x: 20, y: 50, width: 20, height: 20))
    let outside: [DrawingCommand] = [
      .transform([f.outside], .init(translationX: 1, y: 1), copy: true),
      .delete([f.outside]), .style([f.outside], VectorStyle()),
      .group([f.first, f.outside]), .ungroup(f.group), .rename(f.outside, "Wrong"),
      .visibility(f.outside, false), .lock(f.outside, true), .addLayer,
      .resizeArtboard(0, CGSize(width: 500, height: 500)),
      .addPath([path], VectorStyle(), layer: 1),
      .addText(
        "Outside", .zero, font: "Helvetica", size: 16, fill: VectorStyle.solid(0, 0, 0), layer: 1),
      .addAreaText(
        "Outside", CGRect(x: 0, y: 0, width: 30, height: 30), font: "Helvetica", size: 16,
        fill: VectorStyle.solid(0, 0, 0), layer: 1),
      .pathfinder([f.first, f.outside], .unite),
      .transformEach([f.first, f.outside], IndividualTransform(), copy: true),
    ]
    for command in outside {
      var drawing = original
      #expect(throws: DrawingError.self) { try drawing.perform(command, within: f.group) }
      #expect(drawing == original)
    }
    var drawing = original
    let shape = try drawing.perform(
      .addPath([path], VectorStyle(), layer: f.group), within: f.group)
    let text = try drawing.perform(
      .addText(
        "Inside", CGPoint(x: 30, y: 80), font: "Helvetica", size: 16,
        fill: VectorStyle.solid(0, 0, 0), layer: f.group), within: f.group)
    #expect(drawing.node(f.group)?.children.count == 4)
    #expect(shape.union(text).allSatisfy { drawing.isInside($0, isolation: f.group) })
    #expect(drawing.node(f.outside) == original.node(f.outside))
    #expect(drawing.node(f.first)?.raw["unknown"]["keep"].string == "source")
    let reopened = try NativeFormat.decode(NativeFormat.encode(drawing))
    #expect(reopened.envelope["document"] == drawing.envelope["document"])
    _ = try SVGExport.encode(reopened)
    _ = try PDFExport.encode(reopened)
  }

  @Test func isolationDimmingIsPresentationOnlyAndDoesNotAccumulateOnDescendants() throws {
    var f = try Fixture()
    let extra = try f.drawing.perform(
      .addPath(
        [ShapePaths.rectangle(CGRect(x: 100, y: 50, width: 30, height: 30))],
        VectorStyle(fill: VectorStyle.solid(0, 0, 1), stroke: VectorStyle.none), layer: 1))
    try f.drawing.perform(.group(extra.union([f.outside])))
    let original = f.drawing
    func render(_ scope: Int64?) throws -> Data {
      let context = try #require(
        CGContext(
          data: nil, width: 150, height: 100, bitsPerComponent: 8, bytesPerRow: 600,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            | CGBitmapInfo.byteOrder32Big.rawValue))
      context.setFillColor(CGColor(gray: 1, alpha: 1))
      context.fill(CGRect(x: 0, y: 0, width: 150, height: 100))
      context.translateBy(x: 0, y: 100)
      context.scaleBy(x: 1, y: -1)
      VectorRenderer.render(f.drawing, in: context, isolating: scope)
      let bytes = try #require(context.data)
      return Data(bytes: bytes, count: 600 * 100)
    }
    let normal = try render(nil)
    let dimmed = try render(f.group)
    let inside = 20 * 600 + 20 * 4
    let outside = 20 * 600 + 110 * 4
    #expect(dimmed[inside] == normal[inside] && dimmed[inside + 1] == normal[inside + 1])
    #expect(normal[outside] == 0 && normal[outside + 2] == 255)
    #expect(abs(Int(dimmed[outside]) - 204) <= 1 && dimmed[outside + 2] == 255)
    #expect(f.drawing == original)
    #expect(try render(nil) == normal)
    let source = try #require(
      CGImageSourceCreateWithData(try VectorRenderer.png(f.drawing) as CFData, nil))
    #expect(CGImageSourceGetCount(source) == 1)
  }

  private struct Fixture {
    var drawing: Drawing
    var first: Int64
    var second: Int64
    var group: Int64
    var outside: Int64
    init() throws {
      var drawing = Drawing(width: 150, height: 100)
      let a = try drawing.perform(
        .addPath(
          [ShapePaths.rectangle(CGRect(x: 10, y: 10, width: 30, height: 30))],
          VectorStyle(fill: VectorStyle.solid(1, 0, 0), stroke: VectorStyle.none), layer: 1))
      let b = try drawing.perform(
        .addPath(
          [ShapePaths.rectangle(CGRect(x: 50, y: 10, width: 30, height: 30))],
          VectorStyle(fill: VectorStyle.solid(0, 1, 0), stroke: VectorStyle.none), layer: 1))
      first = try #require(a.first)
      second = try #require(b.first)
      drawing.updateNode(first) { $0["unknown"]["keep"] = .string("source") }
      let grouped = try drawing.perform(.group(a.union(b)))
      group = try #require(grouped.first)
      let c = try drawing.perform(
        .addPath(
          [ShapePaths.rectangle(CGRect(x: 100, y: 10, width: 30, height: 30))],
          VectorStyle(fill: VectorStyle.solid(0, 0, 1), stroke: VectorStyle.none), layer: 1))
      outside = try #require(c.first)
      self.drawing = drawing
    }
  }
}
