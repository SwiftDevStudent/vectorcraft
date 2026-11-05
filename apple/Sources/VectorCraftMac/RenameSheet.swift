import SwiftUI
import VectorCraftCore

struct RenameSheet: View {
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  var body: some View {
    Form {
      TextField("Name", text: $state.rename)
      HStack {
        Button("Cancel", role: .cancel) { state.renamedID = nil }
        Button("Rename") {
          if let id = state.renamedID { command(.rename(id, state.rename)) }
          state.renamedID = nil
        }.keyboardShortcut(.defaultAction)
      }
    }.padding()
  }
}
