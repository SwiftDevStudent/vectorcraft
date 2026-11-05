import AppKit
import VectorCraftCore

extension VectorCanvasView {
  func hit(_ point: CGPoint, selectingGroups: Bool = false) -> Int64? {
    drawing.hitTest(
      point, tolerance: 6 / zoom, selectingGroups: selectingGroups, within: state.isolationID)
  }
  override func selectAll(_ sender: Any?) {
    state.selection = drawing.selectableIDs(within: state.isolationID)
    needsDisplay = true
  }
}
