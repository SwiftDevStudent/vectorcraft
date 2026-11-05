import AppKit
import Observation
import VectorCraftCore

/// A user-selected local library; source artwork remains outside the application and documents.
@MainActor @Observable
final class ScreenshotDeviceLibrary {
  let previews = ScreenshotPreview()
  var choices: [ScreenshotFrameChoice] = []
  private(set) var revision = 0
  private var directory: URL?
  private var scopedDirectory: URL?
  private let bookmarkKey = "ScreenshotDeviceLibraryBookmark"
  var models: [String] { Array(Set(choices.map(\.model))).sorted() }

  isolated deinit { scopedDirectory?.stopAccessingSecurityScopedResource() }

  func restore() {
    guard let bookmark = UserDefaults.standard.data(forKey: bookmarkKey) else { return }
    var stale = false
    guard let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope,
      relativeTo: nil, bookmarkDataIsStale: &stale) else { return }
    try? load(url)
  }
  func choose() throws {
    let panel = NSOpenPanel()
    panel.title = "Choose Your Apple Device Library"
    panel.canChooseDirectories = true; panel.canChooseFiles = false
    guard panel.runModal() == .OK, let url = panel.url else { return }
    try load(url)
    let access = url.startAccessingSecurityScopedResource()
    defer { if access { url.stopAccessingSecurityScopedResource() } }
    UserDefaults.standard.set(try url.bookmarkData(options: .withSecurityScope,
      includingResourceValuesForKeys: nil, relativeTo: nil), forKey: bookmarkKey)
  }
  private func load(_ directory: URL) throws {
    let access = directory.startAccessingSecurityScopedResource()
    var retained = false
    defer { if access && !retained { directory.stopAccessingSecurityScopedResource() } }
    let choices = try ScreenshotFrameInventory.choices(inventory: directory.appendingPathComponent("manifest.json"))
    guard !choices.isEmpty else { throw DrawingError.invalid("Choose the AppleDevices folder containing your measured local frame library.") }
    // CLI-created documents can contain verified local paths without per-file bookmarks.
    // Keep the already-approved library scope while this editor renders those resources.
    scopedDirectory?.stopAccessingSecurityScopedResource()
    scopedDirectory = access ? directory : nil
    retained = true
    self.directory = directory; self.choices = choices
    revision += 1
  }
  func reference(_ choice: ScreenshotFrameChoice) throws -> JSONValue {
    guard let directory else { throw DrawingError.invalid("Choose a device library first.") }
    let access = directory.startAccessingSecurityScopedResource()
    defer { if access { directory.stopAccessingSecurityScopedResource() } }
    let png = directory.appendingPathComponent(choice.relativePath)
    var reference = try ScreenshotFrameInventory.reference(png: png, inventory: directory.appendingPathComponent("manifest.json"))
    reference["bookmark"] = .string(try png.bookmarkData(options: .withSecurityScope,
      includingResourceValuesForKeys: nil, relativeTo: nil).base64EncodedString())
    return reference
  }
}
