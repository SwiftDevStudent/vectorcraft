import AppKit
import Testing
import VectorCraftCore

@testable import VectorCraftMac

@MainActor
struct NativeV4DocumentTests {
  @Test func nativeDocumentEditsUndoAndSnapshotPreserveV4Resources() async throws {
    var initial = Drawing()
    let id = try #require(
      try initial.perform(
        .addPath(
          [ShapePaths.rectangle(CGRect(x: 10, y: 20, width: 50, height: 60))],
          VectorStyle(), layer: 1)
      ).first)
    let resource = Data((0..<12_000).map { UInt8(truncatingIfNeeded: $0 * 19) })
    initial.envelope["images"]["opaque"] = .object([
      "mime": .string("application/octet-stream"), "data": .string(resource.base64EncodedString()),
    ])
    initial = try NativeFormat.decode(NativeFormat.encode(initial))
    let document = CanvasDocument(drawing: initial)
    let undo = UndoManager()
    undo.groupsByEvent = false
    undo.beginUndoGrouping()
    try document.execute(
      .transform([id], CGAffineTransform(translationX: 11, y: 12)), undoManager: undo)
    undo.endUndoGrouping()
    #expect(document.drawing.node(id)?.bounds.origin == CGPoint(x: 21, y: 32))
    undo.undo()
    #expect(document.drawing == initial)
    undo.redo()
    let snapshot = try await document.snapshot(contentType: .vectorcraft)
    let reopened = try NativeFormat.decode(NativeFormat.encode(snapshot))
    #expect(reopened.version == 4 && reopened.nativeBlobData == resource)
    #expect(reopened.envelope["document"] == snapshot.envelope["document"])
    #expect(reopened.envelope["images"] == initial.envelope["images"])
  }
}
