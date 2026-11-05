import CoreGraphics
import Testing

@testable import VectorCraftCore

struct IndividualTransformTests {
  @Test func eachUsesIndividualCentersRatherThanTheCombinedSelectionCenter() throws {
    var f = try Fixture()
    var values = IndividualTransform()
    values.scaleX = 50
    values.scaleY = 200
    values.moveX = 10
    values.moveY = 15
    try f.drawing.perform(.transformEach([f.a, f.b], values))
    #expect(f.drawing.node(f.a)?.bounds == CGRect(x: 55, y: 5, width: 50, height: 160))
    #expect(f.drawing.node(f.b)?.bounds == CGRect(x: 320, y: 205, width: 20, height: 40))
  }

  @Test(arguments: TransformReference.allCases)
  func referencePointsKeepTheChosenPositionFixed(_ reference: TransformReference) throws {
    var f = try Fixture()
    var values = IndividualTransform()
    values.scaleX = 200
    values.scaleY = 300
    values.reference = reference
    let origins = [
      CGPoint(x: 20, y: 30), CGPoint(x: -30, y: 30), CGPoint(x: -80, y: 30),
      CGPoint(x: 20, y: -50), CGPoint(x: -30, y: -50), CGPoint(x: -80, y: -50),
      CGPoint(x: 20, y: -130), CGPoint(x: -30, y: -130), CGPoint(x: -80, y: -130),
    ]
    try f.drawing.perform(.transformEach([f.a], values))
    #expect(
      f.drawing.node(f.a)?.bounds
        == CGRect(origin: origins[reference.rawValue], size: CGSize(width: 200, height: 240)))
  }

  @Test func groupedCopiesTransformOnceAndPreserveOriginalsMetadataAndNativeVersions() throws {
    for version in [Int64(1), 3] {
      var f = try Fixture(version: version)
      let group = try #require(try f.drawing.perform(.group([f.a, f.b])).first)
      let original = f.drawing
      var values = IndividualTransform()
      values.moveX = 20
      let copy = try #require(
        try f.drawing.perform(.transformEach([group, f.a], values, copy: true)).first)
      #expect(f.drawing.node(group) == original.node(group))
      let children = try #require(f.drawing.node(copy)?.children)
      #expect(children.count == 2 && !children.contains { [f.a, f.b].contains($0.id) })
      #expect(children.first?.bounds == CGRect(x: 40, y: 30, width: 100, height: 80))
      #expect(children.first?.raw["unknown"]["keep"].string == "source")
      let reopened = try NativeFormat.decode(NativeFormat.encode(f.drawing))
      #expect(reopened.envelope["document"] == f.drawing.envelope["document"])
      _ = try SVGExport.encode(reopened)
      _ = try PDFExport.encode(reopened)
    }
  }

  @Test func randomPreviewAndCommitAgreeAndInvalidOrOutsideCommandsAreAtomic() throws {
    let f = try Fixture()
    var values = IndividualTransform()
    values.random = true
    values.seed = 719
    values.scaleX = 200
    values.scaleY = 50
    values.moveX = 30
    values.rotation = 45
    var a = f.drawing
    var b = f.drawing
    try a.perform(.transformEach([f.a, f.b], values))
    try b.perform(.transformEach([f.b, f.a], values))
    #expect(a == b && a != f.drawing)
    for id in [f.a, f.b] {
      let before = try #require(f.drawing.node(id)?.bounds)
      let after = try #require(a.node(id)?.bounds)
      #expect(abs(after.midX - before.midX) <= 30.000001)
      #expect(abs(after.midY - before.midY) < 0.000001)
    }
    values.scaleX = 0
    #expect(throws: DrawingError.self) {
      try b.perform(.transformEach([f.a, f.b], values, copy: true))
    }
    #expect(b == a)
    let original = b
    values.scaleX = .infinity
    #expect(throws: DrawingError.self) { try b.perform(.transformEach([f.a], values)) }
    #expect(b == original)
    values.scaleX = 100
    #expect(throws: DrawingError.self) { try b.perform(.transformEach([f.a], values), within: f.b) }
    #expect(b == original)
  }

  @Test func rotationReflectionsAndCustomShearAxesHaveTheExpectedDirection() throws {
    var f = try Fixture()
    var values = IndividualTransform()
    values.rotation = 90
    try f.drawing.perform(.transformEach([f.a], values))
    let p = try #require(f.drawing.node(f.a)?.subpaths.first?.anchors.first?.point)
    #expect(abs(p.x - 30) < 0.000001 && abs(p.y - 120) < 0.000001)
    let testPoint = CGPoint(x: 3, y: 2)
    let horizontal = try TransformGeometry.reflection(axis: 0, around: .zero)
    let vertical = try TransformGeometry.reflection(axis: 90, around: .zero)
    let diagonal = try TransformGeometry.reflection(axis: 45, around: .zero)
    #expect(testPoint.applying(horizontal).distance(to: CGPoint(x: 3, y: -2)) < 0.000001)
    #expect(testPoint.applying(vertical).distance(to: CGPoint(x: -3, y: 2)) < 0.000001)
    #expect(testPoint.applying(diagonal).distance(to: CGPoint(x: -2, y: -3)) < 0.000001)
    let shearH = try TransformGeometry.shear(angle: 45, axis: 0, around: .zero)
    let shearV = try TransformGeometry.shear(angle: 45, axis: 90, around: .zero)
    let shearD = try TransformGeometry.shear(angle: 45, axis: 45, around: .zero)
    #expect(testPoint.applying(shearH).distance(to: CGPoint(x: 1, y: 2)) < 0.000001)
    #expect(testPoint.applying(shearV).distance(to: CGPoint(x: 3, y: 5)) < 0.000001)
    #expect(testPoint.applying(shearD).distance(to: CGPoint(x: 0.5, y: 4.5)) < 0.000001)
    #expect(throws: DrawingError.self) {
      try TransformGeometry.shear(angle: 90, axis: 0, around: .zero)
    }
    #expect(throws: DrawingError.self) {
      try TransformGeometry.reflection(axis: .nan, around: .zero)
    }
    var reflected = IndividualTransform()
    reflected.reflectX = true
    var random = TransformRandom(state: 1)
    let matrix = try reflected.matrix(
      in: CGRect(x: 0, y: 0, width: 10, height: 10), random: &random)
    #expect(CGPoint(x: 2, y: 3).applying(matrix) == CGPoint(x: 2, y: 7))
  }

  private struct Fixture {
    var drawing: Drawing
    let a: Int64
    let b: Int64
    init(version: Int64 = 3) throws {
      var drawing = Drawing()
      drawing.envelope["version"] = .integer(version)
      if version == 1 { drawing.envelope["format"] = .string("drawcraft") }
      a = try #require(
        try drawing.perform(
          .addPath(
            [ShapePaths.rectangle(CGRect(x: 20, y: 30, width: 100, height: 80))], VectorStyle(),
            layer: 1)
        ).first)
      b = try #require(
        try drawing.perform(
          .addPath(
            [ShapePaths.rectangle(CGRect(x: 300, y: 200, width: 40, height: 20))], VectorStyle(),
            layer: 1)
        ).first)
      drawing.updateNode(a) { $0["unknown"]["keep"] = .string("source") }
      self.drawing = drawing
    }
  }
}
