import SwiftUI
import VectorCraftCore

/// Original vector schematics; opening a layout chooser never resolves image resources.
struct ScreenshotLayoutPreview: View {
  let layout: String
  let artboard: CGRect
  let deviceSize: CGSize

  var body: some View {
    Canvas { context, size in
      guard artboard.width > 0, artboard.height > 0 else { return }
      let scale = min((size.width - 8) / artboard.width, (size.height - 8) / artboard.height)
      guard scale > 0 else { return }
      var context = context
      context.translateBy(x: (size.width - artboard.width * scale) / 2,
        y: (size.height - artboard.height * scale) / 2)
      context.scaleBy(x: scale, y: scale)
      let board = CGRect(origin: .zero, size: artboard.size)
      context.clip(to: Path(board))
      context.fill(Path(board), with: .color(Color(red: 0.69, green: 0.85, blue: 0.95)))
      let device = ScreenshotTemplate.deviceFrame(layout, source: deviceSize, in: board)
      if !device.isNull {
        let inset = min(device.width, device.height) * 0.06
        context.fill(Path(roundedRect: device, cornerRadius: inset * 2), with: .color(.black.opacity(0.85)))
        context.fill(Path(roundedRect: device.insetBy(dx: inset, dy: inset), cornerRadius: inset),
          with: .color(.white.opacity(0.95)))
      }
      if layout != "minimal" {
        let text = ScreenshotTemplate.textRect(layout, in: board)
        for line in 0..<2 {
          let width = text.width * (line == 0 ? 0.8 : 0.6)
          let bar = CGRect(x: text.midX - width / 2,
            y: text.minY + text.height * (0.2 + Double(line) * 0.3),
            width: width, height: board.height * 0.015)
          context.fill(Path(bar), with: .color(.black.opacity(0.8)))
        }
      }
    }.accessibilityHidden(true)
  }
}
