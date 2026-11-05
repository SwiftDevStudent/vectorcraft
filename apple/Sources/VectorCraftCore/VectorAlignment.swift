import CoreGraphics

public enum VectorAlignment: String, CaseIterable, Sendable {
  case left, horizontalCenter, right, top, verticalCenter, bottom
  func translation(from source: CGRect, to target: CGRect) -> CGPoint {
    switch self {
    case .left: CGPoint(x: target.minX - source.minX, y: 0)
    case .horizontalCenter: CGPoint(x: target.midX - source.midX, y: 0)
    case .right: CGPoint(x: target.maxX - source.maxX, y: 0)
    case .top: CGPoint(x: 0, y: target.minY - source.minY)
    case .verticalCenter: CGPoint(x: 0, y: target.midY - source.midY)
    case .bottom: CGPoint(x: 0, y: target.maxY - source.maxY)
    }
  }
}
