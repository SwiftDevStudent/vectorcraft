import SwiftUI
import VectorCraftCore

enum WorkspacePanel: String, Identifiable, CaseIterable {
  case color = "Color"
  case colorGuide = "Color Guide"
  case swatches = "Swatches"
  case brushes = "Brushes"
  case symbols = "Symbols"
  case pattern = "Pattern Options"
  case stroke = "Stroke"
  case gradient = "Gradient"
  case transparency = "Transparency"
  case appearance = "Appearance"
  case graphicStyles = "Graphic Styles"
  case artboards = "Artboards"
  case transform = "Transform"
  case align = "Align"
  case pathfinder = "Pathfinder"
  case character = "Character"
  case paragraph = "Paragraph"
  case glyphs = "Glyphs"
  case history = "History"
  case actions = "Actions"
  case info = "Info"
  case navigator = "Navigator"
  var id: Self { self }
  var supported: Bool {
    [
      .color, .stroke, .transparency, .appearance, .artboards, .transform, .align,
      .character, .history, .info, .navigator, .pathfinder, .gradient,
    ].contains(self)
  }
  var glyph: WorkspaceGlyph {
    switch self {
    case .color: .palette
    case .colorGuide: .colorGuide
    case .swatches: .swatches
    case .brushes: .brush
    case .symbols: .symbols
    case .pattern: .pattern
    case .stroke: .stroke
    case .gradient: .gradient
    case .transparency: .transparency
    case .appearance: .appearance
    case .graphicStyles: .graphicStyles
    case .artboards: .artboards
    case .transform: .transform
    case .align: .align
    case .pathfinder: .pathfinder
    case .character: .type
    case .paragraph: .paragraph
    case .glyphs: .glyphs
    case .history: .history
    case .actions: .actions
    case .info: .info
    case .navigator: .navigator
    }
  }
  static let groups: [[Self]] = [
    [.color, .colorGuide], [.swatches, .brushes, .symbols, .pattern],
    [.stroke, .gradient, .transparency], [.appearance, .graphicStyles], [.artboards],
    [.transform, .align, .pathfinder], [.character, .paragraph, .glyphs],
    [.history, .actions, .info, .navigator],
  ]
}

struct WorkspacePanelRail: View {
  var document: CanvasDocument
  @Bindable var state: EditorState
  var command: (DrawingCommand) -> Void
  var editText: () -> Void
  var body: some View {
    ScrollView(.vertical) {
      VStack(spacing: 2) {
        ForEach(Array(WorkspacePanel.groups.enumerated()), id: \.offset) { index, group in
          if index > 0 { WorkspaceSeparator().padding(.horizontal, 5).padding(.vertical, 3) }
          ForEach(group) { panel in
            Button {
              state.openPanel = state.openPanel == panel ? nil : panel
            } label: {
              WorkspaceIcon(glyph: panel.glyph).frame(width: 22, height: 22)
            }.buttonStyle(WorkspaceButtonStyle(active: state.openPanel == panel))
              .disabled(!panel.supported).accessibilityLabel(panel.rawValue)
              .help(
                panel.supported
                  ? panel.rawValue : "\(panel.rawValue) is not yet available in the Swift port")
          }
        }
        if !state.inspectorPresented {
          Button {
            state.inspectorPresented = true
          } label: {
            WorkspaceIcon(glyph: .chevronsLeft)
          }
          .buttonStyle(WorkspaceButtonStyle()).accessibilityLabel("Expand Properties Panel")
        }
      }.padding(.vertical, 6)
    }.scrollIndicators(.hidden).frame(width: 38).background(WorkspaceTheme.panel)
      .overlay(alignment: .leading) { Rectangle().fill(WorkspaceTheme.border).frame(width: 1) }
      .popover(item: $state.openPanel, arrowEdge: .leading) { panel in
        WorkspacePanelContent(
          panel: panel, document: document, state: state, command: command, editText: editText)
      }
  }
}
