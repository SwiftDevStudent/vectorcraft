import SwiftUI
import VectorCraftCore

struct WorkspacePathfinderControls: View {
  var document: CanvasDocument
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  private var rule: VectorFillRule? {
    let rules = state.selection.compactMap(document.drawing.node).map {
      VectorFillRule(rawValue: $0.raw["kind"]["rule"].string) ?? .nonZero
    }
    guard let first = rules.first, rules.allSatisfy({ $0 == first }) else { return nil }
    return first
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
        ForEach(PathfinderOperation.allCases, id: \.rawValue) { operation in
          Button(operation.rawValue) { command(.pathfinder(state.selection, operation)) }
            .frame(maxWidth: .infinity)
        }
      }.disabled(!document.drawing.canUsePathfinder(state.selection))
      WorkspaceSeparator()
      HStack {
        Button("Make Compound") { command(.makeCompound(state.selection)) }
          .disabled(!document.drawing.canMakeCompound(state.selection))
        Button("Release") { command(.releaseCompound(state.selection)) }
          .disabled(!document.drawing.canReleaseCompound(state.selection))
      }
      Picker(
        "Fill Rule",
        selection: Binding<VectorFillRule?>(
          get: { rule },
          set: { value in
            if let value { command(.fillRule(state.selection, value)) }
          })
      ) {
        if rule == nil { Text("Mixed").tag(nil as VectorFillRule?) }
        ForEach(VectorFillRule.allCases, id: \.rawValue) { rule in
          Text(rule.label).tag(Optional(rule))
        }
      }.disabled(!document.drawing.canMakeCompound(state.selection))
    }.buttonStyle(WorkspaceButtonStyle(bordered: true))
  }
}
