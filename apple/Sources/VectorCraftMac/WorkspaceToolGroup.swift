import SwiftUI

struct WorkspaceToolGroup: View {
  @Bindable var state: EditorState
  var name: String
  var slots: [WorkspaceToolSlot]
  private var columns: [GridItem] {
    Array(repeating: GridItem(.fixed(36), spacing: 0), count: state.toolbarDouble ? 2 : 1)
  }

  var body: some View {
    VStack(spacing: 0) {
      Text(name).font(WorkspaceTheme.smallFont).foregroundStyle(WorkspaceTheme.text)
        .frame(height: 18)
      LazyVGrid(columns: columns, spacing: 1) {
        ForEach(slots) { slot in
          let shown = slot.alternatives.contains(state.tool) ? state.tool : slot.tool
          Button {
            if let shown { state.tool = shown }
          } label: {
            WorkspaceIcon(glyph: shown?.workspaceGlyph ?? slot.glyph)
              .frame(width: 27, height: 21)
              .overlay(alignment: .bottomTrailing) {
                if !slot.alternatives.isEmpty {
                  Image(systemName: "arrowtriangle.down.fill").font(.system(size: 4))
                }
              }
          }.buttonStyle(WorkspaceButtonStyle(active: shown != nil && state.tool == shown))
            .disabled(slot.tool == nil)
            .accessibilityLabel(shown?.rawValue ?? slot.label)
            .help(
              slot.tool == nil ? "\(slot.label) is not yet available in the Swift port" : slot.label
            )
            .contextMenu {
              ForEach(slot.alternatives) { tool in
                Button(tool.rawValue) { state.tool = tool }
              }
            }
        }
      }
    }
  }
}

struct WorkspaceToolSlot: Identifiable {
  let label: String
  let glyph: WorkspaceGlyph
  let tool: EditorTool?
  var alternatives: [EditorTool] = []
  var id: String { label }
  init(
    _ label: String, _ glyph: WorkspaceGlyph, _ tool: EditorTool?, alternatives: [EditorTool] = []
  ) {
    self.label = label
    self.glyph = glyph
    self.tool = tool
    self.alternatives = alternatives
  }
}
