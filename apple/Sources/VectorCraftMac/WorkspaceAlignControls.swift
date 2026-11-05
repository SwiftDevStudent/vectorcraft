import SwiftUI
import VectorCraftCore

struct WorkspaceAlignControls: View {
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  var body: some View {
    HStack(spacing: 6) {
      ForEach(VectorAlignment.allCases, id: \.self) { alignment in
        Button {
          command(.align(state.selection, alignment, artboard: state.selectedArtboard))
        } label: {
          WorkspaceIcon(glyph: alignment.glyph, size: 18)
        }.buttonStyle(WorkspaceButtonStyle()).accessibilityLabel(alignment.label).help(
          alignment.label)
      }
    }.disabled(state.selection.isEmpty)
  }
}

extension VectorAlignment {
  var glyph: WorkspaceGlyph {
    switch self {
    case .left: .alignLeft
    case .horizontalCenter: .alignCenter
    case .right: .alignRight
    case .top: .alignTop
    case .verticalCenter: .alignMiddle
    case .bottom: .alignBottom
    }
  }
  var label: String {
    switch self {
    case .left: "Horizontal Align Left"
    case .horizontalCenter: "Horizontal Align Center"
    case .right: "Horizontal Align Right"
    case .top: "Vertical Align Top"
    case .verticalCenter: "Vertical Align Center"
    case .bottom: "Vertical Align Bottom"
    }
  }
}
