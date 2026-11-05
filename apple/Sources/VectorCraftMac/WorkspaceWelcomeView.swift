import SwiftUI

struct WorkspaceWelcomeView: View {
  var create: (Double, Double) -> Void
  var open: () -> Void
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 26) {
        Text("Welcome to VectorCraft").font(.system(size: 24, weight: .semibold))
        HStack(spacing: 14) {
          Button("New File") { create(800, 800) }
          Button("Open", action: open)
        }.buttonStyle(WorkspaceButtonStyle(bordered: true))
        Text("Quickly Start a New File").fontWeight(.semibold)
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 125), spacing: 24)], spacing: 30) {
          ForEach(WorkspacePreset.all) { preset in
            Button {
              create(preset.width, preset.height)
            } label: {
              VStack(spacing: 12) {
                Rectangle().fill(.white)
                  .frame(
                    width: min(60, 60 * preset.width / preset.height),
                    height: min(60, 60 * preset.height / preset.width)
                  )
                  .frame(height: 65).shadow(color: .black.opacity(0.25), radius: 0, x: 2, y: 2)
                Text(preset.name).fontWeight(.semibold)
                Text("\(Int(preset.width)) × \(Int(preset.height)) pt")
                  .font(WorkspaceTheme.smallFont).foregroundStyle(WorkspaceTheme.dim)
              }.frame(maxWidth: .infinity)
            }.buttonStyle(.plain)
          }
        }
      }.padding(40).frame(maxWidth: 950, alignment: .leading)
    }.background(WorkspaceTheme.tabStrip)
  }
}

struct WorkspacePreset: Identifiable {
  var name: String
  var width: Double
  var height: Double
  var id: String { name }
  static let all = [
    Self(name: "Letter", width: 612, height: 792), Self(name: "A4", width: 595.276, height: 841.89),
    Self(name: "Web 1920×1080", width: 1920, height: 1080),
    Self(name: "Phone 390×844", width: 390, height: 844),
    Self(name: "Postcard", width: 288, height: 432),
    Self(name: "Social Square Post", width: 1080, height: 1080),
  ]
}
