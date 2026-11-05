import SwiftUI
import VectorCraftCore

struct WorkspaceContextOverlay: View {
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void

  var body: some View {
    GeometryReader { geometry in
      if !state.selection.isEmpty, state.tool != .pen, state.textEditingSession == nil,
        let selected = state.selectionInCanvas
      {
        let width = min(380, max(0, geometry.size.width - 16))
        let x = min(max(selected.midX, width / 2 + 8), geometry.size.width - width / 2 - 8)
        let below = selected.maxY + 34
        let y = below < geometry.size.height - 24 ? below : max(24, selected.minY - 34)
        WorkspaceContextBar(state: state, command: command)
          .frame(width: width).position(x: x, y: min(y, geometry.size.height - 24))
      }
    }
  }
}
