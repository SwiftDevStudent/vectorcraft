import SwiftUI
import UniformTypeIdentifiers
import VectorCraftCore

enum EditorTool: String, CaseIterable, Identifiable {
  case select = "Select"
  case nodes = "Nodes"
  case pen = "Pen"
  case pencil = "Pencil"
  case rectangle = "Rectangle"
  case ellipse = "Ellipse"
  case star = "Star"
  case line = "Line"
  case hand = "Hand"
  case text = "Type"
  case polygon = "Polygon"
  case zoom = "Zoom"
  case rotate = "Rotate"
  case eyedropper = "Eyedropper"
  case gradient = "Gradient"
  var id: Self { self }
  var symbol: String {
    switch self {
    case .select: "cursorarrow"
    case .nodes: "point.topleft.down.to.point.bottomright.curvepath"
    case .pen: "point.bottomleft.forward.to.point.topright.scurvepath"
    case .pencil: "pencil.tip"
    case .rectangle: "rectangle"
    case .ellipse: "circle"
    case .star: "star"
    case .line: "line.diagonal"
    case .hand: "hand.draw"
    case .text: "textformat"
    case .polygon: "pentagon"
    case .zoom: "plus.magnifyingglass"
    case .rotate: "arrow.counterclockwise"
    case .eyedropper: "eyedropper"
    case .gradient: "slider.horizontal.3"
    }
  }
}

@MainActor @Observable
final class EditorState {
  var tool: EditorTool = .select
  var selection = Set<Int64>()
  var isolationStack: [Int64] = []
  var activeLayer: Int64 = 1
  var style = VectorStyle()
  var gradientTarget: PaintTarget = .fill {
    didSet { if oldValue != gradientTarget { gradientStop = 0 } }
  }
  var gradientStop = 0
  var fillColor = Color(red: 0.25, green: 0.35, blue: 0.95)
  var strokeColor = Color(red: 0.12, green: 0.14, blue: 0.23)
  var fillEnabled = true
  var strokeEnabled = true
  var inspectorPresented = true
  var toolbarDouble = true
  var rulersPresented = false
  var gridPresented = false
  var clipScreenshotArtwork = true
  var imagePreviewsLoading = false
  var imagePreviewsUnavailable = false
  var snapToGrid = false
  var smartGuides = true
  var snapPalettes = true
  var snapHaptics = true
  var homePresented = false
  var commandSearchPresented = false
  var commandQuery = ""
  var transformDialog: TransformDialogSession?
  var pendingTransformDialog: TransformDialogKind?
  var dockTab: WorkspaceDockTab = .properties
  var dockWidth = WorkspaceTheme.dockWidth
  var toolsFloating = false
  var propertiesFloating = false
  var toolsPosition = CGPoint(x: 100, y: 100)
  var propertiesPosition = CGPoint(x: 700, y: 100)
  var workspaceSize = CGSize(width: 1470, height: 923)
  var openPanel: WorkspacePanel?
  var pointer: CGPoint?
  var selectionInCanvas: CGRect?
  var error: String?
  var canvasAction: CanvasAction?
  var zoom: Double = 1
  var textSize = 32.0
  var textFont = "Helvetica"
  var textEditingSession: UUID?
  var canvasHasFocus = false
  var renamedID: Int64?
  var rename = ""
  var exportPresented = false
  var exportDocument: ExportDocument?
  var exportType: UTType = .png
  var selectedArtboard = 0
  var nodeSelection: NodeSelection?
  func reconcileArtboard(in drawing: Drawing) {
    guard !drawing.artboards.indices.contains(selectedArtboard) else { return }
    selectedArtboard = min(max(0, selectedArtboard), max(0, drawing.artboards.count - 1))
    activeLayer = drawing.screenshotBoard(at: selectedArtboard)?.content ?? drawing.layers.last?.id ?? 1
    canvasAction = .fit
  }
  var deletionCommand: DrawingCommand? {
    guard !selection.isEmpty else { return nil }
    if tool == .gradient { return .gradient(selection, gradientTarget, .removeStop(gradientStop)) }
    if tool == .nodes, selection.count == 1, let id = selection.first, let nodeSelection {
      return .deleteAnchor(id, subpath: nodeSelection.subpath, anchor: nodeSelection.anchor)
    }
    return .delete(selection)
  }

  func loadStyle(_ node: VectorNode) {
    if node.type == "layer" { return }
    if node.type == "group", let first = node.children.first {
      loadStyle(first)
      style.opacity = node.opacity
      return
    }
    style = VectorStyle(node: node)
    let gradientPaint = gradientTarget == .fill ? style.fill : style.stroke
    gradientStop = min(
      max(0, gradientStop), max(0, gradientPaint["gradient"]["stops"].array.count - 1))
    fillEnabled = style.fill["type"].string != "none"
    strokeEnabled = style.stroke["type"].string != "none"
    if style.fill["type"].string == "solid" {
      fillColor = Color(cgColor: VectorRenderer.color(style.fill["color"]))
    }
    if style.stroke["type"].string == "solid" {
      strokeColor = Color(cgColor: VectorRenderer.color(style.stroke["color"]))
    }
  }

  func setFill() { style.fill = fillEnabled ? paint(fillColor) : VectorStyle.none }
  func setStroke() { style.stroke = strokeEnabled ? paint(strokeColor) : VectorStyle.none }
  private func paint(_ color: Color) -> JSONValue {
    let rgb = NSColor(color).usingColorSpace(.sRGB) ?? .black
    return VectorStyle.solid(rgb.redComponent, rgb.greenComponent, rgb.blueComponent)
  }

  func isFloating(_ panel: WorkspacePanelKind) -> Bool {
    panel == .tools ? toolsFloating : propertiesFloating
  }
  func panelPosition(_ panel: WorkspacePanelKind) -> CGPoint {
    panel == .tools ? toolsPosition : propertiesPosition
  }
  func movePanel(_ panel: WorkspacePanelKind, to position: CGPoint, bypassSnapping: Bool = false) {
    let width = panel == .tools ? (toolbarDouble ? 76.0 : 48.0) : dockWidth
    let position =
      snapPalettes && !bypassSnapping
      ? Snapping.grid(position, spacing: Snapping.paletteSpacing) : position
    let point = CGPoint(
      x: min(max(0, position.x), max(0, workspaceSize.width - width)),
      y: min(max(44, position.y), max(44, workspaceSize.height - 140)))
    if panel == .tools {
      toolsFloating = true
      toolsPosition = point
    } else {
      propertiesFloating = true
      propertiesPosition = point
      inspectorPresented = true
    }
  }
  func dockPanel(_ panel: WorkspacePanelKind) {
    if panel == .tools { toolsFloating = false } else { propertiesFloating = false }
  }
  func resetWorkspace() {
    toolsFloating = false
    propertiesFloating = false
    inspectorPresented = true
    dockWidth = WorkspaceTheme.dockWidth
    toolbarDouble = true
  }
}

enum WorkspacePanelKind { case tools, properties }

enum CanvasAction: Equatable { case fit, fitWorkspace, actualSize, finishPath, closePath, cancelPath, editText }
struct NodeSelection: Equatable {
  var subpath: Int
  var anchor: Int
  var handle: String?
}

struct EditorActions {
  var drawing: Drawing
  var selectTool: (EditorTool) -> Void
  var command: (DrawingCommand) -> Void
  var fit: () -> Void
  var insertShape: (EditorTool) -> Void
  var editText: () -> Void
  var deleteSelection: () -> Void
  var selected: Set<Int64>
  var search: () -> Void
  var export: (UTType) -> Void
  var exportEnabled: Bool
  var editingText: Bool
  var canvasHasFocus: Bool
  var openPathfinder: () -> Void
  var openGradient: () -> Void
  var enterIsolation: () -> Void
  var exitIsolation: () -> Void
  var canIsolate: Bool
  var isIsolating: Bool
  var transformAgain: () -> Void
  var canTransformAgain: Bool
  var showTransform: (TransformDialogKind) -> Void
  var canTransform: Bool
}

struct EditorActionsKey: FocusedValueKey { typealias Value = EditorActions }
extension FocusedValues {
  var editorActions: EditorActions? {
    get { self[EditorActionsKey.self] }
    set { self[EditorActionsKey.self] = newValue }
  }
}
