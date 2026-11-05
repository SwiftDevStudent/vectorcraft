import Foundation

/// One renderer per editor serializes thumbnail raster work away from the main actor.
public actor ScreenshotPreview {
  private let images = VectorImagePreviewCache()
  public init() {}
  public static func isAffected(board id: Int64, previous: Drawing, current: Drawing) -> Bool {
    guard let oldBoard = previous.screenshotBoard(id), let board = current.screenshotBoard(id),
      let oldIndex = previous.artboardIndex(id: id), let index = current.artboardIndex(id: id)
    else { return true }
    guard previous.artboards.indices.contains(oldIndex), current.artboards.indices.contains(index)
    else { return true }
    return previous.node(oldBoard.layer) != current.node(board.layer)
      || previous.artboards[oldIndex] != current.artboards[index]
      || previous.envelope["images"] != current.envelope["images"]
      || previous.nativeBlobData != current.nativeBlobData
  }

  public func png(_ drawing: Drawing, board id: Int64) throws -> Data {
    try Task.checkCancellation()
    guard let board = drawing.screenshotBoard(id) else {
      throw DrawingError.invalid("The screenshot slot is unavailable.")
    }
    let artwork = try drawing.screenshotArtworkDrawing(board)
    let rect = artwork.artboard
    let bytes = try VectorRenderer.png(artwork, scale: min(128 / rect.width, 128 / rect.height),
      previewImages: images)
    try Task.checkCancellation()
    return bytes
  }
}
