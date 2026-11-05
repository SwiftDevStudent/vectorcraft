import SwiftUI
import VectorCraftCore

struct WorkspacePanelContent: View {
  var panel: WorkspacePanel
  var document: CanvasDocument
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  var editText: () -> Void
  @Environment(\.undoManager) private var undoManager
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(panel.rawValue).fontWeight(.semibold)
        Spacer()
        Button {
          state.openPanel = nil
        } label: {
          WorkspaceIcon(glyph: .chevronsRight, size: 12)
        }
        .buttonStyle(.plain).accessibilityLabel("Close Panel")
      }
      WorkspaceSeparator()
      switch panel {
      case .color, .stroke, .transparency, .appearance:
        WorkspaceAppearanceControls(state: state, command: command)
      case .transform:
        WorkspaceTransformControls(document: document, state: state, command: command)
      case .align: WorkspaceAlignControls(state: state, command: command)
      case .pathfinder:
        WorkspacePathfinderControls(document: document, state: state, command: command)
      case .gradient:
        WorkspaceGradientControls(document: document, state: state, command: command)
      case .artboards: WorkspaceArtboardControls(document: document, state: state, command: command)
      case .character:
        WorkspaceCharacterControls(document: document, state: state, command: command)
        Button("Edit Text…", action: editText).buttonStyle(WorkspaceButtonStyle(bordered: true))
          .disabled(state.selection.count != 1)
      case .history:
        Button("Undo \(undoManager?.undoActionName ?? "")") { undoManager?.undo() }
          .disabled(undoManager?.canUndo != true)
        Button("Redo \(undoManager?.redoActionName ?? "")") { undoManager?.redo() }
          .disabled(undoManager?.canRedo != true)
        Text("\(document.drawing.layers.count) Layers").foregroundStyle(WorkspaceTheme.dim)
      case .info:
        Text(document.drawing.title)
        Text("\(document.drawing.artboards.count) Artboards")
        if let pointer = state.pointer {
          Text(
            "X: \(pointer.x, format: .number.precision(.fractionLength(0...2))) pt  Y: \(pointer.y, format: .number.precision(.fractionLength(0...2))) pt"
          )
        }
      case .navigator:
        Button("Fit Artboard") { state.canvasAction = .fit }
        Button("Actual Size") { state.canvasAction = .actualSize }
        Picker("Artboard", selection: $state.selectedArtboard) {
          ForEach(Array(document.drawing.artboards.enumerated()), id: \.offset) { index, _ in
            Text("Artboard \(index + 1)").tag(index)
          }
        }
      default: EmptyView()
      }
    }.font(WorkspaceTheme.font).foregroundStyle(WorkspaceTheme.text).padding(12)
      .frame(width: 256).background(WorkspaceTheme.panel).preferredColorScheme(.dark)
  }
}
