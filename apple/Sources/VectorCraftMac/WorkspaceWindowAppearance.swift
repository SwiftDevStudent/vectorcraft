import SwiftUI

struct WorkspaceWindowAppearance: NSViewRepresentable {
  func makeNSView(context: Context) -> WorkspaceWindowView { WorkspaceWindowView() }
  func updateNSView(_ view: WorkspaceWindowView, context: Context) { view.configureWindow() }
}

final class WorkspaceWindowView: NSView {
  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    configureWindow()
  }
  func configureWindow() {
    guard let window else { return }
    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    window.backgroundColor = WorkspaceTheme.pasteboard
    window.minSize = NSSize(width: 760, height: 480)
  }
}
