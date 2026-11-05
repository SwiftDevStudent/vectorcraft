import AppKit
import VectorCraftCore

/// A canvas owns its serial image preparation and discards work when its target changes.
@MainActor
final class CanvasBitmapPaste {
  private weak var view: VectorCanvasView?
  private let decoder = ClipboardBitmapDecoder()
  private(set) var task: Task<Void, Never>?

  init(view: VectorCanvasView) { self.view = view }

  func start(_ data: Data, placement: PastePlacement) {
    cancel()
    guard let view else { return }
    let original = view.drawing, state = view.state
    let isolation = state.isolationID, artboard = state.selectedArtboard
    let container = state.insertionContainer(in: original), selection = state.selection
    let decoder = decoder
    task = Task(priority: .utility) { [weak self] in
      do {
        let fragment = try await decoder.prepare(data)
        guard !Task.isCancelled, let self, let view = self.view else { return }
        defer { task = nil }
        guard view.state === state, view.artworkClipboardReady,
          view.drawing == original, state.isolationID == isolation,
          state.selectedArtboard == artboard,
          state.insertionContainer(in: view.drawing) == container
        else {
          state.error = "The paste target changed while preparing the image. Paste again."
          return
        }
        try view.applyClipboard(.paste(fragment, placement, container: container, relativeTo: selection))
      } catch {
        guard !Task.isCancelled, let self, let view = self.view else { return }
        task = nil
        view.state.error = error.localizedDescription
      }
    }
  }

  func cancel() {
    task?.cancel()
    task = nil
  }
}

private actor ClipboardBitmapDecoder {
  func prepare(_ data: Data) throws -> VectorFragment {
    try Task.checkCancellation()
    return try VectorFragment(bitmapData: data)
  }
}
