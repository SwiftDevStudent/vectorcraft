import SwiftUI
import VectorCraftCore

/// Floating palettes share the exact controls and state of the docked workspace.
struct WorkspaceFloatingPanels: View {
  var document: CanvasDocument
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  var editText: () -> Void
  var body: some View {
    GeometryReader { geometry in
      if state.toolsFloating {
        WorkspaceToolStrip(state: state, command: command, editText: editText)
          .frame(height: max(100, min(650, geometry.size.height - state.toolsPosition.y - 48)))
          .modifier(FloatingPaletteStyle())
          .offset(x: state.toolsPosition.x, y: state.toolsPosition.y)
      }
      if state.propertiesFloating && state.inspectorPresented {
        WorkspaceDock(document: document, state: state, command: command, editText: editText)
          .frame(
            width: state.dockWidth,
            height: max(100, min(650, geometry.size.height - state.propertiesPosition.y - 48))
          )
          .modifier(FloatingPaletteStyle())
          .offset(x: state.propertiesPosition.x, y: state.propertiesPosition.y)
      }
    }
  }
}

struct FloatingPaletteStyle: ViewModifier {
  func body(content: Content) -> some View {
    content.background(WorkspaceTheme.panel).compositingGroup()
      .overlay(Rectangle().stroke(WorkspaceTheme.border))
      .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
  }
}
