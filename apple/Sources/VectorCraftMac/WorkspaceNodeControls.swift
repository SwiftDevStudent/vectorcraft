import SwiftUI
import VectorCraftCore

struct WorkspaceNodeControls: View {
  var document: CanvasDocument
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Path").foregroundStyle(WorkspaceTheme.dim)
      Button("Close/Open Path") {
        guard let id = state.selection.first, let node = document.drawing.node(id) else { return }
        var paths = node.subpaths
        guard let index = state.nodeSelection?.subpath ?? paths.indices.first,
          paths.indices.contains(index)
        else { return }
        paths[index].closed.toggle()
        command(.replacePath(id, paths))
      }
      HStack {
        Button("Corner") { changeNode(smooth: false) }
        Button("Smooth") { changeNode(smooth: true) }
      }.disabled(state.nodeSelection == nil)
      Button("Delete Anchor") {
        guard let selection = state.nodeSelection, let id = state.selection.first else { return }
        command(.deleteAnchor(id, subpath: selection.subpath, anchor: selection.anchor))
      }.disabled(state.nodeSelection == nil)
    }.buttonStyle(WorkspaceButtonStyle(bordered: true))
  }
  private func changeNode(smooth: Bool) {
    guard let selection = state.nodeSelection, let id = state.selection.first,
      let node = document.drawing.node(id)
    else { return }
    var paths = node.subpaths
    guard paths.indices.contains(selection.subpath),
      paths[selection.subpath].anchors.indices.contains(selection.anchor)
    else { return }
    var anchor = paths[selection.subpath].anchors[selection.anchor]
    anchor.smooth = smooth
    anchor.incoming = smooth ? CGPoint(x: anchor.point.x - 30, y: anchor.point.y) : anchor.point
    anchor.outgoing = smooth ? CGPoint(x: anchor.point.x + 30, y: anchor.point.y) : anchor.point
    paths[selection.subpath].anchors[selection.anchor] = anchor
    command(.replacePath(id, paths))
  }
}
