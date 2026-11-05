import SwiftUI

enum WorkspaceGlyph: String, CaseIterable {
  case selection = "dc-selection"
  case direct = "dc-direct"
  case lasso = "lasso"
  case rectangle = "square"
  case ellipse = "dc-ellipse"
  case polygon = "dc-polygon"
  case shaper = "shapes"
  case pencil = "pencil"
  case eraser = "eraser"
  case brush = "paintbrush"
  case pen = "pen-tool"
  case curvature = "spline"
  case width = "dc-width"
  case rotate = "rotate-ccw"
  case shapeBuilder = "dc-shape-builder"
  case areaType = "dc-type-area"
  case type = "type"
  case zoom = "zoom-in"
  case hand = "hand"
  case rotateView = "dc-rotate-view"
  case gradient = "dc-gradient"
  case eyedropper = "pipette"
  case star = "star"
  case line = "dc-line"
  case chevronsLeft = "chevrons-left"
  case chevronsRight = "chevrons-right"
  case chevronDown = "chevron-down"
  case home = "house"
  case search = "search"
  case community = "message-circle"
  case palette = "palette"
  case colorGuide = "dc-color-guide"
  case swatches = "swatch-book"
  case symbols = "spray-can"
  case pattern = "grid-3x3"
  case stroke = "dc-stroke"
  case transparency = "dc-transparency"
  case appearance = "dc-appearance"
  case graphicStyles = "dc-graphic-styles"
  case artboards = "dc-artboards"
  case transform = "dc-transform-panel"
  case align = "dc-align"
  case pathfinder = "dc-pathfinder"
  case paragraph = "pilcrow"
  case glyphs = "text-cursor-input"
  case history = "history"
  case actions = "dc-actions"
  case info = "info"
  case navigator = "map"
  case alignLeft = "align-start-vertical"
  case alignCenter = "align-center-vertical"
  case alignRight = "align-end-vertical"
  case alignTop = "align-start-horizontal"
  case alignMiddle = "align-center-horizontal"
  case alignBottom = "align-end-horizontal"
  case layers = "layers"
  case duplicate = "copy"
  case lock = "lock"
  case eye = "eye"
  case plus = "plus"
  case delete = "trash-2"
  case close = "x"
  case ruler = "ruler"
  case guides = "square-dashed"
  case smartGuides = "wand-sparkles"
}

struct WorkspaceIcon: View {
  var glyph: WorkspaceGlyph
  var size: CGFloat = 18
  var body: some View {
    if let url = Bundle.module.url(forResource: glyph.rawValue, withExtension: "pdf"),
      let native = NSImage(contentsOf: url)
    {
      Image(nsImage: native).resizable().renderingMode(.template)
        .scaledToFit().frame(width: size, height: size).accessibilityHidden(true)
    }
  }
}
