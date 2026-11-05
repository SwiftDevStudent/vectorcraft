import SwiftUI
import VectorCraftCore

struct CanvasRepresentable: NSViewRepresentable {
  var drawing: Drawing
  var state: EditorState
  var command: (DrawingCommand) -> Void
  var action: CanvasAction?
  var rulers: Bool
  var grid: Bool
  var gradientTarget: PaintTarget
  var gradientStop: Int
  var transformPreview: (drawing: Drawing, selection: Set<Int64>)?
  var imageAccessRevision: Int

  func makeNSView(context: Context) -> VectorCanvasView {
    let view = VectorCanvasView()
    view.imagePreviews.accessChanged(imageAccessRevision)
    view.transformPreview = transformPreview
    view.update(drawing: drawing, state: state, command: command)
    return view
  }
  func updateNSView(_ view: VectorCanvasView, context: Context) {
    view.imagePreviews.accessChanged(imageAccessRevision)
    view.transformPreview = transformPreview
    view.update(drawing: drawing, state: state, command: command)
  }
  static func dismantleNSView(_ view: VectorCanvasView, coordinator: ()) {
    view.finishTextEditing()
    view.imagePreviews.cancel()
    view.bitmapPaste.cancel()
  }
}
