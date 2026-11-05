import CoreGraphics
import Foundation

public enum MovementConstraint: CaseIterable, Sendable {
  case horizontal, vertical, diagonalDown, diagonalUp

  public var direction: CGPoint {
    switch self {
    case .horizontal: CGPoint(x: 1, y: 0)
    case .vertical: CGPoint(x: 0, y: 1)
    case .diagonalDown: CGPoint(x: 1, y: 1)
    case .diagonalUp: CGPoint(x: 1, y: -1)
    }
  }
  public func project(_ delta: CGPoint) -> CGPoint {
    let d = direction
    let length = (delta.x * d.x + delta.y * d.y) / (d.x * d.x + d.y * d.y)
    return CGPoint(x: d.x * length, y: d.y * length)
  }
  public static func nearest(to delta: CGPoint) -> Self {
    allCases.min { $0.project(delta).distance(to: delta) < $1.project(delta).distance(to: delta) }
      ?? .horizontal
  }
}

public enum ResizeHandle: CaseIterable, Sendable {
  case topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left

  public func point(in rect: CGRect) -> CGPoint {
    switch self {
    case .topLeft: CGPoint(x: rect.minX, y: rect.minY)
    case .top: CGPoint(x: rect.midX, y: rect.minY)
    case .topRight: CGPoint(x: rect.maxX, y: rect.minY)
    case .right: CGPoint(x: rect.maxX, y: rect.midY)
    case .bottomRight: CGPoint(x: rect.maxX, y: rect.maxY)
    case .bottom: CGPoint(x: rect.midX, y: rect.maxY)
    case .bottomLeft: CGPoint(x: rect.minX, y: rect.maxY)
    case .left: CGPoint(x: rect.minX, y: rect.midY)
    }
  }
  public var opposite: Self {
    switch self {
    case .topLeft: .bottomRight
    case .top: .bottom
    case .topRight: .bottomLeft
    case .right: .left
    case .bottomRight: .topLeft
    case .bottom: .top
    case .bottomLeft: .topRight
    case .left: .right
    }
  }
}

public enum TransformGeometry {
  public static func resize(
    _ bounds: CGRect, handle: ResizeHandle, to point: CGPoint,
    proportional: Bool, fromCenter: Bool
  ) -> CGAffineTransform {
    let fixed =
      fromCenter ? CGPoint(x: bounds.midX, y: bounds.midY) : handle.opposite.point(in: bounds)
    let start = handle.point(in: bounds)
    let dx = start.x - fixed.x
    let dy = start.y - fixed.y
    let horizontal = handle != .top && handle != .bottom && abs(dx) > 0.000001
    let vertical = handle != .left && handle != .right && abs(dy) > 0.000001
    var sx = horizontal ? (point.x - fixed.x) / dx : 1
    var sy = vertical ? (point.y - fixed.y) / dy : 1
    if proportional {
      let magnitude = horizontal && vertical ? max(abs(sx), abs(sy)) : abs(horizontal ? sx : sy)
      sx = sx < 0 ? -magnitude : magnitude
      sy = sy < 0 ? -magnitude : magnitude
    }
    // Keep handles usable through a crossing without producing a zero-area object.
    func nonzero(_ scale: CGFloat) -> CGFloat {
      abs(scale) < 0.0001 ? (scale < 0 ? -0.0001 : 0.0001) : scale
    }
    return CGAffineTransform(translationX: fixed.x, y: fixed.y)
      .scaledBy(x: nonzero(sx), y: nonzero(sy)).translatedBy(x: -fixed.x, y: -fixed.y)
  }

  public static func rotation(
    from start: CGPoint, to end: CGPoint, around center: CGPoint, constrained: Bool
  ) -> CGAffineTransform {
    var angle =
      atan2(end.y - center.y, end.x - center.x) - atan2(start.y - center.y, start.x - center.x)
    if constrained { angle = (angle / (.pi / 4)).rounded() * (.pi / 4) }
    return CGAffineTransform(translationX: center.x, y: center.y).rotated(by: angle)
      .translatedBy(x: -center.x, y: -center.y)
  }
}
