import AppKit
import Observation
import SwiftUI
import UniformTypeIdentifiers
import VectorCraftCore

/// Owns a user-requested import independently of whichever document window is frontmost.
@MainActor @Observable
final class SVGFileImport {
  private(set) var isImporting = false
  @ObservationIgnored private var task: Task<Void, Never>?
  @ObservationIgnored private var panel: NSOpenPanel?

  func choose(present: @escaping @MainActor (Drawing) -> Void) {
    guard !isImporting else { return }
    let picker = NSOpenPanel()
    picker.allowedContentTypes = [.svg]
    picker.allowsMultipleSelection = false
    picker.canChooseDirectories = false
    picker.prompt = "Import"
    panel = picker
    isImporting = true
    picker.begin { [weak self] response in
      guard let self else { return }
      panel = nil
      guard response == .OK, let url = picker.url else {
        isImporting = false
        return
      }
      task = Task { [weak self] in
        defer {
          self?.isImporting = false
          self?.task = nil
        }
        do {
          let drawing = try await SVGFileReader.read(url)
          try Task.checkCancellation()
          present(drawing)
        } catch is CancellationError {
          // Canceling an import doesn't create a document or present an error.
        } catch { NSApp.presentError(error) }
      }
    }
  }
}

enum SVGFileReader {
  @concurrent static func read(_ source: URL) async throws -> Drawing {
    try Task.checkCancellation()
    let scoped = source.startAccessingSecurityScopedResource()
    defer { if scoped { source.stopAccessingSecurityScopedResource() } }
    let coordinator = NSFileCoordinator(filePresenter: nil)
    var coordinationError: NSError?
    var result: Result<Drawing, any Error>?
    coordinator.coordinate(readingItemAt: source, options: [], error: &coordinationError) { url in
      result = Result {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        guard let size = values.fileSize, size <= SVGImport.maximumBytes else {
          throw DrawingError.invalid("SVG import is limited to 8 MB.")
        }
        return try SVGImport.decode(
          Data(contentsOf: url, options: .mappedIfSafe),
          title: url.deletingPathExtension().lastPathComponent)
      }
    }
    if let coordinationError { throw coordinationError }
    guard let result else { throw DrawingError.invalid("Could not coordinate SVG import.") }
    try Task.checkCancellation()
    return try result.get()
  }
}
