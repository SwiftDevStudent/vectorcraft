import SwiftUI

/// Matches the Rust app's Medium Dark tokens and explicit workspace metrics.
enum WorkspaceTheme {
  static let panel = Color(hex: 0x535353)
  static let tabStrip = Color(hex: 0x424242)
  static let input = Color(hex: 0x454545)
  static let inputBorder = Color(hex: 0x5f5f5f)
  static let border = Color(hex: 0x383838)
  static let divider = Color(hex: 0x4b4b4b)
  static let text = Color(hex: 0xd1d1d1)
  static let dim = Color(hex: 0xb0b0b0)
  static let disabled = Color(hex: 0x7a7a7a)
  static let icon = Color(hex: 0xc2c2c2)
  static let hover = Color(hex: 0x606060)
  static let active = Color(hex: 0x303030)
  static let selected = Color(hex: 0x52677c)
  static let pasteboard = NSColor(srgbRed: 96 / 255, green: 96 / 255, blue: 96 / 255, alpha: 1)
  static let alignmentGuide = NSColor.magenta
  static let selection = NSColor(srgbRed: 79 / 255, green: 128 / 255, blue: 1, alpha: 1)
  static let font = Font.custom("SourceSans3-Regular", fixedSize: 13)
  static let semibold = Font.custom("SourceSans3-Semibold", fixedSize: 12.5)
  static let smallFont = Font.custom("SourceSans3-Regular", fixedSize: 11)
  static let dockWidth: CGFloat = 300
}

extension Color {
  fileprivate init(hex: UInt32) {
    self.init(
      .sRGB, red: Double((hex >> 16) & 255) / 255,
      green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
  }
}

struct WorkspaceButtonStyle: ButtonStyle {
  var active = false
  var bordered = false
  @Environment(\.isEnabled) private var enabled
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(enabled ? WorkspaceTheme.text : WorkspaceTheme.disabled)
      .padding(.horizontal, bordered ? 10 : 4).padding(.vertical, 4)
      .background(active || configuration.isPressed ? WorkspaceTheme.active : WorkspaceTheme.panel)
      .overlay {
        if bordered { RoundedRectangle(cornerRadius: 2).stroke(WorkspaceTheme.inputBorder) }
      }
      .clipShape(RoundedRectangle(cornerRadius: 2))
  }
}

struct WorkspaceFieldStyle: TextFieldStyle {
  func _body(configuration: TextField<Self._Label>) -> some View {
    configuration.textFieldStyle(.plain).padding(.horizontal, 6).padding(.vertical, 5)
      .background(WorkspaceTheme.input)
      .overlay(RoundedRectangle(cornerRadius: 2).stroke(WorkspaceTheme.inputBorder))
      .clipShape(RoundedRectangle(cornerRadius: 2))
  }
}

struct WorkspaceSeparator: View {
  var body: some View { Rectangle().fill(WorkspaceTheme.divider).frame(height: 1) }
}
