import AppKit
import VectorCraftCore

extension VectorCanvasView {
  func beginTextEditing(
    id: Int64? = nil, origin: CGPoint = .zero, area: CGRect? = nil, event: NSEvent? = nil
  ) {
    finishTextEditing()
    let node = id.flatMap(drawing.node)
    if let node {
      guard drawing.canEdit(node.id), drawing.isInside(node.id, isolation: state.isolationID),
        VectorText.canEditInline(node)
      else {
        state.error =
          "This text has formatting the inline editor cannot yet preserve. Its original data is retained."
        return
      }
      let xf = node.raw["kind"]["xf"].affine ?? .identity
      guard xf.a * xf.d - xf.b * xf.c > 0.000001,
        abs(xf.a * xf.c + xf.b * xf.d) < 0.000001
      else {
        state.error = "Inline editing of skewed or reflected text is not yet supported."
        return
      }
      state.selection = [node.id]
    } else {
      state.selection = []
    }
    state.tool = .text
    let location = area?.origin ?? origin
    let editor = CanvasTextEditor(canvas: self, node: node, origin: location, area: area)
    textEditor = editor
    editor.focus(event: event)
    needsDisplay = true
  }

  func finishTextEditing() {
    guard let editor = textEditor else { return }
    textEditor = nil
    state.textEditingSession = nil
    editor.detach()
    needsDisplay = true
  }
}
