import AppKit
import VectorCraftCore

extension VectorCanvasView {
  func snapAnchor(_ selection: NodeSelection) -> VectorAnchor? {
    guard let id = state.selection.first, let paths = drawing.node(id)?.subpaths,
      paths.indices.contains(selection.subpath)
    else { return nil }
    let anchors = paths[selection.subpath].anchors
    guard anchors.indices.contains(selection.anchor) else { return nil }
    return anchors[selection.anchor]
  }

  func snapped(
    _ point: CGPoint, moving: CGRect = .zero, event: NSEvent, constrainMovement: Bool = false
  ) -> CGPoint {
    let bypass = event.modifierFlags.contains(.control)
    let result = Snapping.position(
      point, moving: moving, targets: snapTargets,
      grid: state.snapToGrid && !bypass, guides: state.smartGuides && !bypass,
      tolerance: 6 / zoom, constraint: constrainMovement ? .nearest(to: point) : nil)
    snapGuides = result.guides
    snapFeedback.move(
      raw: toView(CGPoint(x: point.x + moving.minX, y: point.y + moving.minY)),
      aligned: toView(CGPoint(x: result.point.x + moving.minX, y: result.point.y + moving.minY)),
      in: self, event: event,
      enabled: state.snapHaptics && !bypass)
    return result.point
  }

  func drawSnapGuides(_ context: CGContext) {
    guard !snapGuides.isEmpty else { return }
    context.saveGState()
    defer { context.restoreGState() }
    context.setStrokeColor(WorkspaceTheme.alignmentGuide.cgColor)
    context.setLineWidth(1)
    for guide in snapGuides {
      let from =
        guide.axis == .vertical
        ? CGPoint(x: guide.value, y: guide.start) : CGPoint(x: guide.start, y: guide.value)
      let to =
        guide.axis == .vertical
        ? CGPoint(x: guide.value, y: guide.end) : CGPoint(x: guide.end, y: guide.value)
      context.move(to: toView(from))
      context.addLine(to: toView(to))
      context.strokePath()
    }
  }

  func endSnapping() {
    snapTargets = []
    snapGuides = []
    snapFeedback.end()
  }
}
