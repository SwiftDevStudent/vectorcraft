import AppKit
import Foundation
import UniformTypeIdentifiers
import VectorCraftCore

struct ScreenshotBoardDrag: Codable, Sendable {
  let document: UUID
  let board: Int64

  // Supply bytes directly, without the file promises synthesized for a mixed
  // Transferable source. A local board drag is never an exported image file.
  func itemProvider() -> NSItemProvider {
    let provider = NSItemProvider()
    provider.registerDataRepresentation(
      forTypeIdentifier: ScreenshotDropItem.contentType.identifier, visibility: .ownProcess
    ) { completion in
      do { completion(try JSONEncoder().encode(self), nil) }
      catch { completion(nil, error) }
      return nil
    }
    return provider
  }
}

enum ScreenshotDropItem: Sendable {
  case board(ScreenshotBoardDrag)
  case image(Data)

  static let contentType = UTType(
    exportedAs: "com.swiftdev.vectorcraft.screenshot-slot", conformingTo: .data)
  @MainActor static func load(_ provider: NSItemProvider) async throws -> Self {
    if provider.hasItemConformingToTypeIdentifier(contentType.identifier) {
      let data: Data = try await withCheckedThrowingContinuation { continuation in
        _ = provider.loadDataRepresentation(forTypeIdentifier: contentType.identifier) { data, error in
          if let error { continuation.resume(throwing: error) }
          else if let data { continuation.resume(returning: data) }
          else { continuation.resume(throwing: DrawingError.invalid("Missing screenshot card data.")) }
        }
      }
      guard data.count <= 4096 else { throw DrawingError.invalid("Invalid screenshot drag.") }
      return .board(try JSONDecoder().decode(ScreenshotBoardDrag.self, from: data))
    }
    if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
      let data: Data = try await withCheckedThrowingContinuation { continuation in
        _ = provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, error in
          if let error { continuation.resume(throwing: error) }
          else if let data { continuation.resume(returning: data) }
          else { continuation.resume(throwing: DrawingError.invalid("Missing screenshot file.")) }
        }
      }
      guard let url = URL(dataRepresentation: data, relativeTo: nil) else {
        throw DrawingError.invalid("Drop a local PNG or JPEG file.")
      }
      return try image(from: url)
    }
    return try await withCheckedThrowingContinuation { continuation in
      provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
        if let error { continuation.resume(throwing: error) }
        else {
          continuation.resume(with: Result {
            guard let url else { throw DrawingError.invalid("Missing screenshot image.") }
            // Read while the provider's temporary file is valid.
            return try image(from: url)
          })
        }
      }
    }
  }

  static func image(from url: URL) throws -> Self {
    guard url.isFileURL else { throw DrawingError.invalid("Drop a local PNG or JPEG file.") }
    let access = url.startAccessingSecurityScopedResource()
    defer { if access { url.stopAccessingSecurityScopedResource() } }
    let file = try FileHandle(forReadingFrom: url)
    defer { try? file.close() }  // Read-only handle cleanup cannot change the imported bytes.
    let data = try file.read(upToCount: 16 * 1024 * 1024 + 1) ?? Data()
    guard !data.isEmpty, data.count <= 16 * 1024 * 1024 else {
      throw DrawingError.invalid("Choose a PNG or JPEG no larger than 16 MB.")
    }
    return .image(data)
  }

  static func command(
    _ items: [Self], document: UUID? = nil, target: ScreenshotSlot, template: String = "headline"
  ) throws -> DrawingCommand {
    if items.count == 1, let first = items.first, case .board(let drag) = first {
      guard drag.document == document else {
        throw DrawingError.invalid("Move screenshot cards within the same document.")
      }
      return .screenshot(
        ScreenshotCommand(.moveBoard, row: target.row, board: drag.board, slot: target.index))
    }
    let images = items.compactMap { if case .image(let bytes) = $0 { bytes } else { nil } }
    guard images.count == items.count, !images.isEmpty, images.count <= 10 else {
      throw DrawingError.invalid("Drop up to ten PNG or JPEG files, or move one screenshot card.")
    }
    return .screenshot(
      ScreenshotCommand(
        .placeScreenshots, row: target.row, template: template, slot: target.index, images: images))
  }
}
