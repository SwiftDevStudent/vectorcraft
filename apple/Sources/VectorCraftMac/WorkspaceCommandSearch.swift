import SwiftUI
import VectorCraftCore

struct WorkspaceCommandSearch: View {
  var document: CanvasDocument
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  var editText: () -> Void
  @Environment(\.dismiss) private var dismiss
  @FocusState private var focused: Bool
  private var tools: [EditorTool] {
    EditorTool.allCases.filter {
      state.commandQuery.isEmpty || $0.rawValue.localizedCaseInsensitiveContains(state.commandQuery)
    }
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        WorkspaceIcon(glyph: .search)
        TextField("Search Commands and Tools", text: $state.commandQuery).focused($focused)
          .textFieldStyle(.plain)
        Button("Cancel") { dismiss() }
      }
      WorkspaceSeparator()
      ScrollView {
        VStack(alignment: .leading, spacing: 6) {
          ForEach(tools) { tool in
            Button {
              state.tool = tool
              dismiss()
            } label: {
              HStack {
                WorkspaceIcon(glyph: tool.workspaceGlyph)
                Text(tool.rawValue)
                Spacer()
              }
            }.buttonStyle(WorkspaceButtonStyle())
          }
          if matches("Edit Text") {
            Button("Edit Text…") {
              dismiss()
              editText()
            }
          }
          if matches("Duplicate") {
            Button("Duplicate") {
              command(.duplicate(state.selection))
              dismiss()
            }.disabled(state.selection.isEmpty)
          }
          if matches("Transform Again") {
            Button("Transform Again") {
              if let value = document.transformAgainCommand(
                for: state.selection, within: state.isolationID)
              {
                command(value)
              }
              dismiss()
            }.disabled(
              state.textEditingSession != nil
                || document.transformAgainCommand(for: state.selection, within: state.isolationID)
                  == nil
            )
          }
          ForEach(TransformDialogKind.allCases.filter { matches($0.rawValue) }) { kind in
            Button("\(kind.rawValue)…") {
              state.pendingTransformDialog = kind
              dismiss()
            }.disabled(!state.canTransform(in: document.drawing))
          }
          if matches("Enter Isolation") {
            Button("Enter Isolation") {
              if let id = state.selection.first { state.enterIsolation(id, in: document.drawing) }
              dismiss()
            }.disabled(!state.canEnterIsolation(in: document.drawing))
          }
          if matches("Exit Isolation") {
            Button("Exit Isolation") {
              state.exitIsolation(in: document.drawing)
              dismiss()
            }.disabled(state.isolationID == nil)
          }
          ForEach(PathfinderOperation.allCases.filter { matches($0.rawValue) }, id: \.rawValue) {
            operation in
            Button(operation.rawValue) {
              command(.pathfinder(state.selection, operation))
              dismiss()
            }.disabled(!document.drawing.canUsePathfinder(state.selection))
          }
          if matches("Make Compound Path") {
            Button("Make Compound Path") {
              command(.makeCompound(state.selection))
              dismiss()
            }.disabled(!document.drawing.canMakeCompound(state.selection))
          }
          if matches("Release Compound Path") {
            Button("Release Compound Path") {
              command(.releaseCompound(state.selection))
              dismiss()
            }.disabled(!document.drawing.canReleaseCompound(state.selection))
          }
          if matches("Fit Artboard") {
            Button("Fit Artboard") {
              state.canvasAction = .fit
              dismiss()
            }
          }
          if matches("New Layer") {
            Button("New Layer") {
              command(.addLayer)
              dismiss()
            }.disabled(state.isolationID != nil)
          }
        }
      }
    }.font(WorkspaceTheme.font).padding(16).frame(minWidth: 360, minHeight: 280)
      .onAppear { focused = true }
  }
  private func matches(_ label: String) -> Bool {
    state.commandQuery.isEmpty || label.localizedCaseInsensitiveContains(state.commandQuery)
  }
}
