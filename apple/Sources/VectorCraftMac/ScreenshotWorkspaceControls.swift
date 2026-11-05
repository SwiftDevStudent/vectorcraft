import AppKit
import SwiftUI
import UniformTypeIdentifiers
import VectorCraftCore

struct ScreenshotWorkspaceControls: View {
  var document: CanvasDocument
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  @Environment(ScreenshotDeviceLibrary.self) private var library
  @State private var template = "headline"
  @State private var language = "en-US"

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Menu("Add Row") {
            ForEach(ScreenshotPreset.all) { preset in
              Button(preset.name) {
                command(.screenshot(ScreenshotCommand(.addRow, preset: preset.id, template: template)))
                if let board = document.drawing.screenshotRows.last?.boards.first { select(board) }
              }.accessibilityIdentifier("screenshots.addRow.\(preset.id)")
            }
          }.accessibilityIdentifier("screenshots.addRow")
          Button("Fit Workspace") { state.canvasAction = .fitWorkspace }.accessibilityIdentifier("screenshots.fitWorkspace")
        }
        ScreenshotLayoutPicker(label: "New Slots", selection: template,
          artboard: CGRect(x: 0, y: 0, width: 1206, height: 2622),
          deviceSize: CGSize(width: 1206, height: 2622), identifier: "screenshots.template") {
          template = $0
        }
        TextField("Language", text: $language).onSubmit {
          command(.screenshot(ScreenshotCommand(.setLanguage, language: language)))
        }.accessibilityIdentifier("screenshots.language")
        ScreenshotExportControls(drawing: document.drawing, state: state)
        Toggle("Clip to Artboards", isOn: $state.clipScreenshotArtwork)
          .accessibilityIdentifier("screenshots.clipPreview")
      }.padding(12)
      WorkspaceSeparator()
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          if let board = document.drawing.screenshotBoard(at: state.selectedArtboard) {
            ScreenshotBoardControls(document: document, state: state, board: board,
              library: library, command: command, importScreenshot: importScreenshot)
            WorkspaceSeparator()
          }
          ForEach(document.drawing.screenshotRows) { row in
            ScreenshotRowControls(row: row, drawing: document.drawing,
              selected: document.drawing.screenshotBoard(at: state.selectedArtboard)?.id,
              select: select, add: { slot in
                command(.screenshot(ScreenshotCommand(.addBoard, row: row.id, template: template, slot: slot.index)))
              }, documentID: document.screenshotDragID, drop: drop, move: { id, slot in
                command(.screenshot(ScreenshotCommand(.moveBoard, row: row.id, board: id, slot: slot)))
              }, failed: { state.error = $0 })
            WorkspaceSeparator()
          }
        }.padding(12)
      }
    }.onAppear { refreshLanguage() }
      .onChange(of: document.drawing) { _, _ in refreshLanguage() }
  }
  private func select(_ board: ScreenshotBoard) {
    guard let index = document.drawing.artboardIndex(id: board.id) else { return }
    state.isolationStack = []; state.selection = []; state.selectedArtboard = index
    state.activeLayer = board.content; state.canvasAction = .fit
  }
  private func refreshLanguage() {
    language = document.drawing.envelope["document"]["unknown"]["screenshots"]["language"].string
    if language.isEmpty { language = "en-US" }
  }
  private func drop(_ items: [ScreenshotDropItem], target: ScreenshotSlot) -> Bool {
    do {
      command(try ScreenshotDropItem.command(items, document: document.screenshotDragID, target: target, template: template))
      return true
    } catch { state.error = error.localizedDescription; return false }
  }
  private func importScreenshot(_ board: ScreenshotBoard) {
    let panel = NSOpenPanel(); panel.allowedContentTypes = [.png, .jpeg]
    panel.canChooseDirectories = false; panel.allowsMultipleSelection = true
    guard panel.runModal() == .OK,
      let target = document.drawing.screenshotSlots.first(where: { $0.boardID == board.id }) else { return }
    do { _ = drop(try panel.urls.map(ScreenshotDropItem.image), target: target) }
    catch { state.error = error.localizedDescription }
  }
}
