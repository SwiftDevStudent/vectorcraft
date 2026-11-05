import SwiftUI
import VectorCraftCore

struct WorkspaceTransformControls: View {
  var document: CanvasDocument
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  @State private var x = 0.0
  @State private var y = 0.0
  @State private var width = 0.0
  @State private var height = 0.0
  @State private var angle = 0.0
  var body: some View {
    VStack(spacing: 8) {
      Grid(horizontalSpacing: 6, verticalSpacing: 8) {
        GridRow {
          Text("X:").foregroundStyle(WorkspaceTheme.dim)
          TextField("X", value: $x, format: .number.precision(.fractionLength(0...2)))
            .onSubmit { move(horizontal: true) }
          Text("W:").foregroundStyle(WorkspaceTheme.dim)
          TextField("Width", value: $width, format: .number.precision(.fractionLength(0...2)))
            .onSubmit(resize)
        }
        GridRow {
          Text("Y:").foregroundStyle(WorkspaceTheme.dim)
          TextField("Y", value: $y, format: .number.precision(.fractionLength(0...2)))
            .onSubmit { move(horizontal: false) }
          Text("H:").foregroundStyle(WorkspaceTheme.dim)
          TextField("Height", value: $height, format: .number.precision(.fractionLength(0...2)))
            .onSubmit(resize)
        }
      }.textFieldStyle(WorkspaceFieldStyle())
      HStack(spacing: 8) {
        WorkspaceIcon(glyph: .rotate, size: 16)
        TextField("Rotation", value: $angle, format: .number.precision(.fractionLength(0...2)))
          .textFieldStyle(WorkspaceFieldStyle()).frame(width: 70).onSubmit(rotate)
        Button("Rotate", action: rotate).buttonStyle(WorkspaceButtonStyle())
        Spacer()
      }
    }.disabled(state.selection.isEmpty)
      .onChange(of: state.selection) { _, _ in refresh() }
      .onChange(of: document.drawing) { _, _ in refresh() }
      .onAppear(perform: refresh)
  }
  private var bounds: CGRect {
    state.selection.compactMap(document.drawing.node).reduce(CGRect.null) { $0.union($1.bounds) }
  }
  private func refresh() {
    let box = bounds
    x = box.isNull ? 0 : box.midX
    y = box.isNull ? 0 : box.midY
    width = box.isNull ? 0 : box.width
    height = box.isNull ? 0 : box.height
  }
  private func move(horizontal: Bool) {
    let box = bounds
    guard !box.isNull else { return }
    command(
      .transform(
        state.selection,
        .init(
          translationX: horizontal ? x - box.midX : 0,
          y: horizontal ? 0 : y - box.midY)))
  }
  private func resize() {
    let box = bounds
    guard width > 0, height > 0, box.width > 0, box.height > 0 else { return }
    if state.selection.count == 1, let id = state.selection.first,
      let node = document.drawing.node(id), VectorText.areaRect(node) != nil,
      let xf = node.raw["kind"]["xf"].affine, xf.b == 0, xf.c == 0, xf.a > 0, xf.d > 0
    {
      command(
        .resizeTextFrame(id, CGRect(origin: box.origin, size: CGSize(width: width, height: height)))
      )
      return
    }
    command(
      .transform(
        state.selection,
        CGAffineTransform(translationX: box.minX, y: box.minY)
          .scaledBy(x: width / box.width, y: height / box.height)
          .translatedBy(x: -box.minX, y: -box.minY)))
  }
  private func rotate() {
    let box = bounds
    guard !box.isNull else { return }
    command(
      .transform(
        state.selection,
        CGAffineTransform(translationX: box.midX, y: box.midY).rotated(by: angle * .pi / 180)
          .translatedBy(x: -box.midX, y: -box.midY)))
    angle = 0
  }
}
