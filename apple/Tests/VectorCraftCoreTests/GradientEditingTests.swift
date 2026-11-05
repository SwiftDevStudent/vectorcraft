import CoreGraphics
import Foundation
import Testing

@testable import VectorCraftCore

struct GradientEditingTests {
  @Test func movingAndInsertingStopsKeepNativeOrderAndReturnTheSelectedStop() throws {
    let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
    let initial = try GradientPaint.editing(VectorStyle.none, bounds: bounds, with: .kind(.linear))
    let inserted = try GradientPaint.editing(initial.raw, bounds: bounds, with: .insertStop(0.5))
    #expect(
      inserted.selectedStop == 1 && inserted.stops.map { $0["offset"].double } == [0, 0.5, 1])
    let moved = try GradientPaint.editing(inserted.raw, bounds: bounds, with: .stopOffset(0, 0.75))
    #expect(moved.selectedStop == 1 && moved.stops.map { $0["offset"].double } == [0.5, 0.75, 1])
    let reversed = try GradientPaint.editing(
      moved.raw, bounds: bounds, with: .reverse, selecting: 0)
    #expect(
      reversed.selectedStop == 2 && reversed.stops.map { $0["offset"].double } == [0, 0.25, 0.5])
    let duplicate = try GradientPaint.editing(inserted.raw, bounds: bounds, with: .insertStop(0.5))
    #expect(
      duplicate.selectedStop == 2
        && duplicate.stops.map { $0["offset"].double } == [0, 0.5, 0.5, 1])
  }
  @Test func insertingAnInterpolatedTransparentStopPreservesTheRenderedRamp() throws {
    var drawing = Drawing(width: 100, height: 100)
    let id = try #require(
      try drawing.perform(
        .addPath(
          [ShapePaths.rectangle(CGRect(x: 0, y: 0, width: 100, height: 100))],
          VectorStyle(stroke: VectorStyle.none), layer: 1)
      ).first)
    try drawing.perform(.gradient([id], .fill, .kind(.linear)))
    try drawing.perform(.gradient([id], .fill, .stopColor(0, VectorStyle.solid(1, 0, 0)["color"])))
    try drawing.perform(.gradient([id], .fill, .stopColor(1, VectorStyle.solid(0, 0, 1)["color"])))
    try drawing.perform(.gradient([id], .fill, .stopOpacity(0, 0.2)))
    try drawing.perform(.gradient([id], .fill, .stopOpacity(1, 0.8)))
    let positions = [1, 25, 50, 75, 98]
    let before = try positions.map { try pixel(drawing, x: $0) }
    try drawing.perform(.gradient([id], .fill, .insertStop(0.5)))
    let after = try positions.map { try pixel(drawing, x: $0) }
    for (a, b) in zip(before, after) {
      #expect(abs(a.0 - b.0) <= 1 && abs(a.1 - b.1) <= 1 && abs(a.2 - b.2) <= 1)
    }
    if let path = ProcessInfo.processInfo.environment["VECTORCRAFT_TEST_ARTIFACTS"] {
      let folder = URL(fileURLWithPath: path)
      try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
      try NativeFormat.encode(drawing).write(
        to: folder.appending(path: "gradient-alpha.vectorcraft"), options: .atomic)
      try SVGExport.encode(drawing).write(
        to: folder.appending(path: "gradient-alpha.svg"), options: .atomic)
      try VectorRenderer.png(drawing).write(
        to: folder.appending(path: "gradient-alpha.png"), options: .atomic)
    }
  }
  @Test func automaticRadialAspectAndKindChangesWriteCompleteNativeGeometry() throws {
    for version in [Int64(1), 3] {
      var drawing = Drawing(width: 240, height: 120)
      drawing.envelope["version"] = .integer(version)
      let a = try add(&drawing, CGRect(x: 10, y: 20, width: 100, height: 80))
      let b = try add(&drawing, CGRect(x: 130, y: 20, width: 50, height: 80))
      try drawing.perform(.gradient([a], .fill, .kind(.linear)))
      try drawing.perform(.gradient([a], .fill, .kind(.radial)))
      let changed = try gradient(a, drawing)
      #expect(changed.raw["geom"]["start"].point == CGPoint(x: 60, y: 60))
      #expect(changed.raw["geom"]["end"].point == CGPoint(x: 110, y: 60))
      try drawing.perform(.gradient([b], .fill, .kind(.radial)))
      try drawing.perform(.gradient([b], .fill, .aspect(0.5)))
      let aspect = try gradient(b, drawing)
      #expect(aspect.raw["geom"]["start"].point == CGPoint(x: 155, y: 60))
      #expect(aspect.raw["geom"]["end"].point == CGPoint(x: 195, y: 60))
      #expect(aspect.aspect == 0.5)
      let path = ProcessInfo.processInfo.environment["VECTORCRAFT_TEST_ARTIFACTS"]
      let folder =
        path.map { URL(fileURLWithPath: $0) }
        ?? FileManager.default.temporaryDirectory.appending(path: "VectorCraft-Gradient-\(UUID())")
      try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
      try NativeFormat.encode(drawing).write(
        to: folder.appending(path: "gradient-v\(version).vectorcraft"), options: .atomic)
      try SVGExport.encode(drawing).write(
        to: folder.appending(path: "gradient-v\(version).svg"), options: .atomic)
      try VectorRenderer.png(drawing).write(
        to: folder.appending(path: "gradient-v\(version).png"), options: .atomic)
    }
  }
  @Test func editedStopColorsOpacityAndReverseReachTheRenderedArtwork() throws {
    var drawing = Drawing(width: 100, height: 100)
    let id = try #require(
      try drawing.perform(
        .addPath(
          [ShapePaths.rectangle(CGRect(x: 0, y: 0, width: 100, height: 100))],
          VectorStyle(stroke: VectorStyle.none), layer: 1)
      ).first)
    try drawing.perform(.gradient([id], .fill, .kind(.linear)))
    try drawing.perform(.gradient([id], .fill, .stopColor(0, VectorStyle.solid(1, 0, 0)["color"])))
    try drawing.perform(.gradient([id], .fill, .stopColor(1, VectorStyle.solid(0, 0, 1)["color"])))
    var left = try pixel(drawing, x: 1)
    var right = try pixel(drawing, x: 98)
    #expect(left.0 > 245 && left.2 < 10 && right.2 > 245 && right.0 < 10)
    try drawing.perform(.gradient([id], .fill, .insertStop(0.5)))
    try drawing.perform(.gradient([id], .fill, .stopOpacity(1, 0)))
    let center = try pixel(drawing, x: 50)
    #expect(center.0 > 245 && center.1 > 245 && center.2 > 245)
    try drawing.perform(.gradient([id], .fill, .reverse))
    left = try pixel(drawing, x: 1)
    right = try pixel(drawing, x: 98)
    #expect(left.2 > 240 && left.0 < 15 && right.0 > 240 && right.2 < 15)
  }

  @Test func groupTargetsAreDeduplicatedAndIsolationAndInheritedLocksAreAtomic() throws {
    var drawing = Drawing()
    let a = try add(&drawing, CGRect(x: 20, y: 20, width: 80, height: 60))
    let b = try add(&drawing, CGRect(x: 120, y: 20, width: 40, height: 60))
    let outside = try add(&drawing, CGRect(x: 220, y: 20, width: 40, height: 60))
    let group = try #require(try drawing.perform(.group([a, b])).first)
    try drawing.perform(.gradient([group, a], .fill, .kind(.linear)))
    #expect(try drawing.gradientTargets([group, a]).count == 2)
    try drawing.perform(.gradient([a], .fill, .insertStop(0.5)), within: group)
    let before = drawing
    #expect(throws: DrawingError.self) {
      try drawing.perform(.gradient([outside], .fill, .kind(.radial)), within: group)
    }
    #expect(drawing == before)
    try drawing.perform(.lock(b, true))
    let locked = drawing
    #expect(throws: DrawingError.self) { try drawing.perform(.gradient([group], .fill, .reverse)) }
    #expect(drawing == locked)
  }
  @Test func gradientsUseEachObjectsBoundsAndOnlyChangeTheTargetPaint() throws {
    var drawing = Drawing(width: 400, height: 200)
    let a = try add(&drawing, CGRect(x: 10, y: 20, width: 100, height: 80))
    let b = try add(&drawing, CGRect(x: 220, y: 30, width: 40, height: 30))
    drawing.updateNode(a) { raw in
      raw["foreign"]["keep"] = .string("node")
      var items = raw["appearance"]["items"].array
      items[0]["opacity"] = .number(0.7)
      items[1]["dash"] = .object(["pattern": .array([.number(4), .number(2)])])
      raw["appearance"]["items"] = .array(items)
    }
    let before = try #require(drawing.node(a))
    try drawing.perform(.gradient([a, b], .fill, .kind(.linear)))
    let ga = try gradient(a, drawing)
    let gb = try gradient(b, drawing)
    #expect(ga.start == CGPoint(x: 10, y: 60) && ga.end == CGPoint(x: 110, y: 60))
    #expect(gb.start == CGPoint(x: 220, y: 45) && gb.end == CGPoint(x: 260, y: 45))
    #expect(drawing.node(a)?.raw["foreign"] == before.raw["foreign"])
    #expect(
      drawing.node(a)?.raw["appearance"]["items"].array[1]
        == before.raw["appearance"]["items"].array[1])
    #expect(drawing.node(a)?.raw["appearance"]["items"].array[0]["opacity"] == .number(0.7))
    let fill = ga.raw
    try drawing.perform(.gradient([a], .stroke, .kind(.radial)))
    #expect(try gradient(a, drawing).raw == fill)
    #expect(try gradient(a, drawing, .stroke).kind == .radial)
    #expect(
      drawing.node(a)?.raw["appearance"]["items"].array[1]["dash"]
        == before.raw["appearance"]["items"].array[1]["dash"])
  }

  @Test func stopEditsInterpolateColorsPreserveForeignDataAndReverseTheRamp() throws {
    var drawing = Drawing()
    let id = try add(&drawing, CGRect(x: 0, y: 0, width: 100, height: 100))
    try drawing.perform(.gradient([id], .fill, .kind(.linear)))
    drawing.updateNode(id) { raw in
      var items = raw["appearance"]["items"].array
      items[0]["paint"]["foreign"] = .string("paint")
      var stops = items[0]["paint"]["gradient"]["stops"].array
      stops[0]["foreign"] = .string("stop")
      items[0]["paint"]["gradient"]["stops"] = .array(stops)
      raw["appearance"]["items"] = .array(items)
    }
    try drawing.perform(.gradient([id], .fill, .stopColor(0, VectorStyle.solid(1, 0, 0)["color"])))
    try drawing.perform(.gradient([id], .fill, .stopColor(1, VectorStyle.solid(0, 0, 1)["color"])))
    try drawing.perform(.gradient([id], .fill, .insertStop(0.25)))
    let inserted = try gradient(id, drawing)
    #expect(inserted.stops.count == 3)
    #expect(inserted.stops[1]["color"] == VectorStyle.solid(0.75, 0, 0.25)["color"])
    try drawing.perform(.gradient([id], .fill, .stopOffset(1, 0.4)))
    try drawing.perform(.gradient([id], .fill, .stopOpacity(1, 0.5)))
    try drawing.perform(.gradient([id], .fill, .reverse))
    let reversed = try gradient(id, drawing)
    #expect(reversed.raw["foreign"].string == "paint")
    #expect(reversed.stops.last?["foreign"].string == "stop")
    #expect(reversed.stops[1]["offset"].double == 0.6)
    #expect(reversed.stops[1]["opacity"].double == 0.5)
    try drawing.perform(.gradient([id], .fill, .removeStop(1)))
    #expect(try gradient(id, drawing).stops.count == 2)
  }

  @Test func geometryAnglesRadialAspectAndLegacyPersistenceStayConsistent() throws {
    for version in [Int64(1), 3] {
      var drawing = Drawing(width: 200, height: 200)
      drawing.envelope["version"] = .integer(version)
      let id = try add(&drawing, CGRect(x: 10, y: 20, width: 100, height: 80))
      try drawing.perform(.gradient([id], .fill, .kind(.linear)))
      try drawing.perform(.gradient([id], .fill, .angle(90)))
      var g = try gradient(id, drawing)
      #expect(abs(g.start.x - 60) < 0.000001 && abs(g.start.y - 110) < 0.000001)
      #expect(abs(g.end.x - 60) < 0.000001 && abs(g.end.y - 10) < 0.000001)
      try drawing.perform(.gradient([id], .fill, .kind(.radial)))
      try drawing.perform(
        .gradient([id], .fill, .geometry(CGPoint(x: 40, y: 50), CGPoint(x: 90, y: 50))))
      try drawing.perform(.gradient([id], .fill, .aspect(0.4)))
      g = try gradient(id, drawing)
      #expect(
        g.kind == .radial && g.start == CGPoint(x: 40, y: 50) && g.end == CGPoint(x: 90, y: 50)
          && g.aspect == 0.4)
      let reopened = try NativeFormat.decode(NativeFormat.encode(drawing))
      #expect(reopened.layers == drawing.layers && reopened.version == version)
      #expect(!drawing.renderingWarnings.contains("complex gradients"))
      #expect(try SVGExport.encode(drawing).count > 100)
      #expect(try PDFExport.encode(drawing).starts(with: Data("%PDF".utf8)))
      #expect(try VectorRenderer.png(drawing).starts(with: [137, 80, 78, 71]))
    }
  }

  @Test func invalidAndUnsupportedEditsLeaveEverySelectedObjectUnchanged() throws {
    var drawing = Drawing()
    let a = try add(&drawing, CGRect(x: 10, y: 10, width: 80, height: 60))
    let b = try add(&drawing, CGRect(x: 130, y: 10, width: 40, height: 30))
    try drawing.perform(.gradient([a, b], .fill, .kind(.linear)))
    let before = drawing
    for edit: GradientEdit in [
      .stopOffset(5, 0.2), .stopOpacity(0, .nan), .stopOffset(0, -1), .removeStop(0),
      .angle(.infinity), .aspect(0), .geometry(.zero, .zero),
    ] {
      #expect(throws: DrawingError.self) { try drawing.perform(.gradient([a, b], .fill, edit)) }
      #expect(drawing == before)
    }
    let text = try #require(
      try drawing.perform(
        .addText(
          "Keep type", .zero, font: "Helvetica", size: 20, fill: VectorStyle.solid(0, 0, 0),
          layer: 1)
      ).first)
    let withText = drawing
    #expect(throws: DrawingError.self) {
      try drawing.perform(.gradient([a, text], .fill, .kind(.radial)))
    }
    #expect(drawing == withText)
    drawing.updateNode(b) { raw in
      var items = raw["appearance"]["items"].array
      var stops = items[0]["paint"]["gradient"]["stops"].array
      stops[0]["swatch"] = .string("Global")
      items[0]["paint"]["gradient"]["stops"] = .array(stops)
      raw["appearance"]["items"] = .array(items)
    }
    let linked = drawing
    #expect(throws: DrawingError.self) { try drawing.perform(.gradient([a, b], .fill, .reverse)) }
    #expect(drawing == linked)
    try drawing.perform(.lock(b, true))
    let locked = drawing
    #expect(throws: DrawingError.self) {
      try drawing.perform(.gradient([a, b], .fill, .kind(.radial)))
    }
    #expect(drawing == locked)
  }

  private func add(_ drawing: inout Drawing, _ rect: CGRect) throws -> Int64 {
    try #require(
      try drawing.perform(.addPath([ShapePaths.rectangle(rect)], VectorStyle(), layer: 1)).first)
  }
  private func pixel(_ drawing: Drawing, x: Int) throws -> (Int, Int, Int) {
    let context = try #require(
      CGContext(
        data: nil, width: 100, height: 100, bitsPerComponent: 8, bytesPerRow: 400,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
    VectorRenderer.render(drawing, in: context)
    let bytes = try #require(context.data).assumingMemoryBound(to: UInt8.self)
    let offset = 50 * 400 + x * 4
    return (Int(bytes[offset]), Int(bytes[offset + 1]), Int(bytes[offset + 2]))
  }
  private func gradient(_ id: Int64, _ drawing: Drawing, _ target: PaintTarget = .fill) throws
    -> GradientPaint
  {
    let node = try #require(drawing.node(id))
    return try GradientPaint(GradientPaint.paint(of: node, target: target), bounds: node.bounds)
  }
}
