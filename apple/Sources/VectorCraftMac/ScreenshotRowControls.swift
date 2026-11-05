import SwiftUI
import VectorCraftCore

struct ScreenshotRowControls: View {
  let row: ScreenshotRow
  let drawing: Drawing
  let selected: Int64?
  let select: (ScreenshotBoard) -> Void
  let add: (ScreenshotSlot) -> Void
  let documentID: UUID
  let drop: ([ScreenshotDropItem], ScreenshotSlot) -> Bool
  let move: (Int64, Int) -> Void
  let failed: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(row.name).font(WorkspaceTheme.semibold)
      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 6) {
        ForEach(drawing.screenshotSlots.filter { $0.row == row.id }) { slot in
          let board = slot.boardID.flatMap(drawing.screenshotBoard)
          ScreenshotSlotCard(slot: slot, drawing: drawing, documentID: documentID, rowName: row.name,
            selected: slot.boardID != nil && slot.boardID == selected) {
            if let board { select(board) } else { add(slot) }
          } drop: { items, target in drop(items, target) } move: { id, index in move(id, index) } failed: { failed($0) }
        }
      }
    }
  }
}
