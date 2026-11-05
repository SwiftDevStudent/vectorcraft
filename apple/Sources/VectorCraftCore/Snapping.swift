import CoreGraphics
import Foundation

public struct SnapGuide: Equatable, Sendable {
  public enum Axis: Sendable { case horizontal, vertical }
  public var axis: Axis
  public var value: CGFloat
  public var start: CGFloat
  public var end: CGFloat
}

public struct SnapResult: Equatable, Sendable {
  public var point: CGPoint
  public var guides: [SnapGuide] = []
}

/// Geometry only; the Mac canvas owns drag events, modifiers and haptic feedback.
public enum Snapping {
  public static let gridSpacing: CGFloat = 10
  public static let paletteSpacing: CGFloat = 8

  public static func grid(_ point: CGPoint, spacing: CGFloat) -> CGPoint {
    guard spacing.isFinite, spacing > 0, point.x.isFinite, point.y.isFinite else {
      return point
    }
    return CGPoint(
      x: (point.x / spacing).rounded() * spacing,
      y: (point.y / spacing).rounded() * spacing)
  }

  public static func position(
    _ point: CGPoint, moving: CGRect = .zero, targets: [CGRect],
    grid: Bool, guides: Bool, tolerance: CGFloat, constraint: MovementConstraint? = nil
  ) -> SnapResult {
    guard point.x.isFinite, point.y.isFinite else { return SnapResult(point: point) }
    if let constraint {
      return constrainedPosition(
        point, moving: moving, targets: targets, grid: grid, guides: guides,
        tolerance: tolerance, constraint: constraint)
    }
    let origin = CGPoint(x: point.x + moving.minX, y: point.y + moving.minY)
    let aligned = self.grid(origin, spacing: gridSpacing)
    var result = SnapResult(
      point: grid
        ? CGPoint(x: aligned.x - moving.minX, y: aligned.y - moving.minY) : point)
    guard guides, tolerance.isFinite, tolerance >= 0 else { return result }
    let moved = moving.offsetBy(dx: point.x, dy: point.y)
    for axis in [SnapGuide.Axis.vertical, .horizontal] {
      let vertical = axis == .vertical
      let positions =
        vertical ? [moved.minX, moved.midX, moved.maxX] : [moved.minY, moved.midY, moved.maxY]
      var best = tolerance + 0.000001
      var match: (CGFloat, CGFloat, CGRect)?
      for target in targets where usable(target) {
        let values =
          vertical
          ? [target.minX, target.midX, target.maxX] : [target.minY, target.midY, target.maxY]
        for value in values {
          for position in positions {
            let distance = abs(value - position)
            if distance < best {
              best = distance
              match = (value - position, value, target)
            }
          }
        }
      }
      if let (delta, value, target) = match {
        if vertical { result.point.x = point.x + delta } else { result.point.y = point.y + delta }
        result.guides.append(
          SnapGuide(
            axis: axis, value: value,
            start: vertical ? min(moved.minY, target.minY) : min(moved.minX, target.minX),
            end: vertical ? max(moved.maxY, target.maxY) : max(moved.maxX, target.maxX)))
      }
    }
    return result
  }

  private static func constrainedPosition(
    _ point: CGPoint, moving: CGRect, targets: [CGRect], grid: Bool, guides: Bool,
    tolerance: CGFloat, constraint: MovementConstraint
  ) -> SnapResult {
    let projected = constraint.project(point)
    let snapped = position(
      projected, moving: moving, targets: targets, grid: grid, guides: guides, tolerance: tolerance)
    let d = constraint.direction
    var candidates: [(amount: CGFloat, guided: Bool)] = []
    for axis in [SnapGuide.Axis.vertical, .horizontal] {
      let direction = axis == .vertical ? d.x : d.y
      guard direction != 0 else { continue }
      let guided = snapped.guides.contains { $0.axis == axis }
      if grid || guided {
        let correction =
          axis == .vertical ? snapped.point.x - projected.x : snapped.point.y - projected.y
        candidates.append((correction / direction, guided))
      }
    }
    let chosen =
      candidates.min {
        $0.guided == $1.guided ? abs($0.amount) < abs($1.amount) : $0.guided
      }?.amount ?? 0
    let aligned = CGPoint(x: projected.x + d.x * chosen, y: projected.y + d.y * chosen)
    let moved = moving.offsetBy(dx: aligned.x, dy: aligned.y)
    let actualGuides = snapped.guides.filter { guide in
      let positions =
        guide.axis == .vertical
        ? [moved.minX, moved.midX, moved.maxX] : [moved.minY, moved.midY, moved.maxY]
      return positions.contains { abs($0 - guide.value) < 0.000001 }
    }
    return SnapResult(point: aligned, guides: actualGuides)
  }

  public static func targets(
    in drawing: Drawing, excluding selected: Set<Int64>, within isolation: Int64? = nil
  ) -> [CGRect] {
    func visibleBounds(_ node: VectorNode) -> CGRect {
      guard node.visible else { return .null }
      if ["layer", "group"].contains(node.type) {
        return node.children.reduce(CGRect.null) { $0.union(visibleBounds($1)) }
      }
      return node.bounds
    }
    func containsSelection(_ node: VectorNode) -> Bool {
      selected.contains(node.id) || node.children.contains(where: containsSelection)
    }
    func collect(_ nodes: [VectorNode]) -> [CGRect] {
      nodes.flatMap { node -> [CGRect] in
        guard node.visible, !selected.contains(node.id) else { return [] }
        if node.type == "layer" || (node.type == "group" && containsSelection(node)) {
          return collect(node.children)
        }
        let bounds = visibleBounds(node)
        return usable(bounds) ? [bounds] : []
      }
    }
    return collect(drawing.selectionRoots(within: isolation)) + drawing.artboards.filter(usable)
  }

  private static func usable(_ rect: CGRect) -> Bool {
    !rect.isNull && [rect.minX, rect.minY, rect.maxX, rect.maxY].allSatisfy(\.isFinite)
  }
}
