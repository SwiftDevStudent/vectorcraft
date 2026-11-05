import CoreGraphics
import Foundation

struct GradientGeometry {
  var start: CGPoint
  var end: CGPoint
  var aspect: Double

  init(paint: JSONValue, bounds: CGRect) {
    let angle = (paint["angle"].double ?? 0) * .pi / 180
    let radial = paint["gradient"]["kind"].string == "Radial"
    let center = CGPoint(x: bounds.midX, y: bounds.midY)
    let extent =
      radial
      ? max(bounds.width, bounds.height) / 2
      : (abs(cos(angle)) * bounds.width + abs(sin(angle)) * bounds.height) / 2
    start =
      paint["geom"]["start"].point
      ?? (radial
        ? center : CGPoint(x: center.x - cos(angle) * extent, y: center.y + sin(angle) * extent))
    end =
      paint["geom"]["end"].point
      ?? CGPoint(x: center.x + cos(angle) * extent, y: center.y - sin(angle) * extent)
    aspect = paint["geom"]["aspect"].double ?? 1
  }

  func transformed(_ transform: CGAffineTransform, radial: Bool) throws -> GradientGeometry {
    let dx = end.x - start.x
    let dy = end.y - start.y
    let newStart = start.applying(transform)
    var result = self
    result.start = newStart
    if radial {
      let ux = transform.a * dx + transform.c * dy
      let uy = transform.b * dx + transform.d * dy
      let vx = (-transform.a * dy + transform.c * dx) * aspect
      let vy = (-transform.b * dy + transform.d * dx) * aspect
      let xx = ux * ux + vx * vx
      let yy = uy * uy + vy * vy
      let xy = ux * uy + vx * vy
      let delta = hypot(xx - yy, 2 * xy)
      let major = sqrt(max(0, (xx + yy + delta) / 2))
      let minor = sqrt(max(0, (xx + yy - delta) / 2))
      guard major.isFinite, major > 0.000001, minor > 0.000001 else {
        throw DrawingError.invalid("The gradient transform is degenerate.")
      }
      let angle = atan2(2 * xy, xx - yy) / 2
      result.end = CGPoint(x: newStart.x + major * cos(angle), y: newStart.y + major * sin(angle))
      result.aspect = minor / major
    } else {
      let determinant = transform.a * transform.d - transform.b * transform.c
      guard determinant.isFinite, abs(determinant) > 0.000000000001 else {
        throw DrawingError.invalid("The gradient transform is degenerate.")
      }
      let nx = (transform.d * dx - transform.b * dy) / determinant
      let ny = (-transform.c * dx + transform.a * dy) / determinant
      let length = nx * nx + ny * ny
      guard length.isFinite, length > 0.000000000001 else {
        throw DrawingError.invalid("The gradient transform is degenerate.")
      }
      let scale = (dx * dx + dy * dy) / length
      result.end = CGPoint(x: newStart.x + nx * scale, y: newStart.y + ny * scale)
    }
    return result
  }

  func json() -> JSONValue {
    .object([
      "start": start.json(version: 1), "end": end.json(version: 1), "aspect": .number(aspect),
    ])
  }
}
