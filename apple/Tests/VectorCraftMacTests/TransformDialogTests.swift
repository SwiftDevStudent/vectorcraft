import AppKit
import Testing
import VectorCraftCore

@testable import VectorCraftMac

@MainActor
struct TransformDialogTests {
  @Test func previewCancelAndCopyUseTheSameCommandWithoutSavingPreviewState() throws {
    let f = try Fixture()
    let original = f.document.drawing
    f.state.presentTransform(.each, in: original)
    let session = try #require(f.state.transformDialog)
    session.settings.individual.scaleX = 50
    session.settings.individual.moveY = 20
    session.refresh()
    let preview = try #require(f.state.transformPreview(in: original))
    #expect(preview.drawing.node(f.a)?.bounds == CGRect(x: 45, y: 50, width: 50, height: 80))
    #expect(f.document.drawing == original && !f.undo.canUndo)
    #expect(
      try NativeFormat.decode(NativeFormat.encode(f.document.drawing)).envelope["document"]
        == original.envelope["document"])
    session.previewEnabled = false
    session.refresh()
    #expect(f.state.transformPreview(in: original) == nil)
    f.state.transformDialog = nil
    #expect(f.state.transformPreview(in: original) == nil && f.document.drawing == original)
    let copied = try f.run(session.command(copy: true, in: original))
    #expect(copied.count == 2 && copied.isDisjoint(with: f.state.selection))
    #expect(f.document.drawing.node(f.a) == original.node(f.a))
    let saved = f.document.drawing
    f.undo.undo()
    #expect(f.document.drawing == original)
    f.undo.redo()
    #expect(f.document.drawing == saved)
    let repeatCommand = try #require(f.document.transformAgainCommand(for: copied))
    let repeated = try f.run(repeatCommand)
    #expect(Set(repeated.compactMap { f.document.drawing.node($0)?.bounds.width }) == [25, 10])
  }

  @Test func eachRepetitionUsesTheNewObjectsOwnReferencesAndLeavesCopiesUnmodified() throws {
    let f = try Fixture()
    let session = TransformDialogSession(
      kind: .each, drawing: f.document.drawing, selection: [f.a], isolation: nil)
    session.settings.individual.scaleX = 50
    session.refresh()
    try f.run(session.command(copy: false, in: f.document.drawing))
    let command = try #require(f.document.transformAgainCommand(for: [f.b]))
    try f.run(command)
    #expect(f.document.drawing.node(f.b)?.bounds == CGRect(x: 310, y: 200, width: 20, height: 20))
  }

  @Test func reflectAndShearPreviewCommitAndAffineRepeatPreserveTextAndForeignData() throws {
    let f = try Fixture()
    let session = TransformDialogSession(
      kind: .reflect, drawing: f.document.drawing, selection: [f.a], isolation: nil)
    session.settings.individual.reference = .left
    session.refresh()
    let reflected = try #require(session.preview?.drawing.node(f.a)?.bounds)
    #expect(abs(reflected.minX + 80) < 0.000001)
    try f.run(session.command(copy: false, in: f.document.drawing))
    #expect(f.document.drawing.node(f.a)?.raw["unknown"]["keep"].string == "source")
    let shear = TransformDialogSession(
      kind: .shear, drawing: f.document.drawing, selection: [f.b], isolation: nil)
    shear.settings.shearAngle = 45
    shear.refresh()
    let before = f.document.drawing
    let id = try #require(try f.run(shear.command(copy: true, in: before)).first)
    #expect(f.document.drawing.node(f.b) == before.node(f.b))
    let bounds = try #require(f.document.drawing.node(id)?.bounds)
    #expect(abs(bounds.minX - 290) < 0.000001 && abs(bounds.width - 60) < 0.000001)
    #expect(f.document.transformAgainCommand(for: [id]) != nil)
    let text = try #require(
      try f.run(
        .addText(
          "Mirror text", CGPoint(x: 100, y: 300), font: "Helvetica", size: 16,
          fill: VectorStyle.solid(0, 0, 0), layer: 1)
      ).first)
    let textBefore = try #require(f.document.drawing.node(text))
    let textSession = TransformDialogSession(
      kind: .reflect, drawing: f.document.drawing, selection: [text], isolation: nil)
    let textCopy = try #require(
      try f.run(textSession.command(copy: true, in: f.document.drawing)).first)
    let mirrored = try #require(f.document.drawing.node(textCopy))
    #expect(f.document.drawing.node(text) == textBefore)
    #expect(mirrored.raw["kind"]["runs"] == textBefore.raw["kind"]["runs"])
    let matrix = try #require(mirrored.raw["kind"]["xf"].affine)
    #expect(matrix.a * matrix.d - matrix.b * matrix.c < 0)
    let canvas = VectorCanvasView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
    canvas.update(drawing: f.document.drawing, state: f.state) { _ in
      Issue.record("Protected text must not be edited.")
    }
    canvas.beginTextEditing(id: textCopy)
    #expect(canvas.textEditor == nil && f.state.error != nil)
    #expect(f.document.drawing.node(textCopy) == mirrored)
    _ = try SVGExport.encode(f.document.drawing)
    _ = try PDFExport.encode(f.document.drawing)
  }

  @Test func invalidAndStaleDialogResultsCannotMutateOrLeakIntoTheCanvas() throws {
    let f = try Fixture()
    f.state.presentTransform(.shear, in: f.document.drawing)
    let session = try #require(f.state.transformDialog)
    session.settings.shearAngle = 90
    session.refresh()
    #expect(session.error != nil && session.preview == nil && !f.undo.canUndo)
    session.settings.shearAngle = 30
    session.refresh()
    let original = f.document.drawing
    try f.run(.transform([f.a], .init(translationX: 10, y: 0)))
    #expect(f.state.transformPreview(in: f.document.drawing) == nil)
    #expect(throws: DrawingError.self) { try session.command(copy: false, in: f.document.drawing) }
    #expect(f.document.drawing.node(f.a)?.bounds.minX == 30)
    #expect(original.node(f.a)?.bounds.minX == 20)
    f.state.textEditingSession = UUID()
    #expect(!f.state.canTransform(in: f.document.drawing))
  }

  @MainActor private final class Fixture {
    let document: CanvasDocument
    let state = EditorState()
    let undo = UndoManager()
    let a: Int64, b: Int64
    init() throws {
      var drawing = Drawing()
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
      document = CanvasDocument(drawing: drawing)
      state.selection = [a, b]
      undo.groupsByEvent = false
    }
    @discardableResult
    func run(_ command: DrawingCommand) throws -> Set<Int64> {
      undo.beginUndoGrouping()
      defer { undo.endUndoGrouping() }
      return try document.execute(command, undoManager: undo)
    }
  }
}
