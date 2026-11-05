import CoreGraphics
import Foundation

public struct VectorAnchor: Equatable, Sendable {
  public var point: CGPoint
  public var incoming: CGPoint
  public var outgoing: CGPoint
  public var smooth: Bool

  public init(
    _ point: CGPoint, incoming: CGPoint? = nil, outgoing: CGPoint? = nil, smooth: Bool = false
  ) {
    self.point = point
    self.incoming = incoming ?? point
    self.outgoing = outgoing ?? point
    self.smooth = smooth
  }

  public init?(json: JSONValue) {
    guard let p = json["p"].point else { return nil }
    self.init(
      p, incoming: json["in"].point, outgoing: json["out"].point,
      smooth: json["kind"].string == "Smooth")
  }

  public func json(version: Int64) -> JSONValue {
    var value: JSONValue = .object(["p": point.json(version: version)])
    if incoming != point || version == 1 { value["in"] = incoming.json(version: version) }
    if outgoing != point || version == 1 { value["out"] = outgoing.json(version: version) }
    if smooth || version == 1 { value["kind"] = .string(smooth ? "Smooth" : "Corner") }
    return value
  }
}

public struct VectorSubpath: Equatable, Sendable {
  public var anchors: [VectorAnchor]
  public var closed: Bool
  public init(anchors: [VectorAnchor], closed: Bool) {
    self.anchors = anchors
    self.closed = closed
  }
  public var cgPath: CGPath {
    let path = CGMutablePath()
    guard let first = anchors.first else { return path }
    path.move(to: first.point)
    for (previous, next) in zip(anchors, anchors.dropFirst()) { addSegment(path, previous, next) }
    if closed, let last = anchors.last {
      addSegment(path, last, first)
      path.closeSubpath()
    }
    return path
  }
  private func addSegment(_ path: CGMutablePath, _ a: VectorAnchor, _ b: VectorAnchor) {
    if a.outgoing == a.point && b.incoming == b.point {
      path.addLine(to: b.point)
    } else {
      path.addCurve(to: b.point, control1: a.outgoing, control2: b.incoming)
    }
  }
  public func json(version: Int64) -> JSONValue {
    .object(["anchors": .array(anchors.map { $0.json(version: version) }), "closed": .bool(closed)])
  }
}

extension JSONValue {
  public var point: CGPoint? {
    if array.count == 2, let x = array.first?.double, let y = array.last?.double, x.isFinite,
      y.isFinite
    {
      return CGPoint(x: x, y: y)
    }
    if let x = self["x"].double, let y = self["y"].double, x.isFinite, y.isFinite {
      return CGPoint(x: x, y: y)
    }
    return nil
  }
  public var rect: CGRect? {
    guard let x0 = self["x0"].double, let y0 = self["y0"].double,
      let x1 = self["x1"].double, let y1 = self["y1"].double,
      [x0, y0, x1, y1].allSatisfy({ $0.isFinite && abs($0) <= 1_000_000 }), x1 > x0, y1 > y0
    else { return nil }
    return CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
  }
}

extension CGPoint {
  public func json(version: Int64 = 3) -> JSONValue {
    version == 1 ? .object(["x": .number(x), "y": .number(y)]) : .array([.number(x), .number(y)])
  }
  public func distance(to p: CGPoint) -> CGFloat { hypot(x - p.x, y - p.y) }
}
