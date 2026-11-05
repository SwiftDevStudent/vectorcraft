import SwiftUI
import VectorCraftCore

struct WorkspacePaintProxy: View {
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  var body: some View {
    VStack(spacing: 6) {
      ZStack {
        WorkspacePaintChip(paint: state.style.stroke)
          .frame(width: 24, height: 24).overlay(Rectangle().stroke(.black, lineWidth: 2))
          .offset(x: 8, y: 8)
        WorkspacePaintChip(paint: state.style.fill)
          .frame(width: 24, height: 24).overlay(Rectangle().stroke(.black, lineWidth: 2))
          .offset(x: -4, y: -4)
      }.frame(height: 40).accessibilityLabel("Fill and Stroke")
      HStack(spacing: 2) {
        Button {
          state.fillEnabled = true
          state.setFill()
          apply()
        } label: {
          Rectangle().fill(state.fillColor).frame(width: 10, height: 10)
        }
        .accessibilityLabel("Solid Fill")
        Button {
          state.fillEnabled = false
          state.setFill()
          apply()
        } label: {
          Rectangle().fill(.white).frame(width: 10, height: 10)
            .overlay(Image(systemName: "line.diagonal").foregroundStyle(.red))
        }.accessibilityLabel("No Fill")
      }.buttonStyle(.plain)
    }
  }
  private func apply() {
    if !state.selection.isEmpty { command(.style(state.selection, state.style)) }
  }
}
