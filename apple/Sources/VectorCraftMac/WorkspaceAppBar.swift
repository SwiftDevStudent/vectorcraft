import SwiftUI

struct WorkspaceAppBar: View {
  @Bindable var state: EditorState
  var body: some View {
    HStack(spacing: 8) {
      Image(nsImage: NSApp.applicationIconImage).resizable().scaledToFit()
        .frame(width: 22, height: 22).accessibilityHidden(true)
      Button {
        state.homePresented.toggle()
      } label: {
        WorkspaceIcon(glyph: .home)
      }
      .buttonStyle(WorkspaceButtonStyle(active: state.homePresented)).accessibilityLabel("Home")
      Spacer(minLength: 12)
      ViewThatFits(in: .horizontal) {
        Button {
          if let url = URL(string: "https://discord.gg/artcraft") { NSWorkspace.shared.open(url) }
        } label: {
          HStack(spacing: 5) {
            WorkspaceIcon(glyph: .community, size: 13)
            Text("Discord").font(WorkspaceTheme.semibold)
          }.foregroundStyle(.white).padding(.horizontal, 10).frame(height: 24)
            .background(Color(red: 88 / 255, green: 101 / 255, blue: 242 / 255), in: Capsule())
        }.buttonStyle(.plain).help("ArtCraft community on Discord")
        Color.clear.frame(width: 0, height: 24)
      }
      ViewThatFits(in: .horizontal) {
        Button {
          state.commandSearchPresented = true
        } label: {
          HStack(spacing: 6) {
            WorkspaceIcon(glyph: .search, size: 13)
            Text("Search Commands and Tools").font(WorkspaceTheme.smallFont)
          }.padding(.horizontal, 10).frame(height: 24)
            .background(WorkspaceTheme.input, in: Capsule())
        }.buttonStyle(.plain)
        Button {
          state.commandSearchPresented = true
        } label: {
          WorkspaceIcon(glyph: .search)
        }
        .buttonStyle(WorkspaceButtonStyle()).accessibilityLabel("Search Commands and Tools")
      }
      Menu("Essentials") {
        Button("Float Tools") { state.movePanel(.tools, to: state.toolsPosition) }
        Button("Float Properties") { state.movePanel(.properties, to: state.propertiesPosition) }
        Button("Reset Workspace") { state.resetWorkspace() }
        Divider()
        Toggle("Properties Panel", isOn: $state.inspectorPresented)
        Toggle("Two Tool Columns", isOn: $state.toolbarDouble)
        Toggle("Rulers", isOn: $state.rulersPresented)
        Toggle("Grid", isOn: $state.gridPresented)
        Toggle("Snap to Grid", isOn: $state.snapToGrid)
        Toggle("Smart Guides", isOn: $state.smartGuides)
        Toggle("Snap Palettes to Grid", isOn: $state.snapPalettes)
        Toggle("Snap Haptics", isOn: $state.snapHaptics)
      }.menuStyle(.borderlessButton).fixedSize()
    }.padding(.leading, 78).padding(.trailing, 14).frame(height: 44)
      .background(WorkspaceTheme.panel)
      .overlay { Text("VectorCraft").allowsHitTesting(false) }
      .overlay(alignment: .bottom) { Rectangle().fill(WorkspaceTheme.border).frame(height: 1) }
  }
}
