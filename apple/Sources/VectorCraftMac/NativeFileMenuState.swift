import AppKit
import Observation

/// A UI projection of AppKit's recent-file state, connected after SwiftUI installs its controller.
@MainActor @Observable
final class NativeFileMenuState {
  private(set) var recentDocuments: [URL] = []
  private(set) var controller: NSDocumentController?
  @ObservationIgnored private var windowObservation: (any NSObjectProtocol)?

  var canShare: Bool {
    guard let item = controller?.standardShareMenuItem(), item.isEnabled else { return false }
    if let menu = item.submenu {
      return menu.items.contains { !$0.isSeparatorItem && $0.isEnabled }
    }
    guard let action = item.action else { return false }
    return NSApp.target(forAction: action, to: item.target, from: item) != nil
  }

  func connect(to controller: NSDocumentController) {
    self.controller = controller
    // Refresh recent-file state when documents open; KVO alone left the menu stale in GUI checks.
    // Refresh after a document becomes main, after its native open/save registration completes.
    windowObservation = NotificationCenter.default.addObserver(
      forName: NSWindow.didBecomeMainNotification, object: nil, queue: .main
    ) { [weak self] _ in
      Task { @MainActor [weak self] in self?.refresh() }
    }
    refresh()
  }

  private func refresh() { recentDocuments = controller?.recentDocumentURLs ?? [] }

  func open(_ url: URL) {
    controller?.openDocument(withContentsOf: url, display: true) { _, _, error in
      if let error { NSApp.presentError(error) }
    }
  }
  func clearRecent() {
    controller?.clearRecentDocuments(nil)
    refresh()
  }
  func share() {
    guard let item = controller?.standardShareMenuItem() else { return }
    if let menu = item.submenu {
      menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    } else if let action = item.action {
      NSApp.sendAction(action, to: item.target, from: item)
    }
  }
}
