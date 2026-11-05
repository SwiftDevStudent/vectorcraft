import AppKit
import VectorCraftCore

extension VectorCanvasView {
  func drawScreenshotSlots(_ context: CGContext) {
    for slot in drawing.screenshotSlots where slot.boardID == nil {
      context.saveGState()
      context.setFillColor(WorkspaceTheme.pasteboard.blended(withFraction: 0.07, of: .white)?.cgColor ?? NSColor.darkGray.cgColor)
      context.fill(slot.rect)
      context.setStrokeColor(NSColor.secondaryLabelColor.cgColor)
      context.setLineWidth(1 / zoom)
      context.setLineDash(phase: 0, lengths: [6 / zoom, 5 / zoom])
      context.stroke(slot.rect.insetBy(dx: 1 / zoom, dy: 1 / zoom))
      context.restoreGState()
      let text = "\(slot.index + 1)\n+" as NSString
      let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
      text.draw(in: CGRect(x: slot.rect.minX, y: slot.rect.midY - 28 / zoom, width: slot.rect.width, height: 64 / zoom),
        withAttributes: [.font: NSFont.systemFont(ofSize: 20 / zoom), .foregroundColor: NSColor.secondaryLabelColor, .paragraphStyle: paragraph])
    }
  }
}
