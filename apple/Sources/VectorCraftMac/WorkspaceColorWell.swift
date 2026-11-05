import SwiftUI

/// Native color-picker behavior with the Rust workspace's square paint chip.
struct WorkspaceColorWell: NSViewRepresentable {
  var label: String
  @Binding var color: Color
  func makeCoordinator() -> Coordinator { Coordinator(self) }
  func makeNSView(context: Context) -> SquareColorWell {
    let well = SquareColorWell(frame: CGRect(x: 0, y: 0, width: 22, height: 22))
    well.colorWellStyle = .default
    well.target = context.coordinator
    well.action = #selector(Coordinator.changed(_:))
    well.setAccessibilityLabel(label)
    return well
  }
  func updateNSView(_ well: SquareColorWell, context: Context) {
    context.coordinator.parent = self
    well.color = NSColor(color)
    well.needsDisplay = true
  }
  @MainActor final class Coordinator: NSObject {
    var parent: WorkspaceColorWell
    init(_ parent: WorkspaceColorWell) { self.parent = parent }
    @objc func changed(_ sender: NSColorWell) { parent.color = Color(nsColor: sender.color) }
  }
}

final class SquareColorWell: NSColorWell {
  override var intrinsicContentSize: NSSize { NSSize(width: 22, height: 22) }
  override func mouseDown(with event: NSEvent) { showPicker() }
  override func accessibilityPerformPress() -> Bool {
    showPicker()
    return true
  }
  private func showPicker() {
    activate(true)
    NSColorPanel.shared.makeKeyAndOrderFront(nil)
  }
  override func draw(_ dirtyRect: NSRect) {
    color.drawSwatch(in: bounds.insetBy(dx: 1, dy: 1))
    NSColor(white: 0.45, alpha: 1).setStroke()
    NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5)).stroke()
  }
}
