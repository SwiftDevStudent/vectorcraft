import SwiftUI
import VectorCraftCore

struct StyleInspectorView: View {
  var document: CanvasDocument
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  var editText: () -> Void
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        Text(selectionLabel).foregroundStyle(WorkspaceTheme.dim)
        if state.selection.isEmpty {
          Text("Document").foregroundStyle(WorkspaceTheme.dim)
          WorkspaceArtboardControls(document: document, state: state, command: command)
        } else {
          Text("Transform").foregroundStyle(WorkspaceTheme.dim)
          WorkspaceTransformControls(document: document, state: state, command: command)
          WorkspaceSeparator().padding(.vertical, 2)
          Text("Appearance").foregroundStyle(WorkspaceTheme.dim)
          WorkspaceAppearanceControls(state: state, command: command)
          if state.selection.count == 1, let id = state.selection.first,
            document.drawing.node(id)?.type == "text"
          {
            WorkspaceSeparator().padding(.vertical, 2)
            Text("Character").foregroundStyle(WorkspaceTheme.dim)
            WorkspaceCharacterControls(document: document, state: state, command: command)
          }
          WorkspaceSeparator().padding(.vertical, 2)
          Text("Align").foregroundStyle(WorkspaceTheme.dim)
          WorkspaceAlignControls(state: state, command: command)
          WorkspaceSeparator().padding(.vertical, 2)
          Text("Quick Actions").foregroundStyle(WorkspaceTheme.dim)
          WorkspaceQuickActions(
            document: document, state: state, command: command, editText: editText)
          if state.tool == .nodes {
            WorkspaceSeparator()
            WorkspaceNodeControls(document: document, state: state, command: command)
          }
        }
      }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
    }
  }
  private var selectionLabel: String {
    if state.selection.isEmpty { return "Document" }
    if state.selection.count > 1 { return "\(state.selection.count) Objects" }
    return state.selection.first.flatMap(document.drawing.node)?.type.capitalized ?? "Selection"
  }
}
