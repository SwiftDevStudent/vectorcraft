import SwiftUI
import VectorCraftCore

struct ScreenshotSlotCard: View {
  let slot: ScreenshotSlot
  let drawing: Drawing
  let documentID: UUID
  let rowName: String
  let selected: Bool
  let activate: () -> Void
  let drop: ([ScreenshotDropItem], ScreenshotSlot) -> Bool
  let move: (Int64, Int) -> Void
  let failed: (String) -> Void
  @State private var importTask: Task<Void, Never>?
  @State private var targeted = false

  var body: some View {
    let board = slot.boardID.flatMap(drawing.screenshotBoard)
    ZStack {
      Button(action: activate) {
      VStack(spacing: 4) {
        Group {
          if let board {
            ScreenshotThumbnail(drawing: drawing, board: board)
          } else {
            Image(systemName: "plus").frame(maxWidth: .infinity, maxHeight: .infinity)
          }
        }.frame(height: 70)
        HStack(spacing: 3) {
          Text("\(slot.index + 1)")
          if let board, drawing.screenshotIsIncluded(board) {
            Image(systemName: "circle.fill").imageScale(.small)
          }
        }
      }.frame(maxWidth: .infinity).padding(.vertical, 4)
    }.buttonStyle(WorkspaceButtonStyle(active: selected || targeted, bordered: true))
      .contentShape(Rectangle())
      .modifier(ScreenshotCardDrag(board: board, documentID: documentID))
    }
      .overlay {
        if targeted {
          RoundedRectangle(cornerRadius: 2).stroke(
            Color(nsColor: WorkspaceTheme.selection), lineWidth: 2)
        }
      }
      .accessibilityLabel("\(rowName), Slot \(slot.index + 1)\(board == nil ? ", Empty" : "")")
      .accessibilityIdentifier("screenshots.slot.\(slot.row).\(slot.index)")
      .accessibilityValue(selected ? "Selected" : "")
      .onDrop(of: [ScreenshotDropItem.contentType, .fileURL, .image], isTargeted: $targeted) { providers in
        guard !providers.isEmpty, providers.count <= 10 else {
          failed("Drop up to ten PNG or JPEG files.")
          return false
        }
        importTask?.cancel()
        importTask = Task {
          do {
            var items: [ScreenshotDropItem] = []
            for provider in providers { items.append(try await ScreenshotDropItem.load(provider)) }
            guard !Task.isCancelled else { return }
            _ = drop(items, slot)
          } catch { if !Task.isCancelled { failed(error.localizedDescription) } }
        }
        return true
      }
      .onDisappear { importTask?.cancel() }
      .contextMenu {
        if let board {
          Menu("Move to Slot") {
            ForEach(drawing.screenshotSlots.filter { $0.row == slot.row && $0.index != slot.index })
            { target in
              Button(
                target.boardID == nil
                  ? "Slot \(target.index + 1)" : "Swap with Slot \(target.index + 1)"
              ) { move(board.id, target.index) }
            }
          }
        }
      }
  }
}

private struct ScreenshotCardDrag: ViewModifier {
  let board: ScreenshotBoard?
  let documentID: UUID
  func body(content: Content) -> some View {
    if let board {
      content.onDrag {
        ScreenshotBoardDrag(document: documentID, board: board.id).itemProvider()
      }
    } else { content }
  }
}
