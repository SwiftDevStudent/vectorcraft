import SwiftUI

@main
struct VectorCraftApp: App {
  init() { WorkspaceFonts.register() }
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  var body: some Scene {
    DocumentGroup { document in
      EditorView(document: document)
    } makeDocument: { _, _ in
      CanvasDocument()
    }
    .commands {
      EditorCommands(fileMenu: appDelegate.fileMenu)
    }
    .windowStyle(.hiddenTitleBar)
    .defaultSize(width: 1470, height: 923)
  }
}
