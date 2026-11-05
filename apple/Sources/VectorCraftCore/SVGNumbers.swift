import CoreGraphics
import Foundation

/// ASCII SVG numeric grammar, including adjacent signs, exponents and compact arc flags.
struct SVGNumbers {
  let bytes: [UInt8]
  var index = 0
  init(_ text: String) { bytes = Array(text.utf8) }
  var next: UInt8? { bytes.indices.contains(index) ? bytes[index] : nil }
  mutating func spaces() {
    while let c = next, [9, 10, 13, 32].contains(c) { index += 1 }
  }
  mutating func separator() {
    spaces()
    if next == 44 {
      index += 1
      spaces()
    }
  }
  mutating func number() throws -> Double {
    separator()
    let start = index
    if next == 43 || next == 45 { index += 1 }
    var digits = 0
    while let c = next, (48...57).contains(c) {
      index += 1
      digits += 1
    }
    if next == 46 {
      index += 1
      while let c = next, (48...57).contains(c) {
        index += 1
        digits += 1
      }
    }
    guard digits > 0 else { throw error("Expected a finite number.") }
    if next == 69 || next == 101 {
      index += 1
      if next == 43 || next == 45 { index += 1 }
      let exponentStart = index
      while let c = next, (48...57).contains(c) { index += 1 }
      guard index > exponentStart else { throw error("Invalid numeric exponent.") }
    }
    guard index - start <= 128,
      let value = Double(String(decoding: bytes[start..<index], as: UTF8.self)), value.isFinite,
      abs(value) <= 1_000_000_000
    else { throw error("A number exceeds the supported SVG limits.") }
    return value
  }
  mutating func flag() throws -> Bool {
    separator()
    guard let c = next, c == 48 || c == 49 else { throw error("Arc flags must be 0 or 1.") }
    index += 1
    return c == 49
  }
  mutating func list() throws -> [Double] {
    var result: [Double] = []
    spaces()
    while next != nil {
      guard result.count < 100_000 else { throw error("Too many numeric values.") }
      result.append(try number())
      spaces()
    }
    return result
  }
}

func svgError(_ message: String) -> DrawingError { .invalid("SVG: \(message)") }
private func error(_ message: String) -> DrawingError { svgError(message) }

enum SVGTransform {
  static func parse(_ text: String) throws -> CGAffineTransform {
    var scanner = SVGNumbers(text)
    var result = CGAffineTransform.identity
    while true {
      scanner.spaces()
      if scanner.next == 44 {
        scanner.index += 1
        scanner.spaces()
      }
      guard scanner.next != nil else { return result }
      let start = scanner.index
      while let c = scanner.next, (65...90).contains(c) || (97...122).contains(c) {
        scanner.index += 1
      }
      let name = String(decoding: scanner.bytes[start..<scanner.index], as: UTF8.self)
      scanner.spaces()
      guard scanner.next == 40 else { throw svgError("Invalid transform list.") }
      scanner.index += 1
      var values: [Double] = []
      scanner.spaces()
      while scanner.next != 41 {
        guard scanner.next != nil, values.count < 6 else {
          throw svgError("Invalid transform arguments.")
        }
        values.append(try scanner.number())
        scanner.spaces()
      }
      scanner.index += 1
      let transform: CGAffineTransform
      switch (name, values.count) {
      case ("matrix", 6):
        transform = CGAffineTransform(
          a: values[0], b: values[1], c: values[2], d: values[3], tx: values[4], ty: values[5])
      case ("translate", 1), ("translate", 2):
        transform = CGAffineTransform(translationX: values[0], y: values.count == 2 ? values[1] : 0)
      case ("scale", 1), ("scale", 2):
        transform = CGAffineTransform(
          scaleX: values[0], y: values.count == 2 ? values[1] : values[0])
      case ("rotate", 1), ("rotate", 3):
        let rotation = CGAffineTransform(rotationAngle: values[0] * .pi / 180)
        transform =
          values.count == 1
          ? rotation
          : CGAffineTransform(translationX: -values[1], y: -values[2]).concatenating(rotation)
            .concatenating(CGAffineTransform(translationX: values[1], y: values[2]))
      case ("skewX", 1):
        transform = CGAffineTransform(a: 1, b: 0, c: tan(values[0] * .pi / 180), d: 1, tx: 0, ty: 0)
      case ("skewY", 1):
        transform = CGAffineTransform(a: 1, b: tan(values[0] * .pi / 180), c: 0, d: 1, tx: 0, ty: 0)
      default: throw svgError("Unsupported transform or argument count: \(name).")
      }
      result = transform.concatenating(result)
      guard
        [result.a, result.b, result.c, result.d, result.tx, result.ty].allSatisfy({
          $0.isFinite && abs($0) <= 1_000_000
        })
      else { throw svgError("Transform exceeds supported limits.") }
    }
  }
}
