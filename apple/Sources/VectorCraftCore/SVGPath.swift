import CoreGraphics
import Foundation

enum SVGPath {
  static func parse(_ text: String) throws -> CGPath {
    var s = SVGNumbers(text)
    let path = CGMutablePath()
    var current = CGPoint.zero
    var start = CGPoint.zero
    var command: UInt8?
    var cubic: CGPoint?
    var quadratic: CGPoint?
    var count = 0
    var moved = false
    func point(_ relative: Bool) throws -> CGPoint {
      let x = try s.number()
      let y = try s.number()
      return CGPoint(x: x + (relative ? current.x : 0), y: y + (relative ? current.y : 0))
    }
    while true {
      s.spaces()
      guard let next = s.next else { break }
      if (65...90).contains(next) || (97...122).contains(next) {
        command = next
        s.index += 1
      }
      guard let op = command else { throw svgError("Path data needs a command.") }
      let lower = op | 32
      let relative = op >= 97
      guard moved || lower == 109 else { throw svgError("Path data must begin with moveto.") }
      count += 1
      guard count <= 100_000 else { throw svgError("Too many path segments.") }
      switch lower {
      case 109:
        current = try point(relative)
        start = current
        path.move(to: current)
        moved = true
        command = relative ? 108 : 76
      case 108:
        current = try point(relative)
        path.addLine(to: current)
      case 104:
        current.x = try s.number() + (relative ? current.x : 0)
        path.addLine(to: current)
      case 118:
        current.y = try s.number() + (relative ? current.y : 0)
        path.addLine(to: current)
      case 99, 115:
        let c1 =
          lower == 99
          ? try point(relative)
          : cubic.map { CGPoint(x: current.x * 2 - $0.x, y: current.y * 2 - $0.y) } ?? current
        let c2 = try point(relative)
        let end = try point(relative)
        path.addCurve(to: end, control1: c1, control2: c2)
        cubic = c2
        current = end
      case 113, 116:
        let control =
          lower == 113
          ? try point(relative)
          : quadratic.map { CGPoint(x: current.x * 2 - $0.x, y: current.y * 2 - $0.y) } ?? current
        let end = try point(relative)
        path.addQuadCurve(to: end, control: control)
        quadratic = control
        current = end
      case 97:
        let rx = try s.number()
        let ry = try s.number()
        let angle = try s.number()
        let large = try s.flag()
        let sweep = try s.flag()
        let end = try point(relative)
        count += try arc(
          path, from: current, to: end, rx: abs(rx), ry: abs(ry), angle: angle, large: large,
          sweep: sweep)
        guard count <= 100_000 else { throw svgError("Too many arc segments.") }
        current = end
      case 122:
        path.closeSubpath()
        current = start
        command = nil
      default: throw svgError("Unsupported path command: \(Character(UnicodeScalar(op))).")
      }
      if lower != 99 && lower != 115 { cubic = nil }
      if lower != 113 && lower != 116 { quadratic = nil }
      guard current.x.isFinite, current.y.isFinite, abs(current.x) <= 1_000_000,
        abs(current.y) <= 1_000_000
      else { throw svgError("Path coordinates exceed supported limits.") }
    }
    return path
  }

  /// SVG endpoint-to-center parameterization; short cubic segments retain editable anchors.
  private static func arc(
    _ path: CGMutablePath, from a: CGPoint, to b: CGPoint, rx inputRX: Double, ry inputRY: Double,
    angle: Double, large: Bool, sweep: Bool
  ) throws -> Int {
    if a == b { return 0 }
    if inputRX == 0 || inputRY == 0 {
      path.addLine(to: b)
      return 1
    }
    let phi = angle.truncatingRemainder(dividingBy: 360) * .pi / 180
    let cp = cos(phi)
    let sp = sin(phi)
    let dx = (a.x - b.x) / 2
    let dy = (a.y - b.y) / 2
    let x = cp * dx + sp * dy
    let y = -sp * dx + cp * dy
    let scale = max(1, hypot(x / inputRX, y / inputRY))
    let rx = inputRX * scale
    let ry = inputRY * scale
    guard rx.isFinite, ry.isFinite, rx > 0, ry > 0, rx <= 1_000_000, ry <= 1_000_000 else {
      throw svgError("Elliptical arc exceeds supported limits.")
    }
    // Normalize before computing the center: products of radii and tiny endpoint
    // differences otherwise underflow/overflow even when every input is finite.
    let nx = x / rx
    let ny = y / ry
    let norm = hypot(nx, ny)
    if norm == 0 {
      path.addLine(to: b)
      return 1
    }
    let factor = (large == sweep ? -1.0 : 1.0) * sqrt(max(0, 1 - norm * norm))
    let cx = rx * (ny / norm) * factor
    let cy = -ry * (nx / norm) * factor
    let center = CGPoint(
      x: cp * cx - sp * cy + (a.x + b.x) / 2, y: sp * cx + cp * cy + (a.y + b.y) / 2)
    let ux = (x - cx) / rx
    let uy = (y - cy) / ry
    let vx = (-x - cx) / rx
    let vy = (-y - cy) / ry
    let theta = atan2(uy, ux)
    var delta = atan2(ux * vy - uy * vx, ux * vx + uy * vy)
    if !sweep && delta > 0 { delta -= 2 * .pi }
    if sweep && delta < 0 { delta += 2 * .pi }
    // Endpoint differences below angular precision can round a nearly full arc to zero.
    if large && delta == 0 { delta = sweep ? 2 * .pi : -2 * .pi }
    guard center.x.isFinite, center.y.isFinite, theta.isFinite, delta.isFinite else {
      throw svgError("Invalid elliptical arc.")
    }
    let segments = max(1, Int(ceil(abs(delta) / (.pi / 12))))
    guard segments <= 25 else { throw svgError("Elliptical arc exceeds supported limits.") }
    func location(_ t: Double) -> CGPoint {
      CGPoint(
        x: center.x + cp * rx * cos(t) - sp * ry * sin(t),
        y: center.y + sp * rx * cos(t) + cp * ry * sin(t))
    }
    func tangent(_ t: Double) -> CGPoint {
      CGPoint(x: -cp * rx * sin(t) - sp * ry * cos(t), y: -sp * rx * sin(t) + cp * ry * cos(t))
    }
    for i in 0..<segments {
      let t0 = theta + delta * Double(i) / Double(segments)
      let t1 = theta + delta * Double(i + 1) / Double(segments)
      let k = 4 / 3 * tan((t1 - t0) / 4)
      let p0 = location(t0)
      let p1 = location(t1)
      let d0 = tangent(t0)
      let d1 = tangent(t1)
      path.addCurve(
        to: i == segments - 1 ? b : p1,
        control1: CGPoint(x: p0.x + d0.x * k, y: p0.y + d0.y * k),
        control2: CGPoint(x: p1.x - d1.x * k, y: p1.y - d1.y * k))
    }
    return segments
  }
}
