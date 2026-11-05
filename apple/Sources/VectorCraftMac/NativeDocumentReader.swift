import SwiftUI
import VectorCraftCore

struct NativeDocumentReader: DocumentReader {
  @concurrent
  func read(from source: sending URL, progress: consuming Subprogress) async throws
    -> sending Drawing
  {
    let manager = progress.start(totalCount: 2)
    let values = try source.resourceValues(forKeys: [.fileSizeKey])
    guard let size = values.fileSize, size <= NativeFormat.maximumBytes else {
      throw DrawingError.invalid(
        "The document exceeds the 64 MB editor limit or its size is unavailable.")
    }
    let data = try Data(contentsOf: source, options: .mappedIfSafe)
    manager.complete(count: 1)
    let drawing = try NativeFormat.decode(data)
    manager.complete(count: 1)
    return drawing
  }
}
