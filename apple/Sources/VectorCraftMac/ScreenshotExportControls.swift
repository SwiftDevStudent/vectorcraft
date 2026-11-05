import AppKit
import SwiftUI
import VectorCraftCore

struct ScreenshotExportControls: View {
  let drawing: Drawing
  @Bindable var state: EditorState
  @State private var task: Task<Void, Never>?
  @State private var exportedFolder: URL?

  var body: some View {
    HStack {
      Menu(task == nil ? "Export Used (\(drawing.includedScreenshotBoards.count))" : "Exporting…") {
        ForEach(ScreenshotExportFormat.allCases, id: \.self) { format in
          Button(format.rawValue.uppercased()) { export(format) }
        }
      }.disabled(task != nil || drawing.includedScreenshotBoards.isEmpty)
        .accessibilityIdentifier("screenshots.exportUsed")
      if let exportedFolder {
        Button("Show Export") { NSWorkspace.shared.open(exportedFolder) }
      }
    }.onDisappear { task?.cancel() }
  }

  private func export(_ format: ScreenshotExportFormat) {
    let panel = NSOpenPanel(); panel.canChooseFiles = false; panel.canChooseDirectories = true
    panel.canCreateDirectories = true; panel.prompt = "Export"
    guard panel.runModal() == .OK, let folder = panel.url else { return }
    let snapshot = drawing
    task = Task {
      let access = folder.startAccessingSecurityScopedResource()
      defer { if access { folder.stopAccessingSecurityScopedResource() }; task = nil }
      do { exportedFolder = try await ScreenshotExport.write(snapshot, format: format, to: folder) }
      catch is CancellationError {}
      catch { state.error = error.localizedDescription }
    }
  }
}
