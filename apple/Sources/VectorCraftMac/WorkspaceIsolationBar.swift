import SwiftUI
import VectorCraftCore

struct WorkspaceIsolationBar: View {
  var drawing: Drawing
  @Bindable var state: EditorState
  var body: some View {
    HStack(spacing: 10) {
      Button("Exit Isolation") { state.exitIsolation(in: drawing) }
        .buttonStyle(WorkspaceButtonStyle(bordered: true))
      ScrollView(.horizontal) {
        HStack(spacing: 7) {
          Button("Document") { state.exitIsolation(in: drawing, retaining: 0) }
          ForEach(Array(state.isolationStack.enumerated()), id: \.offset) { index, id in
            Text("/").foregroundStyle(WorkspaceTheme.dim)
            if index == state.isolationStack.count - 1 {
              Text(drawing.node(id)?.name ?? "Group").font(WorkspaceTheme.semibold)
            } else {
              Button(drawing.node(id)?.name ?? "Group") {
                state.exitIsolation(in: drawing, retaining: index + 1)
              }
            }
          }
        }.buttonStyle(WorkspaceButtonStyle())
      }.scrollIndicators(.hidden)
      Spacer(minLength: 0)
    }.padding(.horizontal, 8).frame(height: 30).background(WorkspaceTheme.tabStrip)
  }
}
