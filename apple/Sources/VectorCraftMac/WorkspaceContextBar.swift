import SwiftUI
import VectorCraftCore

struct WorkspaceContextBar: View {
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  var body: some View {
    ViewThatFits(in: .horizontal) {
      controls(compact: false)
      controls(compact: true)
    }
  }

  private func controls(compact: Bool) -> some View {
    HStack(spacing: 6) {
      Rectangle().fill(WorkspaceTheme.disabled).frame(width: 3, height: 24)
      if !compact {
        Button("Offset Path") {}.disabled(true).help(
          "Offset Path is not yet available in the Swift port")
        Button("Simplify") {}.disabled(true).help("Simplify is not yet available in the Swift port")
      }
      Button {
        command(.duplicate(state.selection))
      } label: {
        HStack {
          WorkspaceIcon(glyph: .duplicate, size: 16)
          Text("Duplicate")
        }
      }
      Rectangle().fill(state.fillColor).frame(width: 18, height: 18)
      Button {
        for id in state.selection { command(.lock(id, true)) }
      } label: {
        WorkspaceIcon(glyph: .lock, size: 16)
      }.accessibilityLabel("Lock Selection")
    }.buttonStyle(WorkspaceButtonStyle(bordered: true))
      .font(WorkspaceTheme.font).padding(6).background(WorkspaceTheme.panel)
      .overlay(RoundedRectangle(cornerRadius: 5).stroke(WorkspaceTheme.border))
      .clipShape(RoundedRectangle(cornerRadius: 5)).shadow(
        color: .black.opacity(0.25), radius: 5, y: 3
      )
      .fixedSize(horizontal: true, vertical: false)
  }
}
