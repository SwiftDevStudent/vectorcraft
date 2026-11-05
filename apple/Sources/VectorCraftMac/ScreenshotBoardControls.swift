import AppKit
import SwiftUI
import VectorCraftCore

struct ScreenshotBoardControls: View {
  let document: CanvasDocument
  @Bindable var state: EditorState
  let board: ScreenshotBoard
  let library: ScreenshotDeviceLibrary
  let command: (DrawingCommand) -> Void
  let importScreenshot: (ScreenshotBoard) -> Void
  @State private var scale = 1.0
  @State private var cropX = 0.0
  @State private var cropY = 0.0
  @State private var fit = false

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {

      ScreenshotLayoutPicker(label: "Layout", selection: board.raw["template"].string,
        artboard: artboard, deviceSize: document.drawing.node(board.device)?.bounds.size ?? artboard.size,
        identifier: "screenshots.layout") { id in
        command(.screenshot(ScreenshotCommand(.setTemplate, board: board.id, template: id)))
      }
      if let row = document.drawing.screenshotRows.first(where: {
        $0.boards.contains(where: { $0.id == board.id })
      }),
        ["iphone-duo", "duo-inner", "duo-outer"].contains(row.raw["preset"].string)
      {
        Menu(
          "Display: "
            + (board.raw["display"].string == "duo-outer"
              || (board.raw["display"] == .null && row.raw["preset"].string == "duo-outer")
              ? "Outer" : "Inner")
        ) {
          Button("Inner") {
            command(
              .screenshot(ScreenshotCommand(.setDisplay, preset: "duo-inner", board: board.id)))
          }
          Button("Outer") {
            command(
              .screenshot(ScreenshotCommand(.setDisplay, preset: "duo-outer", board: board.id)))
          }
        }.accessibilityIdentifier("screenshots.duoDisplay")
      }
      Toggle(
        "Include in Export",
        isOn: Binding(
          get: { document.drawing.screenshotIsIncluded(board) },
          set: {
            command(.screenshot(ScreenshotCommand(.setExport, board: board.id, included: $0)))
          })
      )
      .accessibilityIdentifier("screenshots.include")
      HStack {
        Button(
          document.drawing.node(board.screen)?.children.contains(where: { $0.type == "image" })
            == true ? "Replace Screenshot…" : "Insert Screenshot…"
        ) { importScreenshot(board) }.accessibilityIdentifier("screenshots.import")
        Button {
          command(.screenshot(ScreenshotCommand(.rotateBoard, board: board.id)))
        } label: {
          Image(systemName: "rotate.right")
        }.accessibilityLabel("Rotate Artboard").accessibilityIdentifier("screenshots.rotate")
      }
      Menu("Device Frame") {
        Button("Choose Device Library…") { chooseLibrary() }
        ForEach(library.models, id: \.self) { model in
          Menu(model) {
            ForEach(library.choices.filter { $0.model == model }) { choice in
              Button(choice.name) { importFrame(board, choice: choice) }
            }
          }
        }
      }.accessibilityIdentifier("screenshots.frame")
      if let device = document.drawing.node(board.device) {
        Text(device.name).font(WorkspaceTheme.smallFont).foregroundStyle(WorkspaceTheme.dim)
      }
      DisclosureGroup("Image Crop") {
        Picker("Image", selection: $fit) {
          Text("Fill").tag(false)
          Text("Fit").tag(true)
        }
        TextField("Scale", value: $scale, format: .number).accessibilityIdentifier(
          "screenshots.scale")
        TextField("Crop X", value: $cropX, format: .number).accessibilityIdentifier(
          "screenshots.cropX")
        TextField("Crop Y", value: $cropY, format: .number).accessibilityIdentifier(
          "screenshots.cropY")
        Button("Apply Crop") {
          command(
            .screenshot(
              ScreenshotCommand(
                .crop, board: board.id, scale: scale, cropX: cropX, cropY: cropY, fit: fit)))
        }.accessibilityIdentifier("screenshots.applyCrop")
      }
      Button("Select Background") {
        state.selection = [board.background]
        state.dockTab = .properties
      }
      .accessibilityIdentifier("screenshots.background")
    }.onAppear(perform: refresh)
      .onChange(of: board.id) { _, _ in refresh() }
      .onChange(of: document.drawing) { _, _ in refresh() }
  }
  private var artboard: CGRect {
    guard let index = document.drawing.artboardIndex(id: board.id),
      document.drawing.artboards.indices.contains(index) else { return document.drawing.artboard }
    return document.drawing.artboards[index]
  }
  private func refresh() {
    let crop =
      document.drawing.node(board.screen)?.children.first(where: { $0.type == "image" })?.raw[
        "screenshotCrop"] ?? .null
    scale = crop["scale"].double ?? 1
    cropX = crop["x"].double ?? 0
    cropY = crop["y"].double ?? 0
    fit = crop["fit"].boolean ?? false
  }
  private func chooseLibrary() {
    do { try library.choose() } catch { state.error = error.localizedDescription }
  }
  private func importFrame(_ board: ScreenshotBoard, choice: ScreenshotFrameChoice) {
    do {
      command(
        .screenshot(
          ScreenshotCommand(.setFrame, board: board.id, frame: try library.reference(choice))))
    } catch { state.error = error.localizedDescription }
  }
}
