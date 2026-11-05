import SwiftUI
import VectorCraftCore

struct WorkspaceAppearanceControls: View {
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        WorkspaceColorWell(
          label: "Fill",
          color: Binding(
            get: { state.fillColor },
            set: {
              state.fillColor = $0
              state.fillEnabled = true
              state.setFill()
              apply()
            })
        ).frame(width: 22, height: 22)
          .overlay {
            if state.style.fill["type"].string == "gradient" {
              WorkspacePaintChip(paint: state.style.fill).allowsHitTesting(false)
            }
          }
        Text("Fill")
        if !state.fillEnabled { Text("None").foregroundStyle(WorkspaceTheme.dim) }
        Spacer()
        Menu {
          Button("Solid Fill") {
            state.fillEnabled = true
            state.setFill()
            apply()
          }
          Button("No Fill") {
            state.fillEnabled = false
            state.setFill()
            apply()
          }
          Button("Gradient…") {
            state.gradientTarget = .fill
            state.openPanel = .gradient
          }.disabled(state.selection.isEmpty)
        } label: {
          Image(systemName: "ellipsis")
        }
        .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
      }
      HStack(spacing: 8) {
        WorkspaceColorWell(
          label: "Stroke",
          color: Binding(
            get: { state.strokeColor },
            set: {
              state.strokeColor = $0
              state.strokeEnabled = true
              state.setStroke()
              apply()
            })
        ).frame(width: 22, height: 22)
          .overlay {
            if state.style.stroke["type"].string == "gradient" {
              WorkspacePaintChip(paint: state.style.stroke).allowsHitTesting(false)
            }
          }
        Text("Stroke")
        Spacer(minLength: 0)
        TextField(
          "Stroke Width",
          value: Binding(
            get: { state.style.width },
            set: {
              state.style.width = $0
              state.strokeEnabled = $0 > 0
              if state.style.stroke["type"].string == "none" { state.setStroke() }
              apply()
            }), format: .number.precision(.fractionLength(0...2))
        )
        .frame(width: 65).textFieldStyle(WorkspaceFieldStyle())
        Text("pt").foregroundStyle(WorkspaceTheme.dim)
        Menu {
          Button("Solid Stroke") {
            state.strokeEnabled = true
            state.setStroke()
            apply()
          }
          Button("No Stroke") {
            state.strokeEnabled = false
            state.setStroke()
            apply()
          }
          Button("Gradient…") {
            state.gradientTarget = .stroke
            state.openPanel = .gradient
          }.disabled(state.selection.isEmpty)
        } label: {
          Image(systemName: "ellipsis")
        }
        .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
      }
      HStack(spacing: 8) {
        Text("Opacity")
        TextField(
          "Opacity",
          value: Binding(
            get: { state.style.opacity * 100 },
            set: {
              state.style.opacity = min(1, max(0, $0 / 100))
              apply()
            }), format: .number.precision(.fractionLength(0...1))
        )
        .frame(width: 64).textFieldStyle(WorkspaceFieldStyle())
        Text("%").foregroundStyle(WorkspaceTheme.dim)
        Spacer()
      }
    }
  }
  private func apply() {
    if !state.selection.isEmpty { command(.style(state.selection, state.style)) }
  }
}
