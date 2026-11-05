import SwiftUI
import VectorCraftCore

enum WorkspaceDockTab: String {
  case properties = "Properties"
  case layers = "Layers"
  case screenshots = "Screenshots"
}

struct WorkspaceDock: View {
  var document: CanvasDocument
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  var editText: () -> Void
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        WorkspaceDragHandle(state: state, panel: .properties)
        Button {
          state.inspectorPresented = false
        } label: {
          WorkspaceIcon(glyph: .chevronsRight, size: 10)
        }
        .buttonStyle(.plain).accessibilityLabel("Collapse Properties Panel")
      }.padding(.horizontal, 6).frame(height: 14).background(WorkspaceTheme.tabStrip)
      HStack(spacing: 0) {
        ForEach([WorkspaceDockTab.properties, .layers, .screenshots], id: \.self) { tab in
          Button {
            state.dockTab = tab
          } label: {
            Text(tab.rawValue).font(
              state.dockTab == tab ? WorkspaceTheme.semibold : WorkspaceTheme.font
            )
            .padding(.horizontal, 12).frame(height: 33)
            .background(state.dockTab == tab ? WorkspaceTheme.panel : WorkspaceTheme.tabStrip)
          }.buttonStyle(.plain).accessibilityAddTraits(state.dockTab == tab ? .isSelected : [])
          Rectangle().fill(WorkspaceTheme.border).frame(width: 1)
        }
        Spacer(minLength: 0)
      }.frame(height: 33).background(WorkspaceTheme.tabStrip)
      WorkspaceSeparator()
      if state.dockTab == .properties {
        StyleInspectorView(document: document, state: state, command: command, editText: editText)
      } else if state.dockTab == .screenshots {
        ScreenshotWorkspaceControls(document: document, state: state, command: command)
      } else {
        LayersSidebar(document: document, state: state, command: command)
      }
    }.frame(maxHeight: .infinity, alignment: .top)
      .background(WorkspaceTheme.panel)
  }
}
