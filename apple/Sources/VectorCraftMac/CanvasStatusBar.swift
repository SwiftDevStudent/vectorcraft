import SwiftUI
import VectorCraftCore

struct CanvasStatusBar: View {
  var drawing: Drawing
  @Bindable var state: EditorState
  var body: some View {
    VStack(spacing: 0) {
      WorkspaceSeparator()
      HStack(spacing: 10) {
        Image(systemName: "questionmark.circle")
        Text(hint).fontWeight(.semibold).lineLimit(1)
        if state.imagePreviewsLoading {
          ProgressView().controlSize(.mini).accessibilityLabel("Loading Image Previews")
        } else if state.imagePreviewsUnavailable {
          Image(systemName: "photo.badge.exclamationmark")
            .accessibilityLabel("Image Previews Unavailable")
            .help("Image Previews Unavailable")
        }
        Spacer(minLength: 0)
        if state.tool == .pen {
          Button("Finish Path") { state.canvasAction = .finishPath }
          Button("Close Path") { state.canvasAction = .closePath }
          Button("Cancel") { state.canvasAction = .cancelPath }
        }
      }.padding(.horizontal, 10).frame(height: 24)
      WorkspaceSeparator()
      HStack(spacing: 12) {
        Menu("\(state.zoom * 100, format: .number.precision(.fractionLength(0...2)))%") {
          Button("Fit Artboard") { state.canvasAction = .fit }
          Button("Actual Size") { state.canvasAction = .actualSize }
        }.menuStyle(.borderlessButton).fixedSize()
        Rectangle().fill(WorkspaceTheme.divider).frame(width: 1, height: 18)
        Picker("Artboard", selection: $state.selectedArtboard) {
          ForEach(Array(drawing.artboards.enumerated()), id: \.offset) { index, _ in
            Text("\(index + 1)").tag(index)
          }
        }.labelsHidden().fixedSize()
        Rectangle().fill(WorkspaceTheme.divider).frame(width: 1, height: 18)
        Text(state.tool == .select ? "Selection" : state.tool.rawValue)
        Spacer(minLength: 0)
        if let point = state.pointer {
          Text(
            "X: \(point.x, format: .number.precision(.fractionLength(0...2))) pt   Y: \(point.y, format: .number.precision(.fractionLength(0...2))) pt"
          )
          .foregroundStyle(WorkspaceTheme.dim).lineLimit(1)
        }
      }.padding(.horizontal, 10).frame(height: 24)
    }.buttonStyle(WorkspaceButtonStyle()).background(WorkspaceTheme.panel)
  }
  private var hint: String {
    switch state.tool {
    case .select:
      "⇧Click to select multiple objects  |  ⇧Drag to constrain  |  ⌥Drag to copy"
    case .nodes: "Drag an anchor or handle to edit the path"
    case .pen: "Click to add an anchor  |  Drag to create handles  |  Return to finish"
    case .pencil: "Drag to draw a freehand path"
    case .hand: "Drag to pan the canvas"
    case .text: "Click to type  |  Drag a text frame  |  Esc to finish"
    case .zoom: "Click to zoom in  |  ⌥Click to zoom out"
    case .rotate: "Drag to rotate  |  ⇧Drag for 45° steps  |  ⌥Drag to copy"
    case .eyedropper: "Click an object to sample its appearance"
    default: "Drag to draw  |  ⇧Drag to constrain proportions"
    }
  }
}
