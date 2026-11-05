import SwiftUI
import VectorCraftCore

struct EditorCommands: Commands {
  var fileMenu: NativeFileMenuState
  @FocusedValue(\.editorActions) private var editor
  var body: some Commands {
    NativeFileCommands(fileMenu: fileMenu)
    CommandGroup(after: .importExport) {
      Menu("Export") {
        Button("Export SVG…") { editor?.export(.svg) }
        Button("Export PNG…") { editor?.export(.png) }
        Button("Export PDF…") { editor?.export(.pdf) }
      }.disabled(editor?.exportEnabled != true)
    }
    CommandGroup(after: .pasteboard) {
      Button("Paste in Place") {
        ArtworkClipboardAction.perform(#selector(VectorCanvasView.pasteInPlace(_:)))
      }
      .keyboardShortcut("v", modifiers: [.command, .shift])
      .disabled(editor?.editingText != false || editor?.canvasHasFocus != true)
      Button("Paste in Front") {
        ArtworkClipboardAction.perform(#selector(VectorCanvasView.pasteInFront(_:)))
      }
      .keyboardShortcut("f", modifiers: .command)
      .disabled(editor?.editingText != false || editor?.canvasHasFocus != true)
      Button("Paste in Back") {
        ArtworkClipboardAction.perform(#selector(VectorCanvasView.pasteInBack(_:)))
      }
      .keyboardShortcut("b", modifiers: .command)
      .disabled(editor?.editingText != false || editor?.canvasHasFocus != true)
      Divider()
      Button("Duplicate") { if let editor { editor.command(.duplicate(editor.selected)) } }
        .disabled(
          editor?.selected.isEmpty != false || editor?.editingText == true)
      Button("Delete") { editor?.deleteSelection() }
        .keyboardShortcut(.delete, modifiers: []).disabled(
          editor?.selected.isEmpty != false || editor?.editingText == true)
    }
    CommandMenu("Insert") {
      Button("Rectangle") { editor?.insertShape(.rectangle) }
      Button("Ellipse") { editor?.insertShape(.ellipse) }
      Button("Star") { editor?.insertShape(.star) }
      Button("Text…") { editor?.editText() }.keyboardShortcut("t", modifiers: [.command, .shift])
    }
    CommandMenu("Object") {
      Button("Edit Text…") { editor?.editText() }
      Divider()
      Button("Enter Isolation") { editor?.enterIsolation() }
        .disabled(editor?.canIsolate != true)
      Button("Exit Isolation") { editor?.exitIsolation() }
        .disabled(editor?.isIsolating != true)
      Menu("Transform") {
        Button("Transform Again") { editor?.transformAgain() }
          .keyboardShortcut("d", modifiers: .command)
          .disabled(editor?.canTransformAgain != true)
        Divider()
        Button("Transform Each…") { editor?.showTransform(.each) }
          .keyboardShortcut("d", modifiers: [.command, .option, .shift])
          .disabled(editor?.canTransform != true)
        Button("Reflect…") { editor?.showTransform(.reflect) }.disabled(
          editor?.canTransform != true)
        Button("Shear…") { editor?.showTransform(.shear) }.disabled(editor?.canTransform != true)
      }
      Divider()
      Button("Group") { if let editor { editor.command(.group(editor.selected)) } }
        .keyboardShortcut("g", modifiers: .command).disabled((editor?.selected.count ?? 0) < 2)
      Button("Ungroup") {
        if let editor, let id = editor.selected.first { editor.command(.ungroup(id)) }
      }
      .keyboardShortcut("g", modifiers: [.command, .shift]).disabled(editor?.selected.count != 1)
      Menu("Pathfinder") {
        ForEach(PathfinderOperation.allCases, id: \.rawValue) { operation in
          Button(operation.rawValue) {
            if let editor { editor.command(.pathfinder(editor.selected, operation)) }
          }
        }
      }.disabled(editor.map { !$0.drawing.canUsePathfinder($0.selected) || $0.editingText } ?? true)
      Menu("Compound Path") {
        Button("Make") { if let editor { editor.command(.makeCompound(editor.selected)) } }
          .keyboardShortcut("8", modifiers: .command)
          .disabled(
            editor.map { !$0.drawing.canMakeCompound($0.selected) || $0.editingText } ?? true)
        Button("Release") { if let editor { editor.command(.releaseCompound(editor.selected)) } }
          .keyboardShortcut("8", modifiers: [.command, .option, .shift])
          .disabled(
            editor.map { !$0.drawing.canReleaseCompound($0.selected) || $0.editingText } ?? true)
      }
      Divider()
      Button("Bring to Front") {
        if let editor { editor.command(.arrange(editor.selected, front: true)) }
      }
      Button("Send to Back") {
        if let editor { editor.command(.arrange(editor.selected, front: false)) }
      }
    }
    CommandMenu("Tools") {
      Group {
        Button("Selection") { editor?.selectTool(.select) }.keyboardShortcut("v", modifiers: [])
        Button("Node Editing") { editor?.selectTool(.nodes) }.keyboardShortcut("a", modifiers: [])
        Button("Pen") { editor?.selectTool(.pen) }.keyboardShortcut("p", modifiers: [])
        Button("Pencil") { editor?.selectTool(.pencil) }.keyboardShortcut("n", modifiers: [])
        Button("Rectangle") { editor?.selectTool(.rectangle) }.keyboardShortcut("r", modifiers: [])
        Button("Ellipse") { editor?.selectTool(.ellipse) }.keyboardShortcut("o", modifiers: [])
        Button("Hand") { editor?.selectTool(.hand) }.keyboardShortcut("h", modifiers: [])
        Button("Type") { editor?.selectTool(.text) }.keyboardShortcut("t", modifiers: [])
        Button("Gradient") { editor?.selectTool(.gradient) }.keyboardShortcut("g", modifiers: [])
      }.disabled(editor?.editingText == true)
    }
    CommandGroup(after: .toolbar) {
      Button("Fit Artboard") { editor?.fit() }.keyboardShortcut("0", modifiers: .command)
      Button("Search Commands and Tools") { editor?.search() }.keyboardShortcut(
        "k", modifiers: .command)
      Button("Pathfinder") { editor?.openPathfinder() }
      Button("Gradient") { editor?.openGradient() }
    }
  }
}
