import SwiftUI
import VectorCraftCore

struct WorkspaceCharacterControls: View {
  var document: CanvasDocument
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  private var node: VectorNode? {
    guard state.selection.count == 1,
      let node = state.selection.first.flatMap(document.drawing.node),
      node.type == "text"
    else { return nil }
    return node
  }
  private var text: String {
    node?.raw["kind"]["runs"].array.map { $0["text"].string }.joined() ?? ""
  }
  private var family: String {
    node?.raw["kind"]["runs"].array.first?["style"]["font_family"].string ?? state.textFont
  }
  private var size: Double {
    node?.raw["kind"]["runs"].array.first?["style"]["size"].double ?? state.textSize
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Picker(
        "Font",
        selection: Binding(
          get: { family },
          set: { value in
            state.textFont = value
            if let node { command(.editText(node.id, text, font: value, size: size)) }
          })
      ) {
        ForEach(NSFontManager.shared.availableFontFamilies, id: \.self) { Text($0).tag($0) }
      }
      HStack {
        Text("Size")
        TextField(
          "Font Size",
          value: Binding(
            get: { size },
            set: { value in
              guard value.isFinite, (0.1...10000).contains(value) else { return }
              state.textSize = value
              if let node { command(.editText(node.id, text, font: family, size: value)) }
            }), format: .number.precision(.fractionLength(0...2))
        )
        .textFieldStyle(WorkspaceFieldStyle()).frame(width: 70)
        Text("pt").foregroundStyle(WorkspaceTheme.dim)
        Spacer()
      }
    }
  }
}
