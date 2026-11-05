import SwiftUI
import VectorCraftCore

struct WorkspaceQuickActions: View {
  var document: CanvasDocument
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  var editText: () -> Void
  var body: some View {
    Grid(horizontalSpacing: 6, verticalSpacing: 6) {
      GridRow {
        Button("Duplicate") { command(.duplicate(state.selection)) }
        Button("Bring to Front") { command(.arrange(state.selection, front: true)) }
      }
      GridRow {
        if state.selection.count == 1, let id = state.selection.first,
          document.drawing.node(id)?.type == "group"
        {
          Button("Ungroup") { command(.ungroup(id)) }
        } else {
          Button("Group") { command(.group(state.selection)) }.disabled(state.selection.count < 2)
        }
        Button("Send to Back") { command(.arrange(state.selection, front: false)) }
      }
      GridRow {
        Button("Lock") { for id in state.selection { command(.lock(id, true)) } }
        Button("Delete", role: .destructive) { command(.delete(state.selection)) }
      }
      if state.selection.count == 1, let id = state.selection.first,
        document.drawing.node(id)?.type == "text"
      {
        Button("Edit Text…", action: editText)
      }
    }.buttonStyle(WorkspaceButtonStyle(bordered: true))
  }
}
