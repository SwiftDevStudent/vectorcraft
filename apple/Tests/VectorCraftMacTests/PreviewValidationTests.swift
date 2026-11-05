import CoreGraphics
import Foundation
import Testing
@testable import VectorCraftCore
@testable import VectorCraftMac

@MainActor
struct PreviewValidationTests {
  @Test func previewLimitationsFollowNativeEditsUndoAndLoadedSnapshots() async throws {
    var drawing = Drawing()
    let ids = try drawing.perform(.addPath([ShapePaths.rectangle(CGRect(x: 10, y: 10, width: 20, height: 20))],
      VectorStyle(), layer: 1))
    let id = try #require(ids.first)
    drawing.updateNode(id) { $0["blend"] = .string("Multiply") }
    let document = CanvasDocument(drawing: drawing), undo = UndoManager()
    undo.groupsByEvent = false
    #expect(document.renderingWarnings == ["blend modes"])
    undo.beginUndoGrouping()
    try document.execute(.delete([id]), undoManager: undo)
    undo.endUndoGrouping()
    #expect(document.renderingWarnings.isEmpty)
    undo.undo(); #expect(document.renderingWarnings == ["blend modes"])
    undo.redo(); #expect(document.renderingWarnings.isEmpty)
    try await document.apply(snapshot: drawing, previous: nil)
    #expect(document.renderingWarnings == ["blend modes"])
    document.drawing.updateNode(id) { $0["blend"] = .string("Normal") }
    #expect(document.renderingWarnings.isEmpty)
  }
}
