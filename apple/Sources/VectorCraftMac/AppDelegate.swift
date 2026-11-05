import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  let fileMenu = NativeFileMenuState()
  func applicationDidFinishLaunching(_ notification: Notification) {
    // SwiftPM executables need the normal GUI activation policy in their app bundle.
    NSApplication.shared.setActivationPolicy(.regular)
    fileMenu.connect(to: .shared)
    NSApplication.shared.activate()
  }
}
