import SwiftUI
import VectorCraftCore

struct WorkspaceGradientControls: View {
  var document: CanvasDocument
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void

  private var node: VectorNode? { (try? document.drawing.gradientTargets(state.selection))?.first }
  private var gradient: GradientPaint? {
    guard let node else { return nil }
    return try? GradientPaint(
      GradientPaint.paint(of: node, target: state.gradientTarget), bounds: node.bounds)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Picker("Paint", selection: $state.gradientTarget) {
        ForEach(PaintTarget.allCases, id: \.self) { Text($0.rawValue).tag($0) }
      }.pickerStyle(.segmented)
      HStack {
        ForEach(GradientKind.allCases, id: \.self) { kind in
          Button(kind.rawValue) { apply(.kind(kind)) }
            .buttonStyle(WorkspaceButtonStyle(active: gradient?.kind == kind, bordered: true))
        }
        Spacer()
        Button("Reverse") { apply(.reverse) }.disabled(gradient == nil)
      }.disabled(node == nil || state.textEditingSession != nil)
      if let gradient {
        LinearGradient(
          stops: gradient.stops.sorted { ($0["offset"].double ?? 0) < ($1["offset"].double ?? 0) }
            .map {
              .init(
                color: Color(
                  cgColor: VectorRenderer.color($0["color"], opacity: $0["opacity"].double ?? 1)),
                location: $0["offset"].double ?? 0)
            }, startPoint: .leading, endPoint: .trailing
        ).frame(height: 22).accessibilityLabel("Gradient Ramp")
        HStack {
          Text("Angle")
          TextField(
            "Gradient Angle", value: Binding(get: { gradient.angle }, set: { apply(.angle($0)) }),
            format: .number.precision(.fractionLength(0...2))
          )
          .textFieldStyle(WorkspaceFieldStyle())
          Text("°")
        }
        if gradient.kind == .radial {
          HStack {
            Text("Aspect")
            TextField(
              "Gradient Aspect",
              value: Binding(get: { gradient.aspect * 100 }, set: { apply(.aspect($0 / 100)) }),
              format: .number.precision(.fractionLength(0...2))
            )
            .textFieldStyle(WorkspaceFieldStyle())
            Text("%")
          }
        }
        WorkspaceSeparator()
        let index = min(max(0, state.gradientStop), gradient.stops.count - 1)
        let stop = gradient.stops[index]
        Picker("Stop", selection: Binding(get: { index }, set: { state.gradientStop = $0 })) {
          ForEach(gradient.stops.indices, id: \.self) { i in
            Text(
              "\(i + 1) · \((gradient.stops[i]["offset"].double ?? 0) * 100, format: .number.precision(.fractionLength(0...1)))%"
            ).tag(i)
          }
        }
        HStack {
          Text("Color")
          Spacer()
          WorkspaceColorWell(
            label: "Gradient Stop Color",
            color: Binding(
              get: { Color(cgColor: VectorRenderer.color(stop["color"])) },
              set: { color in
                guard let rgb = NSColor(color).usingColorSpace(.sRGB) else { return }
                apply(
                  .stopColor(
                    index,
                    VectorStyle.solid(rgb.redComponent, rgb.greenComponent, rgb.blueComponent)[
                      "color"]))
              })
          )
          .frame(width: 22, height: 22)
        }
        HStack {
          Text("Location")
          TextField(
            "Stop Location",
            value: Binding(
              get: { (stop["offset"].double ?? 0) * 100 },
              set: { apply(.stopOffset(index, $0 / 100)) }),
            format: .number.precision(.fractionLength(0...2))
          )
          .textFieldStyle(WorkspaceFieldStyle())
          Text("%")
        }
        HStack {
          Text("Opacity")
          TextField(
            "Stop Opacity",
            value: Binding(
              get: { (stop["opacity"].double ?? 1) * 100 },
              set: { apply(.stopOpacity(index, $0 / 100)) }),
            format: .number.precision(.fractionLength(0...1))
          )
          .textFieldStyle(WorkspaceFieldStyle())
          Text("%")
        }
        HStack {
          Button("Add Stop") {
            apply(.insertStop(0.5))
          }
          Button("Delete Stop") {
            apply(.removeStop(index))
          }.disabled(gradient.stops.count <= 2)
        }.buttonStyle(WorkspaceButtonStyle(bordered: true))
      } else if let node {
        Text(
          GradientPaint.paint(of: node, target: state.gradientTarget)["type"].string == "gradient"
            ? "Unsupported Gradient" : "No Gradient"
        )
        .foregroundStyle(WorkspaceTheme.dim)
      }
    }.disabled(state.textEditingSession != nil)
  }

  private func apply(_ edit: GradientEdit) {
    guard let node else { return }
    do {
      let result = try GradientPaint.editing(
        GradientPaint.paint(of: node, target: state.gradientTarget), bounds: node.bounds,
        with: edit, selecting: state.gradientStop)
      command(.gradient(state.selection, state.gradientTarget, edit))
      if let updated = document.drawing.node(node.id),
        GradientPaint.paint(of: updated, target: state.gradientTarget) == result.raw
      {
        state.gradientStop = result.selectedStop ?? 0
      }
    } catch { state.error = error.localizedDescription }
  }
}
