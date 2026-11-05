import SwiftUI
import VectorCraftCore

struct ScreenshotLayoutGallery: View {
  let selection: String
  let artboard: CGRect
  let deviceSize: CGSize
  let identifier: String
  let choose: (String) -> Void

  var body: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
      ForEach(ScreenshotTemplate.all) { layout in
        Button { choose(layout.id) } label: {
          VStack(spacing: 5) {
            ScreenshotLayoutPreview(layout: layout.id, artboard: artboard, deviceSize: deviceSize)
              .frame(height: 100)
            Text(layout.name).font(WorkspaceTheme.smallFont)
          }.padding(6).frame(maxWidth: .infinity)
            .background(selection == layout.id ? WorkspaceTheme.selected : WorkspaceTheme.input)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(alignment: .topTrailing) {
              if selection == layout.id { Image(systemName: "checkmark.circle.fill").padding(5) }
            }
        }.buttonStyle(.plain)
          .accessibilityLabel(layout.name)
          .accessibilityValue(selection == layout.id ? "Selected" : "")
          .accessibilityAddTraits(selection == layout.id ? .isSelected : [])
          .accessibilityIdentifier(identifier + ".choice." + layout.id)
      }
    }.padding(10).frame(width: 320)
      .foregroundStyle(WorkspaceTheme.text).background(WorkspaceTheme.panel)
      .accessibilityIdentifier(identifier + ".gallery")
  }
}
