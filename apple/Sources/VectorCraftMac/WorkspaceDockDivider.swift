import SwiftUI

struct WorkspaceDockDivider: View {
  @Bindable var state: EditorState
  @State private var dragOrigin: CGFloat?
  var body: some View {
    Rectangle().fill(WorkspaceTheme.border).frame(width: 2)
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0).onChanged { value in
          if dragOrigin == nil { dragOrigin = state.dockWidth }
          state.dockWidth = min(520, max(230, (dragOrigin ?? 300) - value.translation.width))
        }.onEnded { _ in dragOrigin = nil }
      )
      .accessibilityLabel("Properties Panel Width")
      .accessibilityAdjustableAction { direction in
        switch direction {
        case .increment: state.dockWidth = min(520, state.dockWidth + 20)
        case .decrement: state.dockWidth = max(230, state.dockWidth - 20)
        @unknown default: break
        }
      }
  }
}
