import SwiftUI

struct WorkspaceDragHandle: View {
  @Bindable var state: EditorState
  var panel: WorkspacePanelKind
  @State private var origin: CGPoint?
  @State private var feedback = SnapFeedback()
  var body: some View {
    HStack(spacing: 2) {
      Spacer(minLength: 0)
      Rectangle().fill(WorkspaceTheme.disabled).frame(width: 18, height: 2)
      Spacer(minLength: 0)
      if state.isFloating(panel) {
        Button {
          state.dockPanel(panel)
        } label: {
          WorkspaceIcon(glyph: .chevronsRight, size: 10)
        }
        .buttonStyle(.plain).accessibilityLabel(panel == .tools ? "Dock Tools" : "Dock Properties")
      }
    }.frame(height: 12).contentShape(Rectangle())
      .background(WorkspaceTheme.tabStrip)
      .accessibilityElement(children: .contain)
      .accessibilityLabel(panel == .tools ? "Move Tools" : "Move Properties")
      .help("Drag to move; Control bypasses snapping; double-click to dock or float")
      .gesture(
        DragGesture(minimumDistance: 4, coordinateSpace: .named("workspace"))
          .onChanged { value in
            if origin == nil {
              origin =
                state.isFloating(panel)
                ? state.panelPosition(panel)
                : CGPoint(x: value.startLocation.x - 20, y: value.startLocation.y - 7)
              if let origin { feedback.begin(at: origin, event: NSApp.currentEvent) }
            }
            // Keep a docked grip alive until drop; subsequent floating drags update live.
            if state.isFloating(panel), let origin {
              move(
                to: CGPoint(
                  x: origin.x + value.translation.width,
                  y: origin.y + value.translation.height))
            }
          }.onEnded { value in
            if let origin {
              move(
                to: CGPoint(
                  x: origin.x + value.translation.width,
                  y: origin.y + value.translation.height))
            }
            origin = nil
            feedback.end()
          }
      )
      .onTapGesture(count: 2) { toggleDock() }
      .contextMenu { Button(state.isFloating(panel) ? "Dock" : "Float") { toggleDock() } }
  }
  private func move(to point: CGPoint) {
    let event = NSApp.currentEvent
    let bypass = event?.modifierFlags.contains(.control) == true
    state.movePanel(panel, to: point, bypassSnapping: bypass)
    feedback.move(
      raw: point, aligned: state.panelPosition(panel), in: NSApp.keyWindow?.contentView,
      event: event, enabled: state.snapHaptics && state.snapPalettes && !bypass)
  }
  private func toggleDock() {
    if state.isFloating(panel) {
      state.dockPanel(panel)
    } else {
      state.movePanel(panel, to: state.panelPosition(panel))
    }
  }
}
