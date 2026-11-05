import SwiftUI
import UniformTypeIdentifiers

@MainActor @Observable
final class ExportDocument: WritableDocument {
  nonisolated static let writableContentTypes: [UTType] = [.png, .svg, .pdf]
  let data: Data
  init(data: Data) { self.data = data }
  nonisolated func writer(configuration: sending WriteConfiguration)
    -> sending FileWrapperDocumentWriter<Data>
  {
    FileWrapperDocumentWriter(configuration) { data, _ in FileWrapper(regularFileWithContents: data)
    }
  }
  func snapshot(contentType: UTType) async throws -> sending Data { data }
}
