import AppKit
import OSLog

/// Keeps the standard Save command on NSDocument's activity queue without blocking the main actor.
@MainActor
final class NativeDocumentSave {
  private static let log = Logger(
    subsystem: "com.swiftdev.vectorcraft.mac", category: "DocumentSave")
  // The boundary is injectable so sequencing tests don't present a native Save panel.
  var saveOperation: @MainActor (NSDocument, Bool, @escaping () -> Void) -> Void =
    NativeSaveCompletion.save

  func save(_ document: NSDocument, asNewFile: Bool = false) {
    Self.log.notice("Queued native Save activity")
    document.performActivity(withSynchronousWaiting: false) { [saveOperation] finished in
      Self.log.notice("Continuing native Save activity")
      // NSDocument.h requires this for nested activity calls, including its own Save path.
      document.continueActivity {
        saveOperation(document, asNewFile, finished)
      }
    }
  }

}

@MainActor
private final class NativeSaveCompletion: NSObject {
  private let finished: () -> Void
  private init(finished: @escaping () -> Void) { self.finished = finished }

  static func save(_ document: NSDocument, asNewFile: Bool, finished: @escaping () -> Void) {
    let delegate = NativeSaveCompletion(finished: finished)
    // Keep the delegate alive through Save/Cancel even if its editor view disappears.
    let context = Unmanaged.passRetained(delegate).toOpaque()
    if asNewFile {
      document.runModalSavePanel(
        for: .saveAsOperation, delegate: delegate,
        didSave: #selector(completed(_:didSave:contextInfo:)), contextInfo: context)
    } else {
      document.save(
        withDelegate: delegate, didSave: #selector(completed(_:didSave:contextInfo:)),
        contextInfo: context)
    }
  }

  @objc private func completed(
    _ document: NSDocument, didSave: Bool, contextInfo: UnsafeMutableRawPointer?
  ) {
    defer {
      if let contextInfo { Unmanaged<NativeSaveCompletion>.fromOpaque(contextInfo).release() }
    }
    // Release the activity only after the native operation finishes or the person cancels it.
    finished()
  }
}
