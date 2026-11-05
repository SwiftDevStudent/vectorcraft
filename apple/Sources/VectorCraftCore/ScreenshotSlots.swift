import CoreGraphics
import Foundation

public struct ScreenshotSlot: Identifiable, Sendable {
  public let row: String
  public let index: Int
  public let boardID: Int64?
  public let rect: CGRect
  public var id: String { "\(row)-\(index)" }
}

extension Drawing {
  /// Empty slots are workspace affordances, not native artboards or exportable artwork.
  public var screenshotSlots: [ScreenshotSlot] {
    var y = envelope["document"]["unknown"]["screenshots"]["originY"].double ?? 0
    var slots: [ScreenshotSlot] = []
    for row in screenshotRows {
      var x = 0.0, height = 0.0
      for index in 0..<10 {
        let board = row.boards.enumerated().first { ($0.element.raw["slot"].int ?? Int64($0.offset)) == Int64(index) }?.element
        let size = board.flatMap { artboardIndex(id: $0.id) }.map { artboards[$0].size }
          ?? CGSize(width: row.raw["width"].double ?? 1206, height: row.raw["height"].double ?? 2622)
        let rect = CGRect(x: x, y: y, width: size.width, height: size.height)
        slots.append(ScreenshotSlot(row: row.id, index: index, boardID: board?.id, rect: rect))
        x += rect.width + 160
        height = max(height, rect.height)
      }
      y += height + 160
    }
    return slots
  }

  public var screenshotWorkspaceBounds: CGRect {
    screenshotSlots.reduce(artboards.reduce(CGRect.null) { $0.union($1) }) { $0.union($1.rect) }
  }

  public func screenshotIsIncluded(_ board: ScreenshotBoard) -> Bool {
    let board = screenshotBoard(board.id) ?? board
    if let included = board.raw["included"].boolean { return included }
    if let used = board.raw["used"].boolean { return used }
    // Legacy documents did not track occupancy. Retain any user artwork rather than
    // guessing that an edited template is empty.
    if node(board.screen)?.children.contains(where: { $0.type == "image" }) == true { return true }
    guard let content = node(board.content), content.id != board.device else { return false }
    return content.children.contains { child in
      if child.id == board.device { return false }
      if child.type != "text" { return true }
      let text = child.raw["kind"]["runs"].array.map { $0["text"].string }.joined()
      return !["Find Every\nBusiness", "Made for\nEvery Day"].contains(text)
    }
  }

  public var includedScreenshotBoards: [ScreenshotBoard] {
    screenshotSlots.compactMap { $0.boardID.flatMap(screenshotBoard) }.filter(screenshotIsIncluded)
  }

  mutating func updateScreenshotBoard(_ id: Int64, _ edit: (inout JSONValue) -> Void) {
    var rows = envelope["document"]["unknown"]["screenshots"]["rows"].array
    for r in rows.indices {
      var boards = rows[r]["boards"].array
      for b in boards.indices where boards[b]["id"].int == id { edit(&boards[b]) }
      rows[r]["boards"] = .array(boards)
    }
    envelope["document"]["unknown"]["screenshots"]["rows"] = .array(rows)
  }

  mutating func markEditedScreenshots(comparedTo previous: Drawing) {
    for board in screenshotRows.flatMap(\.boards) where node(board.layer) != previous.node(board.layer) {
      updateScreenshotBoard(board.id) { $0["used"] = .bool(true) }
    }
  }

  /// Isolate a row's artwork so a neighboring cropped phone cannot bleed into this export.
  public func screenshotExportDrawing(_ board: ScreenshotBoard) throws -> Drawing {
    guard screenshotIsIncluded(board) else {
      throw DrawingError.invalid("This screenshot slot is empty or excluded from export.")
    }
    return try screenshotArtworkDrawing(board)
  }

  public func screenshotArtworkDrawing(_ board: ScreenshotBoard) throws -> Drawing {
    guard let index = artboardIndex(id: board.id), let layer = node(board.layer) else {
      throw DrawingError.invalid("The screenshot artwork is unavailable.")
    }
    var result = self
    result.envelope["document"]["layers"] = .array([layer.raw])
    result.envelope["document"]["artboards"] = .array([envelope["document"]["artboards"].array[index]])
    return result
  }
}
