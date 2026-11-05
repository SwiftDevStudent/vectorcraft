import SwiftUI
import UniformTypeIdentifiers
import VectorCraftCore

struct EditorView: View {
  @Bindable var document: CanvasDocument
  @Environment(\.undoManager) private var undoManager
  @Environment(\.documentConfiguration) private var configuration
  @Environment(\.newDocument) private var newDocument
  @Environment(\.scenePhase) private var scenePhase
  @State private var state = EditorState()
  @State private var deviceLibrary = ScreenshotDeviceLibrary()

  var body: some View {
    VStack(spacing: 0) {
      WorkspaceAppBar(state: state)
      HStack(spacing: 0) {
        HStack(spacing: 0) {
          if !state.toolsFloating {
            WorkspaceToolStrip(state: state, command: execute, editText: editText)
          }
          VStack(spacing: 0) {
            WorkspaceDocumentBar(
              name: configuration?.fileURL?.lastPathComponent ?? document.drawing.title,
              zoom: state.zoom)
            if state.isolationID != nil {
              WorkspaceIsolationBar(drawing: document.drawing, state: state)
            }
            if !document.renderingWarnings.isEmpty {
              DisclosureGroup("Limited Preview") {
                Text(
                  "This Swift port does not yet render \(document.renderingWarnings.joined(separator: ", ")). Native saving retains that data; artwork export is disabled."
                )
                .font(WorkspaceTheme.smallFont)
              }.padding(8).background(WorkspaceTheme.tabStrip)
            }
            if state.homePresented {
              WorkspaceWelcomeView(create: createDocument, open: openDocument)
            } else {
              CanvasRepresentable(
                drawing: document.drawing, state: state, command: execute,
                action: state.canvasAction, rulers: state.rulersPresented,
                grid: state.gridPresented,
                gradientTarget: state.gradientTarget, gradientStop: state.gradientStop,
                transformPreview: state.transformPreview(in: document.drawing),
                imageAccessRevision: deviceLibrary.revision
              )
              .overlay { WorkspaceContextOverlay(state: state, command: execute) }
              .padding(.top, 4)
              .background(Color(nsColor: WorkspaceTheme.pasteboard))
            }
          }.frame(maxWidth: .infinity, maxHeight: .infinity)
          WorkspacePanelRail(document: document, state: state, command: execute, editText: editText)
        }.frame(minWidth: 400)
        if state.inspectorPresented && !state.propertiesFloating {
          WorkspaceDockDivider(state: state)
          WorkspaceDock(document: document, state: state, command: execute, editText: editText)
            .frame(width: state.dockWidth)
        }
      }
      CanvasStatusBar(drawing: document.drawing, state: state)
    }.overlay(alignment: .topLeading) {
      WorkspaceFloatingPanels(
        document: document, state: state, command: execute, editText: editText)
    }.coordinateSpace(name: "workspace")
      .environment(deviceLibrary)
      .onGeometryChange(for: CGSize.self) {
        $0.size
      } action: {
        state.workspaceSize = $0
      }
      .font(WorkspaceTheme.font).foregroundStyle(WorkspaceTheme.text)
      .background(WorkspaceTheme.panel).preferredColorScheme(.dark)
      .background(WorkspaceWindowAppearance())
      .ignoresSafeArea(.container, edges: .top)
      .focusedSceneValue(
        \.editorActions,
        EditorActions(
          drawing: document.drawing,
          selectTool: { state.tool = $0 }, command: execute,
          fit: { state.canvasAction = .fit }, insertShape: insertShape, editText: editText,
          deleteSelection: deleteSelection, selected: state.selection,
          search: {
            state.commandQuery = ""
            state.commandSearchPresented = true
          }, export: export, exportEnabled: document.renderingWarnings.isEmpty,
          editingText: state.textEditingSession != nil,
          canvasHasFocus: state.canvasHasFocus,
          openPathfinder: { state.openPanel = .pathfinder },
          openGradient: { state.openPanel = .gradient },
          enterIsolation: {
            if let id = state.selection.first { state.enterIsolation(id, in: document.drawing) }
          }, exitIsolation: { state.exitIsolation(in: document.drawing) },
          canIsolate: state.canEnterIsolation(in: document.drawing),
          isIsolating: state.isolationID != nil, transformAgain: transformAgain,
          canTransformAgain: state.textEditingSession == nil && transformAgainCommand != nil,
          showTransform: { state.presentTransform($0, in: document.drawing) },
          canTransform: state.canTransform(in: document.drawing))
      )
      .onChange(of: state.selection) { _, selection in
        let scoped = selection.filter {
          document.drawing.isInside($0, isolation: state.isolationID)
        }
        if scoped != selection {
          state.selection = scoped
          return
        }
        state.nodeSelection = nil
        if let id = selection.first, let node = document.drawing.node(id) {
          state.loadStyle(node)
          if node.type == "layer" { state.activeLayer = id }
        }
      }
      .onChange(of: state.tool) { previous, _ in
        if previous == .pen, state.canvasAction != .cancelPath { state.canvasAction = .finishPath }
      }
      .onChange(of: document.drawing) { previous, drawing in
        if previous.screenshotRows.isEmpty, !drawing.screenshotRows.isEmpty { state.dockTab = .screenshots }
        state.reconcileArtboard(in: drawing)
        state.reconcileIsolation(in: drawing)
        if let id = state.selection.first, let node = drawing.node(id) { state.loadStyle(node) }
        if drawing.node(state.activeLayer) == nil {
          state.activeLayer = drawing.screenshotBoard(at: state.selectedArtboard)?.content ?? drawing.layers.last?.id ?? 1
        }
      }
      .onChange(of: state.selectedArtboard) { _, index in
        if let board = document.drawing.screenshotBoard(at: index) { state.activeLayer = board.content }
      }
      .onChange(of: scenePhase) { _, phase in
        if phase == .active { document.refreshRenderingWarnings() }
      }
      .onChange(of: deviceLibrary.revision) { _, _ in document.refreshRenderingWarnings() }
      .onAppear {
        deviceLibrary.restore()
        document.refreshRenderingWarnings()
        state.activeLayer = document.drawing.screenshotBoard(at: state.selectedArtboard)?.content ?? document.drawing.layers.last?.id ?? 1
        if !document.drawing.screenshotRows.isEmpty { state.dockTab = .screenshots }
      }
      .alert(
        "VectorCraft",
        isPresented: Binding(get: { state.error != nil }, set: { if !$0 { state.error = nil } })
      ) {
        Button("OK", role: .cancel) { state.error = nil }
      } message: {
        Text(state.error ?? "")
      }
      .sheet(
        isPresented: Binding(
          get: { state.renamedID != nil }, set: { if !$0 { state.renamedID = nil } })
      ) {
        RenameSheet(state: state, command: execute)
      }
      .sheet(
        isPresented: $state.commandSearchPresented,
        onDismiss: {
          if let kind = state.pendingTransformDialog {
            state.pendingTransformDialog = nil
            state.presentTransform(kind, in: document.drawing)
          }
        }
      ) {
        WorkspaceCommandSearch(
          document: document, state: state, command: execute, editText: editText)
      }
      .sheet(item: $state.transformDialog) { session in
        WorkspaceTransformDialog(session: session) { copy in
          do {
            let command = try session.command(copy: copy, in: document.drawing)
            state.transformDialog = nil
            execute(command)
          } catch {
            state.transformDialog = nil
            state.error = error.localizedDescription
          }
        }
      }
      .fileExporter(
        isPresented: $state.exportPresented, document: state.exportDocument,
        contentType: state.exportType,
        defaultFilename: document.drawing.title == "Untitled" ? "Drawing" : document.drawing.title
      ) { result in
        if case .failure(let error) = result { state.error = error.localizedDescription }
      }
  }

  private func execute(_ command: DrawingCommand) {
    do {
      if case .screenshot = command { state.isolationStack = [] }
      state.selection = try document.execute(
        command, undoManager: undoManager,
        coalescingTextSession: state.textEditingSession, within: state.isolationID)
      state.reconcileIsolation(in: document.drawing)
      if case .screenshot(let edit) = command, [.addBoard, .addRow, .placeScreenshots, .moveBoard].contains(edit.action),
        let board = document.drawing.screenshotRows.flatMap(\.boards).first(where: { state.selection.contains($0.content) }),
        let index = document.drawing.artboardIndex(id: board.id) {
        state.isolationStack = []; state.selectedArtboard = index; state.activeLayer = board.content
        state.canvasAction = .fit
      }
      if case .deleteAnchor = command { state.nodeSelection = nil }
    } catch { state.error = error.localizedDescription }
  }
  private func deleteSelection() { if let command = state.deletionCommand { execute(command) } }
  private var transformAgainCommand: DrawingCommand? {
    document.transformAgainCommand(for: state.selection, within: state.isolationID)
  }
  private func transformAgain() {
    guard state.textEditingSession == nil, let command = transformAgainCommand else { return }
    execute(command)
  }
  private func insertShape(_ tool: EditorTool) {
    let board =
      document.drawing.artboards.indices.contains(state.selectedArtboard)
      ? document.drawing.artboards[state.selectedArtboard] : document.drawing.artboard
    let rect = CGRect(x: board.midX - 80, y: board.midY - 60, width: 160, height: 120)
    let path: VectorSubpath
    switch tool {
    case .ellipse: path = ShapePaths.ellipse(rect)
    case .star: path = ShapePaths.star(rect)
    default: path = ShapePaths.rectangle(rect)
    }
    execute(.addPath([path], state.style, layer: state.insertionContainer(in: document.drawing)))
    state.tool = .select
  }
  private func editText() {
    state.tool = .text
    state.canvasAction = .editText
  }
  private func createDocument(_ width: Double, _ height: Double) {
    newDocument(CanvasDocument(drawing: Drawing(width: width, height: height)))
  }
  private func openDocument() { NSDocumentController.shared.openDocument(nil) }
  private func export(_ type: UTType) {
    do {
      let selected = document.drawing.screenshotBoard(at: state.selectedArtboard)
      let drawing = try selected.map { try document.drawing.screenshotExportDrawing($0) } ?? document.drawing
      let artboard = selected == nil ? state.selectedArtboard : 0
      let data: Data
      if type == .svg {
        data = try SVGExport.encode(drawing, artboard: artboard)
      } else if type == .pdf {
        data = try PDFExport.encode(drawing, artboard: artboard)
      } else {
        data = try VectorRenderer.png(drawing, artboard: artboard)
      }
      state.exportDocument = ExportDocument(data: data)
      state.exportType = type
      state.exportPresented = true
    } catch { state.error = error.localizedDescription }
  }
}
