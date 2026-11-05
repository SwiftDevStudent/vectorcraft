import CoreGraphics
import Foundation

public enum TransformReference: Int, CaseIterable, Sendable {
  case topLeft, top, topRight, left, center, right, bottomLeft, bottom, bottomRight

  public var label: String {
    switch self {
    case .topLeft: "Top Left"
    case .top: "Top"
    case .topRight: "Top Right"
    case .left: "Left"
    case .center: "Center"
    case .right: "Right"
    case .bottomLeft: "Bottom Left"
    case .bottom: "Bottom"
    case .bottomRight: "Bottom Right"
    }
  }
  public func point(in bounds: CGRect) -> CGPoint {
    CGPoint(
      x: bounds.minX + bounds.width * CGFloat(rawValue % 3) / 2,
      y: bounds.minY + bounds.height * CGFloat(rawValue / 3) / 2)
  }
}

public struct IndividualTransform: Equatable, Sendable {
  public var scaleX = 100.0
  public var scaleY = 100.0
  public var moveX = 0.0
  public var moveY = 0.0
  public var rotation = 0.0
  public var reflectX = false
  public var reflectY = false
  public var reference: TransformReference = .center
  public var random = false
  public var seed: UInt64 = 1
  public init() {}

  public var isIdentity: Bool {
    scaleX == 100 && scaleY == 100 && moveX == 0 && moveY == 0 && rotation == 0 && !reflectX
      && !reflectY
  }

  func matrix(in bounds: CGRect, random: inout TransformRandom) throws -> CGAffineTransform {
    guard [scaleX, scaleY, moveX, moveY, rotation].allSatisfy(\.isFinite),
      scaleX != 0, scaleY != 0, abs(scaleX) <= 100_000, abs(scaleY) <= 100_000,
      abs(moveX) <= 1_000_000, abs(moveY) <= 1_000_000, !bounds.isNull,
      [bounds.minX, bounds.minY, bounds.width, bounds.height].allSatisfy(\.isFinite)
    else { throw DrawingError.invalid("Enter finite transform values and nonzero scales.") }
    let sx = self.random ? 100 + (scaleX - 100) * random.unit() : scaleX
    let sy = self.random ? 100 + (scaleY - 100) * random.unit() : scaleY
    let dx = self.random ? moveX * (2 * random.unit() - 1) : moveX
    let dy = self.random ? moveY * (2 * random.unit() - 1) : moveY
    let angle = self.random ? rotation * (2 * random.unit() - 1) : rotation
    guard sx != 0, sy != 0 else {
      throw DrawingError.invalid("The random scale would collapse an object.")
    }
    let origin = reference.point(in: bounds)
    return CGAffineTransform(translationX: origin.x + dx, y: origin.y + dy)
      .rotated(by: -angle.truncatingRemainder(dividingBy: 360) * .pi / 180)
      .scaledBy(x: sx / 100 * (reflectY ? -1 : 1), y: sy / 100 * (reflectX ? -1 : 1))
      .translatedBy(x: -origin.x, y: -origin.y)
  }
}

/// A command's seed keeps random preview, commit and replay deterministic.
struct TransformRandom {
  var state: UInt64
  mutating func unit() -> Double {
    state &+= 0x9e37_79b9_7f4a_7c15
    var value = state
    value = (value ^ (value >> 30)) &* 0xbf58_476d_1ce4_e5b9
    value = (value ^ (value >> 27)) &* 0x94d0_49bb_1331_11eb
    value ^= value >> 31
    return Double(value >> 11) / 9_007_199_254_740_992
  }
}

extension TransformGeometry {
  public static func reflection(axis: Double, around origin: CGPoint) throws -> CGAffineTransform {
    guard [axis, origin.x, origin.y].allSatisfy(\.isFinite) else {
      throw DrawingError.invalid("Enter a finite reflection axis and reference point.")
    }
    let angle = axis.truncatingRemainder(dividingBy: 360) * .pi / 180
    return CGAffineTransform(translationX: origin.x, y: origin.y).rotated(by: -angle)
      .scaledBy(x: 1, y: -1).rotated(by: angle).translatedBy(x: -origin.x, y: -origin.y)
  }

  public static func shear(angle: Double, axis: Double, around origin: CGPoint) throws
    -> CGAffineTransform
  {
    guard [angle, axis, origin.x, origin.y].allSatisfy(\.isFinite) else {
      throw DrawingError.invalid("Enter finite shear values and a reference point.")
    }
    let radians = angle.truncatingRemainder(dividingBy: 180) * .pi / 180
    guard abs(cos(radians)) > 0.000001 else {
      throw DrawingError.invalid("A 90-degree shear has no finite result.")
    }
    let axis = axis.truncatingRemainder(dividingBy: 360) * .pi / 180
    let k = -tan(radians)
    let sine = sin(axis)
    let cosine = cos(axis)
    let a = 1 + k * cosine * sine
    let b = -k * sine * sine
    let c = k * cosine * cosine
    let d = 1 - k * cosine * sine
    return CGAffineTransform(
      a: a, b: b, c: c, d: d,
      tx: origin.x - a * origin.x - c * origin.y,
      ty: origin.y - b * origin.x - d * origin.y)
  }
}
