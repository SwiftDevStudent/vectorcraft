import SwiftUI
import VectorCraftCore

struct NativeFileCommands: Commands {
  @Bindable var fileMenu: NativeFileMenuState
  @Environment(\.newDocument) private var newDocument
  @State private var svgImport = SVGFileImport()
  @FocusedValue(\.editorActions) private var editor
  var body: some Commands {
    CommandGroup(after: .newItem) {
      Button("New Screenshot Document") {
        do {
          var drawing = Drawing()
          try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
          let snapshot = drawing
          newDocument(CanvasDocument(drawing: snapshot))
        } catch { NSAlert(error: error).runModal() }
      }.accessibilityIdentifier("screenshots.newDocument")
      Button("Import SVG…") {
        svgImport.choose { drawing in newDocument(CanvasDocument(drawing: drawing)) }
      }.disabled(svgImport.isImporting)
      Menu("Open Recent") {
        ForEach(fileMenu.recentDocuments, id: \.self) { url in
          Button(url.lastPathComponent) { fileMenu.open(url) }
        }
        Divider()
        Button("Clear Menu") { fileMenu.clearRecent() }.disabled(fileMenu.recentDocuments.isEmpty)
      }
    }
    CommandGroup(replacing: .saveItem) {
      Button("Close") {
        NSApp.sendAction(NSSelectorFromString("performClose:"), to: nil, from: nil)
      }
      .keyboardShortcut("w", modifiers: .command)
      Button("Close All") {
        NSDocumentController.shared.closeAllDocuments(
          withDelegate: nil, didCloseAllSelector: nil, contextInfo: nil)
      }.keyboardShortcut("w", modifiers: [.command, .option])
        // Accessing the shared controller during menu construction preempts SwiftUI's controller.
        .disabled(editor == nil)
      Divider()
      Button("Save") { save(asNewFile: false) }.keyboardShortcut("s", modifiers: .command)
        .disabled(editor == nil)
      Button("Save As…") { save(asNewFile: true) }
        .keyboardShortcut("s", modifiers: [.command, .shift]).disabled(editor == nil)
      Button("Duplicate") { send("duplicateDocument:") }.disabled(editor == nil)
      Button("Rename…") { send("renameDocument:") }.disabled(editor == nil)
      Button("Move To…") { send("moveDocument:") }.disabled(editor == nil)
      Menu("Revert To") {
        Button("Last Saved") { send("revertDocumentToSaved:") }
        Button("Browse All Versions…") { send("browseDocumentVersions:") }
      }.disabled(editor == nil)
      Button("Share…") { fileMenu.share() }.disabled(editor == nil || !fileMenu.canShare)
    }
  }

  private func save(asNewFile: Bool) {
    guard let document = NSDocumentController.shared.currentDocument else { return }
    NativeDocumentSave().save(document, asNewFile: asNewFile)
  }
  private func send(_ action: String) {
    guard let document = NSDocumentController.shared.currentDocument else { return }
    NSApp.sendAction(NSSelectorFromString(action), to: document, from: nil)
  }
}
