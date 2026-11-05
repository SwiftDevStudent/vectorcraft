import Foundation

extension Drawing {
  mutating func placeScreenshotImages(_ edit: ScreenshotCommand) throws -> Set<Int64> {
    guard let row = screenshotRows.first(where: { $0.id == edit.row }), let start = edit.slot,
      (0..<10).contains(start), let images = edit.images, !images.isEmpty, images.count <= 10
    else {
      throw DrawingError.invalid("Choose a screenshot slot and up to ten PNG or JPEG images.")
    }
    let slots = screenshotSlots.filter { $0.row == row.id }
    let destinations = slots.filter { $0.index == start || ($0.index > start && $0.boardID == nil) }
    guard destinations.count >= images.count else {
      throw DrawingError.invalid("There are not enough empty slots after this screenshot.")
    }
    var selected = Set<Int64>()
    for (destination, data) in zip(destinations, images) {
      if destination.boardID == nil {
        _ = try applyScreenshot(
          ScreenshotCommand(
            .addBoard, row: row.id, template: edit.template, slot: destination.index))
      }
      guard
        let id = screenshotSlots.first(where: { $0.row == row.id && $0.index == destination.index }
        )?.boardID,
        let board = screenshotBoard(id)
      else { throw DrawingError.invalid("The screenshot slot is unavailable.") }
      _ = try applyScreenshot(ScreenshotCommand(.replaceScreenshot, board: id, data: data))
      if selected.isEmpty { selected = [board.content] }
    }
    return selected
  }

  mutating func moveScreenshotBoard(_ edit: ScreenshotCommand) throws -> Set<Int64> {
    guard let id = edit.board, let source = screenshotSlots.first(where: { $0.boardID == id }),
      let target = edit.slot, (0..<10).contains(target), edit.row == nil || edit.row == source.row,
      let board = screenshotBoard(id)
    else {
      throw DrawingError.invalid("Move screenshots within their own device row.")
    }
    if source.index == target { return [board.content] }
    if let other = screenshotSlots.first(where: { $0.row == source.row && $0.index == target })?
      .boardID
    {
      updateScreenshotBoard(other) { $0["slot"] = .integer(Int64(source.index)) }
    }
    updateScreenshotBoard(id) { $0["slot"] = .integer(Int64(target)) }
    try reflowScreenshots()
    return [board.content]
  }
}
