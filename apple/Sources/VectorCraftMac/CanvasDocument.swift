import SwiftUI
import UniformTypeIdentifiers
import VectorCraftCore

extension UTType {
  static let vectorcraft = UTType(
    exportedAs: "com.swiftdev.vectorcraft.document", conformingTo: .data)
  static let drawcraft = UTType(importedAs: "com.swiftdev.drawcraft.document", conformingTo: .data)
}

@MainActor @Observable
final class CanvasDocument: Document {
  nonisolated static let readableContentTypes: [UTType] = [.vectorcraft, .drawcraft]
  nonisolated static let writableContentTypes: [UTType] = [.vectorcraft, .drawcraft]
  var drawing = Drawing() {
    didSet {
      if drawing != oldValue { refreshRenderingWarnings() }
    }
  }
  private(set) var renderingWarnings: [String] = []
  /// Scope local slot drags so equal numeric IDs in another document cannot move its artwork.
  @ObservationIgnored let screenshotDragID = UUID()
  private enum RepeatedTransform {
    case affine(CGAffineTransform, copy: Bool)
    case individual(IndividualTransform, copy: Bool)
  }
  private var lastTransform: RepeatedTransform?
  @ObservationIgnored private var textUndoSession: UUID?
  nonisolated init(drawing: Drawing = Drawing()) {
    // Initialize Observation's stored value before the fresh document transfers to its owner.
    _drawing = drawing
    _renderingWarnings = drawing.renderingWarnings
  }

  func refreshRenderingWarnings() { renderingWarnings = drawing.renderingWarnings }

  nonisolated func reader(configuration: sending ReadConfiguration) -> sending NativeDocumentReader
  { NativeDocumentReader() }
  func apply(snapshot: sending Drawing, previous: sending Drawing?) async throws {
    lastTransform = nil
    drawing = snapshot
  }
  nonisolated func writer(configuration: sending WriteConfiguration)
    -> sending FileWrapperDocumentWriter<Drawing>
  {
    FileWrapperDocumentWriter(configuration) { drawing, _ in
      FileWrapper(regularFileWithContents: try NativeFormat.encode(drawing))
    }
  }
  func snapshot(contentType: UTType) async throws -> sending Drawing { drawing }

  @discardableResult
  func execute(
    _ command: DrawingCommand, undoManager: UndoManager?, coalescingTextSession: UUID? = nil,
    within isolation: Int64? = nil
  ) throws -> Set<Int64> {
    var next = drawing
    let selection = try next.perform(command, within: isolation)
    guard next != drawing else { return selection }
    let session: UUID?
    switch command {
    case .addText, .addAreaText, .editText: session = coalescingTextSession
    default: session = nil
    }
    if let session, textUndoSession == session {
      drawing = next
    } else {
      replace(next, undoManager: undoManager, label: command.label)
    }
    textUndoSession = session
    switch command {
    case .transform(_, let matrix, let copy):
      if !matrix.isIdentity || copy { lastTransform = .affine(matrix, copy: copy) }
    case .transformEach(_, let values, let copy):
      if !values.isIdentity || copy { lastTransform = .individual(values, copy: copy) }
    case .resizeTextFrame: lastTransform = nil
    default: break
    }
    return selection
  }

  func transformAgainCommand(
    for selection: Set<Int64>, within isolation: Int64? = nil
  ) -> DrawingCommand? {
    guard let lastTransform, !selection.isEmpty,
      selection.allSatisfy({
        drawing.canEdit($0) && drawing.isInside($0, isolation: isolation)
          && drawing.node($0)?.type != "layer"
      })
    else { return nil }
    switch lastTransform {
    case .affine(let matrix, let copy): return .transform(selection, matrix, copy: copy)
    case .individual(let values, let copy): return .transformEach(selection, values, copy: copy)
    }
  }

  private func replace(_ next: Drawing, undoManager: UndoManager?, label: String) {
    textUndoSession = nil
    let previous = drawing
    undoManager?.registerUndo(withTarget: self) { document in
      MainActor.assumeIsolated {
        document.replace(previous, undoManager: undoManager, label: label)
      }
    }
    undoManager?.setActionName(label)
    drawing = next
  }
}
