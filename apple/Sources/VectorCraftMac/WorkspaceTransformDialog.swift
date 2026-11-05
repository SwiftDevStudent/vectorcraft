import SwiftUI
import VectorCraftCore

struct WorkspaceTransformDialog: View {
  @Bindable var session: TransformDialogSession
  var commit: (Bool) -> Void
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(session.kind.rawValue).font(WorkspaceTheme.semibold)
      WorkspaceSeparator()
      if session.kind == .each {
        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
          number("Horizontal Scale", value: $session.settings.individual.scaleX, unit: "%")
          number("Vertical Scale", value: $session.settings.individual.scaleY, unit: "%")
          number("Horizontal Move", value: $session.settings.individual.moveX, unit: "pt")
          number("Vertical Move", value: $session.settings.individual.moveY, unit: "pt")
          number("Rotation", value: $session.settings.individual.rotation, unit: "°")
        }
        HStack {
          Toggle("Reflect X", isOn: $session.settings.individual.reflectX)
          Toggle("Reflect Y", isOn: $session.settings.individual.reflectY)
          Toggle("Random", isOn: $session.settings.individual.random)
        }
      } else {
        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
          if session.kind == .shear {
            number("Shear Angle", value: $session.settings.shearAngle, unit: "°")
          }
          GridRow {
            Text("Axis")
            Picker("Axis", selection: $session.settings.axis) {
              ForEach(TransformAxis.allCases) { Text($0.rawValue).tag($0) }
            }.labelsHidden()
          }
          if session.settings.axis == .angle {
            number("Axis Angle", value: $session.settings.axisAngle, unit: "°")
          }
        }
      }
      HStack(spacing: 12) {
        Text("Reference Point")
        Spacer()
        TransformReferencePicker(reference: $session.settings.individual.reference)
      }
      if let error = session.error {
        Text(error).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
      }
      WorkspaceSeparator()
      HStack {
        Toggle("Preview", isOn: $session.previewEnabled)
        Spacer()
        Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
        Button("Copy") { commit(true) }.disabled(session.error != nil)
        Button("OK") { commit(false) }.keyboardShortcut(.defaultAction).disabled(
          session.error != nil)
      }.buttonStyle(WorkspaceButtonStyle(bordered: true))
    }
    .font(WorkspaceTheme.font).foregroundStyle(WorkspaceTheme.text)
    .padding(16).frame(width: 370).background(WorkspaceTheme.panel)
    .onChange(of: session.settings) { _, _ in session.refresh() }
    .onChange(of: session.previewEnabled) { _, _ in session.refresh() }
  }

  private func number(_ label: String, value: Binding<Double>, unit: String) -> some View {
    GridRow {
      Text(label)
      HStack {
        TextField(label, value: value, format: .number.precision(.fractionLength(0...3)))
          .textFieldStyle(WorkspaceFieldStyle()).accessibilityLabel(label)
        Text(unit).foregroundStyle(WorkspaceTheme.dim).frame(width: 16)
      }
    }
  }
}

private struct TransformReferencePicker: View {
  @Binding var reference: TransformReference
  var body: some View {
    Grid(horizontalSpacing: 3, verticalSpacing: 3) {
      ForEach(0..<3) { row in
        GridRow {
          ForEach(TransformReference.allCases.filter { $0.rawValue / 3 == row }, id: \.rawValue) {
            point in
            Button {
              reference = point
            } label: {
              Rectangle().fill(
                reference == point ? Color(nsColor: WorkspaceTheme.selection) : WorkspaceTheme.dim
              )
              .frame(width: 9, height: 9).padding(4)
            }.buttonStyle(.plain).accessibilityLabel(point.label)
              .accessibilityAddTraits(reference == point ? .isSelected : [])
          }
        }
      }
    }
  }
}
