import SwiftUI

struct WorkspaceDocumentBar: View {
  var name: String
  var zoom: Double
  var body: some View {
    HStack(spacing: 10) {
      Button {
        NSApp.sendAction(#selector(NSWindow.performClose(_:)), to: nil, from: nil)
      } label: {
        WorkspaceIcon(glyph: .close, size: 12)
      }.buttonStyle(.plain).accessibilityLabel("Close Document")
      Text(
        "\(name) @ \(zoom * 100, format: .number.precision(.fractionLength(0...2)))% (RGB/Preview)"
      )
      .font(WorkspaceTheme.semibold).lineLimit(1)
      Rectangle().fill(WorkspaceTheme.border).frame(width: 1)
      Spacer(minLength: 0)
    }.padding(.leading, 12).frame(height: 35)
      .background(WorkspaceTheme.tabStrip)
      .overlay(alignment: .bottom) { Rectangle().fill(WorkspaceTheme.border).frame(height: 1) }
  }
}
