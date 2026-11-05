import AppKit
import Testing
import VectorCraftCore

@testable import VectorCraftMac

@MainActor
struct TransformAgainTests {
  @Test func moveRepeatsOnCurrentSelectionAndSurvivesStyleAndUndo() throws {
    let f = try Fixture()
    #expect(f.document.transformAgainCommand(for: [f.first]) == nil)
    try f.run(.transform([f.first], .init(translationX: 30, y: 10)))
    try f.run(.style([f.second], VectorStyle(fill: VectorStyle.solid(1, 0, 0))))
    try f.repeatTransform([f.second])
    #expect(f.document.drawing.node(f.second)?.bounds.origin == CGPoint(x: 230, y: 60))
    f.undo.undo()
    #expect(f.document.drawing.node(f.second)?.bounds.origin == CGPoint(x: 200, y: 50))
    f.undo.redo()
    #expect(f.document.drawing.node(f.second)?.bounds.origin == CGPoint(x: 230, y: 60))
    try f.repeatTransform([f.second])
    #expect(f.document.drawing.node(f.second)?.bounds.origin == CGPoint(x: 260, y: 70))
    #expect(f.document.drawing.node(f.second)?.raw["unknown"]["keep"].string == "retained")
    #expect(f.document.transformAgainCommand(for: []) == nil)
  }

  @Test func copyRepetitionKeepsFreshIDsPaintAndMetadataAndExportsWithoutHistory() throws {
    let f = try Fixture()
    let original = f.document.drawing.node(f.first)
    let copy = try f.run(.transform([f.first], .init(translationX: 50, y: 0), copy: true))
    let repeated = try f.repeatTransform(copy)
    let id = try #require(repeated.first)
    #expect(copy != repeated && !repeated.contains(f.first))
    #expect(f.document.drawing.node(f.first) == original)
    #expect(f.document.drawing.node(id)?.bounds.origin == CGPoint(x: 120, y: 30))
    #expect(f.document.drawing.node(id)?.raw["unknown"]["keep"].string == "retained")
    let saved = f.document.drawing
    f.undo.undo()
    #expect(f.document.drawing.node(id) == nil)
    f.undo.redo()
    #expect(f.document.drawing == saved)
    let reopened = try NativeFormat.decode(NativeFormat.encode(saved))
    #expect(reopened.envelope["document"] == saved.envelope["document"])
    #expect(CanvasDocument(drawing: reopened).transformAgainCommand(for: repeated) == nil)
    _ = try SVGExport.encode(reopened)
    _ = try PDFExport.encode(reopened)
  }

  @Test func newScaleReplacesMoveAndFailedOrIdentityTransformsDoNotReplaceIt() throws {
    let f = try Fixture()
    try f.run(.transform([f.first], .init(translationX: 5, y: 0)))
    try f.run(.transform([f.first], .init(scaleX: 2, y: 3)))
    try f.run(.transform([f.first], .identity))
    #expect(throws: DrawingError.self) {
      try f.run(.transform([f.first], .init(a: .nan, b: 0, c: 0, d: 1, tx: 0, ty: 0)))
    }
    try f.repeatTransform([f.second])
    #expect(
      f.document.drawing.node(f.second)?.bounds == CGRect(x: 400, y: 150, width: 80, height: 60))
    try f.run(.transform([f.first], .init(rotationAngle: .pi / 2)))
    try f.repeatTransform([f.second])
    let bounds = try #require(f.document.drawing.node(f.second)?.bounds)
    #expect(abs(bounds.minX + 210) < 0.000001 && abs(bounds.minY - 400) < 0.000001)
    #expect(abs(bounds.width - 60) < 0.000001 && abs(bounds.height - 80) < 0.000001)
  }

  @Test func isolationRejectsOutsideRepeatAndAppliedSnapshotsResetHistory() async throws {
    let f = try Fixture()
    let group = try #require(try f.run(.group([f.first, f.second])).first)
    let other = try #require(
      try f.run(
        .addPath(
          [ShapePaths.rectangle(CGRect(x: 350, y: 50, width: 40, height: 20))], VectorStyle(),
          layer: 1)
      ).first)
    try f.run(.transform([f.first], .init(translationX: 10, y: 0)))
    #expect(f.document.transformAgainCommand(for: [other], within: group) == nil)
    let outside = try #require(f.document.transformAgainCommand(for: [other]))
    let before = f.document.drawing
    #expect(throws: DrawingError.self) { try f.run(outside, within: group) }
    #expect(f.document.drawing == before)
    try f.repeatTransform([f.first], within: group)
    #expect(f.document.drawing.node(f.first)?.bounds.minX == 40)
    #expect(f.document.drawing.node(f.second) == before.node(f.second))
    try f.run(.lock(f.first, true))
    #expect(f.document.transformAgainCommand(for: [f.first]) == nil)
    let snapshot = f.document.drawing
    try await f.document.apply(snapshot: snapshot, previous: nil)
    #expect(f.document.transformAgainCommand(for: [f.second]) == nil)
  }

  @Test func areaFrameReflowClearsAffineHistoryInsteadOfRepeatingAStaleTransform() throws {
    let f = try Fixture()
    let text = try #require(
      try f.run(
        .addAreaText(
          "Frame text", CGRect(x: 20, y: 30, width: 100, height: 80), font: "Helvetica", size: 16,
          fill: VectorStyle.solid(0, 0, 0), layer: 1)
      ).first)
    try f.run(.transform([text], .init(translationX: 10, y: 0)))
    #expect(f.document.transformAgainCommand(for: [text]) != nil)
    try f.run(.resizeTextFrame(text, CGRect(x: 30, y: 30, width: 120, height: 80)))
    #expect(f.document.transformAgainCommand(for: [text]) == nil)
    #expect(
      f.document.drawing.node(text)?.raw["kind"]["runs"].array.first?["style"]["size"].double == 16)
  }

  @MainActor private final class Fixture {
    let document: CanvasDocument
    let first: Int64
    let second: Int64
    let undo = UndoManager()
    init() throws {
      var drawing = Drawing()
      first = try #require(
        try drawing.perform(
          .addPath(
            [ShapePaths.rectangle(CGRect(x: 20, y: 30, width: 40, height: 20))], VectorStyle(),
            layer: 1)
        ).first)
      second = try #require(
        try drawing.perform(
          .addPath(
            [ShapePaths.rectangle(CGRect(x: 200, y: 50, width: 40, height: 20))], VectorStyle(),
            layer: 1)
        ).first)
      for id in [first, second] {
        drawing.updateNode(id) { $0["unknown"]["keep"] = .string("retained") }
      }
      document = CanvasDocument(drawing: drawing)
      undo.groupsByEvent = false
    }
    @discardableResult
    func run(_ command: DrawingCommand, within isolation: Int64? = nil) throws -> Set<Int64> {
      undo.beginUndoGrouping()
      defer { undo.endUndoGrouping() }
      return try document.execute(command, undoManager: undo, within: isolation)
    }
    @discardableResult
    func repeatTransform(_ selection: Set<Int64>, within isolation: Int64? = nil) throws -> Set<
      Int64
    > {
      try run(
        #require(document.transformAgainCommand(for: selection, within: isolation)),
        within: isolation)
    }
  }
}
