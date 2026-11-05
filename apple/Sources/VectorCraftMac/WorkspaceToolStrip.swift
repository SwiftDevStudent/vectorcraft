import SwiftUI
import VectorCraftCore

struct WorkspaceToolStrip: View {
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  var editText: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      Button {
        state.toolbarDouble.toggle()
      } label: {
        HStack {
          WorkspaceIcon(glyph: state.toolbarDouble ? .chevronsLeft : .chevronsRight, size: 10)
          Spacer()
        }.padding(.leading, 4).frame(height: 14)
      }.buttonStyle(.plain).accessibilityLabel("Toggle Tool Columns")
        .background(WorkspaceTheme.tabStrip)
      WorkspaceDragHandle(state: state, panel: .tools)
      ScrollView(.vertical) {
        VStack(spacing: 0) {
          WorkspaceToolGroup(
            state: state,
            name:
              "Select",
            slots: [
              .init("Selection", .selection, .select), .init("Direct Selection", .direct, .nodes),
              .init("Lasso", .lasso, nil),
            ])
          WorkspaceToolGroup(
            state: state,
            name:
              "Shapes",
            slots: [
              .init("Rectangle", .rectangle, .rectangle, alternatives: [.rectangle, .star, .line]),
              .init("Ellipse", .ellipse, .ellipse), .init("Polygon", .polygon, .polygon),
              .init("Shaper", .shaper, nil),
            ])
          WorkspaceToolGroup(
            state: state,
            name:
              "Draw",
            slots: [
              .init("Pencil", .pencil, .pencil), .init("Eraser", .eraser, nil),
              .init("Paintbrush", .brush, nil), .init("Pen", .pen, .pen),
              .init("Curvature", .curvature, nil),
            ])
          WorkspaceToolGroup(
            state: state,
            name:
              "Modify",
            slots: [
              .init("Width", .width, nil), .init("Rotate", .rotate, .rotate),
              .init("Shape Builder", .shapeBuilder, nil),
            ])
          WorkspaceToolGroup(
            state: state,
            name:
              "Type",
            slots: [
              .init("Area Type", .areaType, nil), .init("Type", .type, .text),
            ])
          WorkspaceToolGroup(
            state: state,
            name:
              "Navigate",
            slots: [
              .init("Zoom", .zoom, .zoom), .init("Hand", .hand, .hand),
              .init("Rotate View", .rotateView, nil),
            ])
          WorkspaceToolGroup(
            state: state,
            name:
              "Color",
            slots: [
              .init("Gradient", .gradient, .gradient),
              .init("Eyedropper", .eyedropper, .eyedropper),
            ])
          WorkspacePaintProxy(state: state, command: command).padding(.top, 2)
          Button("Edit Text…") { editText() }.font(WorkspaceTheme.smallFont)
            .buttonStyle(WorkspaceButtonStyle())
          Menu {
            Button("Rectangle") { state.tool = .rectangle }
            Button("Ellipse") { state.tool = .ellipse }
            Button("Star") { state.tool = .star }
            Button("Line") { state.tool = .line }
            Divider()
            Button("Fit Artboard") { state.canvasAction = .fit }
          } label: {
            Image(systemName: "ellipsis").frame(width: 28, height: 24)
          }.menuStyle(.borderlessButton).menuIndicator(.hidden)
            .accessibilityLabel("More Tools")
        }.padding(.bottom, 8)
      }.scrollIndicators(.hidden)
    }.frame(width: state.toolbarDouble ? 76 : 48)
      .background(WorkspaceTheme.panel)
      .overlay(alignment: .trailing) { Rectangle().fill(WorkspaceTheme.border).frame(width: 1) }
  }

}

extension EditorTool {
  var workspaceGlyph: WorkspaceGlyph {
    switch self {
    case .select: .selection
    case .nodes: .direct
    case .pen: .pen
    case .pencil: .pencil
    case .rectangle: .rectangle
    case .ellipse: .ellipse
    case .star: .star
    case .polygon: .polygon
    case .line: .line
    case .hand: .hand
    case .text: .type
    case .zoom: .zoom
    case .rotate: .rotate
    case .eyedropper: .eyedropper
    case .gradient: .gradient
    }
  }
}
