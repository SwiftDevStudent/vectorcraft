import SwiftUI
import VectorCraftCore

struct ScreenshotLayoutPicker: View {
  let label: String
  let selection: String
  let artboard: CGRect
  let deviceSize: CGSize
  let identifier: String
  let choose: (String) -> Void
  @State private var presented = false

  var body: some View {
    let name = ScreenshotTemplate.all.first { $0.id == selection }?.name ?? "Custom"
    Button { presented.toggle() } label: {
      HStack {
        Text(label + ": " + name)
        Spacer(minLength: 8)
        Image(systemName: "chevron.up.chevron.down")
      }
    }.accessibilityLabel(label + ": " + name)
      .accessibilityIdentifier(identifier)
      .popover(isPresented: $presented, arrowEdge: .trailing) {
        ScreenshotLayoutGallery(selection: selection, artboard: artboard, deviceSize: deviceSize,
          identifier: identifier) { id in
          choose(id)
          presented = false
        }
      }
  }
}
