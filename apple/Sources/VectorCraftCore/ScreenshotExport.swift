import Foundation

public enum ScreenshotExportFormat: String, CaseIterable, Sendable {
  case png, svg, pdf
}

public enum ScreenshotExport {
  /// One immutable document snapshot, sequential files, and a fresh destination per export.
  @concurrent public static func write(_ drawing: Drawing, format: ScreenshotExportFormat, to folder: URL) async throws -> URL {
    let boards = drawing.includedScreenshotBoards
    guard !boards.isEmpty else { throw DrawingError.invalid("There are no populated screenshots to export.") }
    let destination = folder.appendingPathComponent("Screenshots-" + UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false)
    for board in boards {
      try Task.checkCancellation()
      let artwork = try drawing.screenshotExportDrawing(board)
      let data: Data
      switch format {
      case .png: data = try VectorRenderer.png(artwork)
      case .svg: data = try SVGExport.encode(artwork)
      case .pdf: data = try PDFExport.encode(artwork)
      }
      let slots = drawing.screenshotSlots
      guard let slot = slots.first(where: { $0.boardID == board.id }),
        let row = drawing.screenshotRows.firstIndex(where: { $0.id == slot.row }) else { continue }
      let name = String(format: "Row-%02d-Screenshot-%02d", row + 1, slot.index + 1) + "." + format.rawValue
      try data.write(to: destination.appendingPathComponent(name), options: .withoutOverwriting)
    }
    return destination
  }
}
