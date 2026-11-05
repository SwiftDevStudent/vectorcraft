import SwiftUI
import VectorCraftCore

struct WorkspaceArtboardControls: View {
  var document: CanvasDocument
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  @State private var width = 800.0
  @State private var height = 800.0
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("Units").foregroundStyle(WorkspaceTheme.dim)
        Spacer()
        Text("Points")
      }
      HStack(spacing: 8) {
        Text("W:")
        TextField(
          "Artboard Width", value: $width, format: .number.precision(.fractionLength(0...2))
        )
        .disabled(state.isolationID != nil)
        Text("H:")
        TextField(
          "Artboard Height", value: $height, format: .number.precision(.fractionLength(0...2))
        )
        .disabled(state.isolationID != nil)
      }.textFieldStyle(WorkspaceFieldStyle())
      Button("Resize Artboard") {
        command(.resizeArtboard(state.selectedArtboard, CGSize(width: width, height: height)))
      }.buttonStyle(WorkspaceButtonStyle(bordered: true)).disabled(state.isolationID != nil)
      WorkspaceSeparator().padding(.vertical, 4)
      Text("Rulers & Grids").foregroundStyle(WorkspaceTheme.dim)
      HStack {
        Button {
          state.rulersPresented.toggle()
        } label: {
          WorkspaceIcon(glyph: .ruler)
        }
        .buttonStyle(WorkspaceButtonStyle(active: state.rulersPresented)).accessibilityLabel(
          "Rulers")
        Button {
          state.gridPresented.toggle()
        } label: {
          WorkspaceIcon(glyph: .pattern)
        }
        .buttonStyle(WorkspaceButtonStyle(active: state.gridPresented)).accessibilityLabel("Grid")
        Spacer()
        Button {
          state.canvasAction = .fit
        } label: {
          WorkspaceIcon(glyph: .guides)
        }
        .buttonStyle(WorkspaceButtonStyle()).accessibilityLabel("Fit Artboard")
      }
    }.onChange(of: state.selectedArtboard) { _, _ in refresh() }
      .onChange(of: document.drawing) { _, _ in refresh() }.onAppear(perform: refresh)
  }
  private func refresh() {
    guard document.drawing.artboards.indices.contains(state.selectedArtboard) else { return }
    let board = document.drawing.artboards[state.selectedArtboard]
    width = board.width
    height = board.height
  }
}
