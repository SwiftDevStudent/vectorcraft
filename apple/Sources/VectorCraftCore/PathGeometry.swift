import CoreGraphics
import Foundation

/// Lossless editable anchors for the line/quadratic/cubic elements emitted by Core Graphics.
public enum PathGeometry {
  public static func subpaths(_ path: CGPath) throws -> [VectorSubpath] {
    var result: [VectorSubpath] = []
    var anchors: [VectorAnchor] = []
    var count = 0
    var failure: DrawingError?
    func finish(closed: Bool) {
      if closed, anchors.count > 1, let first = anchors.first, let last = anchors.last,
        first.point == last.point
      {
        anchors[0].incoming = last.incoming
        anchors.removeLast()
      }
      if anchors.count >= 2 { result.append(VectorSubpath(anchors: anchors, closed: closed)) }
      anchors = []
    }
    path.applyWithBlock { pointer in
      guard failure == nil else { return }
      let element = pointer.pointee
      let points: [CGPoint]
      switch element.type {
      case .moveToPoint, .addLineToPoint: points = [element.points[0]]
      case .addQuadCurveToPoint: points = [element.points[0], element.points[1]]
      case .addCurveToPoint: points = [element.points[0], element.points[1], element.points[2]]
      case .closeSubpath: points = []
      @unknown default:
        failure = .invalid("Unsupported path geometry.")
        return
      }
      guard
        points.allSatisfy({
          $0.x.isFinite && $0.y.isFinite && abs($0.x) <= 1_000_000 && abs($0.y) <= 1_000_000
        }), count < 100_000
      else {
        failure = .invalid("The resulting path exceeds the supported geometry limits.")
        return
      }
      count += 1
      switch element.type {
      case .moveToPoint:
        finish(closed: false)
        if let point = points.first { anchors.append(VectorAnchor(point)) }
      case .addLineToPoint:
        if let point = points.first { anchors.append(VectorAnchor(point)) }
      case .addCurveToPoint:
        guard let first = points.first, let last = points.last, let previous = anchors.indices.last
        else { return }
        anchors[previous].outgoing = first
        anchors.append(VectorAnchor(last, incoming: points.dropFirst().first))
      case .addQuadCurveToPoint:
        guard let control = points.first, let end = points.last, let previous = anchors.indices.last
        else { return }
        let start = anchors[previous].point
        anchors[previous].outgoing = CGPoint(
          x: start.x + (control.x - start.x) * 2 / 3, y: start.y + (control.y - start.y) * 2 / 3)
        anchors.append(
          VectorAnchor(
            end,
            incoming: CGPoint(
              x: end.x + (control.x - end.x) * 2 / 3, y: end.y + (control.y - end.y) * 2 / 3)))
      case .closeSubpath: finish(closed: true)
      @unknown default: break
      }
    }
    if let failure { throw failure }
    finish(closed: false)
    return result
  }
}

public enum VectorFillRule: String, CaseIterable, Sendable {
  case nonZero = "NonZero"
  case evenOdd = "EvenOdd"
  public var label: String { self == .nonZero ? "Nonzero Winding" : "Even-Odd" }
}

public enum PathfinderOperation: String, CaseIterable, Sendable {
  case unite = "Unite"
  case minusFront = "Minus Front"
  case intersect = "Intersect"
  case exclude = "Exclude"
  case divide = "Divide"
  case trim = "Trim"
  case merge = "Merge"
  case crop = "Crop"
  case minusBack = "Minus Back"
}
