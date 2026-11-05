import AppKit
import SwiftUI
import VectorCraftCore

struct ScreenshotThumbnail: View {
  let drawing: Drawing
  let board: ScreenshotBoard
  @Environment(ScreenshotDeviceLibrary.self) private var library
  @State private var image: NSImage?
  @State private var failed = false
  @State private var render: Task<Void, Never>?

  var body: some View {
    Group {
      if let image {
        Image(nsImage: image).resizable().scaledToFit()
      } else {
        Image(systemName: failed ? "exclamationmark.triangle" : "rectangle.portrait")
      }
    }.onAppear(perform: refresh)
      .onChange(of: drawing) { previous, current in
        if failed || ScreenshotPreview.isAffected(board: board.id, previous: previous, current: current) {
          refresh()
        }
      }
      .onChange(of: library.revision) { _, _ in refresh() }
      .onDisappear { render?.cancel() }
  }
  private func refresh() {
    render?.cancel()
    let snapshot = drawing
    let id = board.id
    render = Task(priority: .utility) {
      do {
        let bytes = try await library.previews.png(snapshot, board: id)
        guard !Task.isCancelled else { return }
        image = NSImage(data: bytes)
        failed = image == nil
      } catch is CancellationError {} catch {
        if !Task.isCancelled {
          image = nil
          failed = true
        }
      }
    }
  }
}
