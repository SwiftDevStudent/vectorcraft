import CoreGraphics
import CryptoKit
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import VectorCraftCore

/// Original synthetic artwork: rounded hardware surrounds a rounded transparent screen cavity.
enum RoundedFrameFixture {
  static let screen = CGRect(x: 20, y: 20, width: 80, height: 160)
  static let exteriorCorner = CGPoint(x: 21, y: 21)
  static func frame() throws -> (data: Data, reference: JSONValue) {
    let context = try #require(CGContext(data: nil, width: 120, height: 200, bitsPerComponent: 8,
      bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.translateBy(x: 0, y: 200); context.scaleBy(x: 1, y: -1)
    context.setFillColor(CGColor(gray: 0.07, alpha: 1))
    context.addPath(CGPath(roundedRect: CGRect(x: 10, y: 10, width: 100, height: 180), cornerWidth: 45, cornerHeight: 45, transform: nil))
    context.fillPath()
    context.setBlendMode(.clear)
    context.addPath(CGPath(roundedRect: screen, cornerWidth: 30, cornerHeight: 30, transform: nil)); context.fillPath()
    context.setBlendMode(.normal)
    context.setFillColor(CGColor(gray: 0, alpha: 1))
    context.fillEllipse(in: CGRect(x: 55, y: 25, width: 10, height: 8))
    context.fill(CGRect(x: 20, y: 45, width: 8, height: 15))
    let data = try png(#require(context.makeImage()))
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("Rounded-frame-\(UUID().uuidString).png")
    try data.write(to: url)
    let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    let reference: JSONValue = .object(["path": .string(url.path), "sha256": .string(hash),
      "width": .integer(120), "height": .integer(200),
      "screen": .object(["x": .integer(20), "y": .integer(20), "width": .integer(80), "height": .integer(160)])])
    return (data, reference)
  }
  static func whiteScreenshot() throws -> Data {
    let context = try #require(CGContext(data: nil, width: 2, height: 2, bitsPerComponent: 8,
      bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.setFillColor(CGColor(gray: 1, alpha: 1)); context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
    return try png(#require(context.makeImage()))
  }
  static func png(_ image: CGImage) throws -> Data {
    let data = NSMutableData()
    let destination = try #require(CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil))
    CGImageDestinationAddImage(destination, image, nil)
    #expect(CGImageDestinationFinalize(destination))
    return data as Data
  }
  static func image(_ data: Data) throws -> CGImage {
    let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
    return try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
  }
  static func pixel(_ image: CGImage, at point: CGPoint) throws -> [UInt8] {
    let crop = try #require(image.cropping(to: CGRect(x: floor(point.x), y: floor(point.y), width: 1, height: 1)))
    let context = try #require(CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.draw(crop, in: CGRect(x: 0, y: 0, width: 1, height: 1))
    let bytes = try #require(context.data?.assumingMemoryBound(to: UInt8.self))
    return Array(UnsafeBufferPointer(start: bytes, count: 4))
  }
}

struct ScreenCavityTests {
  @Test func exteriorTransparentComponentIsRejected() throws {
    let context = try #require(CGContext(data: nil, width: 120, height: 200, bitsPerComponent: 8,
      bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    let image = try #require(context.makeImage())
    #expect(throws: DrawingError.self) { try ScreenCavity.path(in: image, screen: RoundedFrameFixture.screen) }
  }
  @Test func roundedExteriorCornersKeepArtboardBackground() throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let board = try #require(drawing.screenshotRows.first?.boards.first)
    let fixture = try RoundedFrameFixture.frame()
    #expect(try RoundedFrameFixture.pixel(RoundedFrameFixture.image(fixture.data), at: RoundedFrameFixture.exteriorCorner)[3] == 0)
    try drawing.perform(.screenshot(ScreenshotCommand(.setFrame, board: board.id, frame: fixture.reference)))
    let frame = try #require(drawing.node(board.device)?.children.first(where: { $0.type == "image" }))
    let transform = try #require(frame.raw["kind"]["xf"].affine)
    let point = RoundedFrameFixture.exteriorCorner.applying(transform)
    let mask = try #require(drawing.node(board.screen)?.children.first)
    let coversExteriorCorner = mask.cgPath.contains(point)
    #expect(!coversExteriorCorner)
    #expect(!mask.cgPath.contains(CGPoint(x: 24, y: 50).applying(transform)))
    #expect(mask.cgPath.contains(CGPoint(x: 24, y: 150).applying(transform)))
    for screenshot in [false, true] {
      if screenshot { try drawing.perform(.screenshot(ScreenshotCommand(.replaceScreenshot, board: board.id, data: RoundedFrameFixture.whiteScreenshot()))) }
      let output = try RoundedFrameFixture.image(VectorRenderer.png(drawing))
      let corner = try RoundedFrameFixture.pixel(output, at: point)
      #expect(abs(Int(corner[0]) - 20) <= 1 && abs(Int(corner[1]) - 62) <= 1 && abs(Int(corner[2]) - 99) <= 1)
    }
    let output = try RoundedFrameFixture.image(VectorRenderer.png(drawing))
    let screen = try RoundedFrameFixture.pixel(output, at: CGPoint(x: 60, y: 100).applying(transform))
    #expect(screen[0] > 250 && screen[1] > 250 && screen[2] > 250)
    let camera = try RoundedFrameFixture.pixel(output, at: CGPoint(x: 60, y: 29).applying(transform))
    #expect(camera[0] < 10 && camera[1] < 10 && camera[2] < 10)
    #expect(try Data(contentsOf: URL(fileURLWithPath: fixture.reference["path"].string)) == fixture.data)
  }

  @Test func cropUsesMeasuredScreenRectangleAndDeviceTransform() throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let board = try #require(drawing.screenshotRows.first?.boards.first)
    let fixture = try RoundedFrameFixture.frame()
    try drawing.perform(.screenshot(ScreenshotCommand(.setFrame, board: board.id, frame: fixture.reference)))
    try drawing.perform(.screenshot(ScreenshotCommand(.replaceScreenshot, board: board.id, data: RoundedFrameFixture.whiteScreenshot())))
    let frame = try #require(drawing.node(board.device)?.children.first(where: { $0.type == "image" }))
    let frameTransform = try #require(frame.raw["kind"]["xf"].affine)
    let expected = CGAffineTransform(a: 80, b: 0, c: 0, d: 80, tx: -20, ty: 20).concatenating(frameTransform)
    let image = try #require(drawing.node(board.screen)?.children.first(where: { $0.type == "image" }))
    #expect(image.raw["kind"]["xf"].affine == expected)
    let pose = CGAffineTransform(translationX: 30, y: 40).rotated(by: .pi / 9).scaledBy(x: 0.9, y: 1.1)
    try drawing.perform(.transform([board.device], pose))
    try drawing.perform(.screenshot(ScreenshotCommand(.crop, board: board.id)))
    let actual = try #require(drawing.node(image.id)?.raw["kind"]["xf"].affine)
    let transformed = expected.concatenating(pose)
    for (a, b) in zip(actual.json.array.compactMap(\.double), transformed.json.array.compactMap(\.double)) {
      #expect(abs(a - b) < 0.000001)
    }
  }
}
