import SwiftUI
import VectorCraftCore

extension VectorNode {
  var outlineChildren: [VectorNode]? { children.isEmpty ? nil : Array(children.reversed()) }
}

struct LayersSidebar: View {
  var document: CanvasDocument
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void

  var body: some View {
    VStack(spacing: 0) {
      List(selection: $state.selection) {
        OutlineGroup(roots, children: \.outlineChildren) {
          node in
          HStack(spacing: 6) {
            Image(
              systemName: node.type == "layer"
                ? "square.3.layers.3d" : node.type == "group" ? "folder" : "scribble.variable"
            )
            .foregroundStyle(.secondary)
            Text(node.name).lineLimit(1)
            Spacer()
            Button(node.visible ? "Hide" : "Show", systemImage: node.visible ? "eye" : "eye.slash")
            {
              command(.visibility(node.id, !node.visible))
            }.labelStyle(.iconOnly).buttonStyle(.borderless)
              .disabled(!document.drawing.isInside(node.id, isolation: state.isolationID))
            Button(
              node.locked ? "Unlock" : "Lock", systemImage: node.locked ? "lock.fill" : "lock.open"
            ) {
              command(.lock(node.id, !node.locked))
            }.labelStyle(.iconOnly).buttonStyle(.borderless)
              .disabled(!document.drawing.isInside(node.id, isolation: state.isolationID))
          }
          .tag(node.id)
          .contextMenu {
            Button("Rename…") {
              state.renamedID = node.id
              state.rename = node.name
            }.disabled(!document.drawing.isInside(node.id, isolation: state.isolationID))
            if ["group", "layer"].contains(node.type) {
              Button("Enter Isolation") { state.enterIsolation(node.id, in: document.drawing) }
                .disabled(
                  !document.drawing.canIsolate(node.id, within: state.isolationID)
                    || state.tool == .pen || state.textEditingSession != nil)
            }
            if node.type == "layer" {
              Button("Draw on This Layer") { state.activeLayer = node.id }
                .disabled(state.isolationID != nil)
            } else {
              Button("Duplicate") { command(.duplicate([node.id])) }
                .disabled(!document.drawing.isInside(node.id, isolation: state.isolationID))
              Button("Delete") { command(.delete([node.id])) }
                .disabled(!document.drawing.isInside(node.id, isolation: state.isolationID))
            }
          }
        }
      }.listStyle(.plain).scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 24)
        .background(WorkspaceTheme.panel)
      Divider()
      HStack {
        Button("New Layer", systemImage: "plus") { command(.addLayer) }
          .disabled(state.isolationID != nil)
        Spacer()
        Menu("Drawing Layer") {
          ForEach(document.drawing.layers) { layer in
            Button(layer.name) { state.activeLayer = layer.id }
          }
        }.menuStyle(.borderlessButton).disabled(state.isolationID != nil)
      }.padding(8).buttonStyle(WorkspaceButtonStyle())
    }
  }
  private var roots: [VectorNode] {
    if let id = state.isolationID, let root = document.drawing.node(id) { return [root] }
    return Array(document.drawing.layers.reversed())
  }
}
