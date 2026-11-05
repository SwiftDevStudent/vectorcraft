import CoreGraphics
import CryptoKit
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import VectorCraftCore

struct ScreenshotWorkspaceTests {
  @Test func repeatedSameImageReplacementDoesNotGrowNativeV4Arena() throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let board = try #require(drawing.screenshotRows.first?.boards.first)
    let bytes = try imageData(outlined: true)
    #expect(bytes.count >= NativeBlob.inlineLimit)
    try drawing.perform(.screenshot(ScreenshotCommand(.replaceScreenshot, board: board.id, data: bytes)))
    var reopened = try NativeFormat.decode(NativeFormat.encode(drawing))
    #expect(reopened.version == 4)
    #expect(!reopened.nativeBlobData.isEmpty)
    let initialFileSize = try NativeFormat.encode(reopened).count
    let initialArenaSize = reopened.nativeBlobData.count
    for _ in 0..<4 {
      try reopened.perform(.screenshot(ScreenshotCommand(.replaceScreenshot, board: board.id, data: bytes)))
      let saved = try NativeFormat.encode(reopened)
      #expect(saved.count == initialFileSize)
      reopened = try NativeFormat.decode(saved)
      #expect(reopened.nativeBlobData.count == initialArenaSize)
      let image = try #require(reopened.node(board.screen)?.children.first(where: { $0.type == "image" }))
      #expect(VectorImage.data(image, images: reopened.envelope["images"], blobs: reopened.nativeBlobData) == bytes)
    }
  }

  @Test func linkedFrameProxyDecodesAsOneTransparentPixel() throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let board = try #require(drawing.screenshotRows.first?.boards.first)
    let fixture = try RoundedFrameFixture.frame()
    try drawing.perform(.screenshot(ScreenshotCommand(.setFrame, board: board.id, frame: fixture.reference)))
    let frame = try #require(drawing.node(board.device)?.children.first(where: { $0.type == "image" }))
    // Read the proxy resource through the same resolver as native image inspection, without
    // the local-frame URL that normally selects the original PNG instead of its proxy.
    let proxyNode = VectorNode(raw: .object(["kind": .object(["key": frame.raw["kind"]["key"]])]))
    let data = try #require(VectorImage.data(proxyNode, images: drawing.envelope["images"], blobs: drawing.nativeBlobData))
    let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
    let proxy = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
    #expect(proxy.width == 1 && proxy.height == 1)
    #expect(try sample(proxy, x: 0, y: 0) == [0, 0, 0, 0])
  }

  @Test(arguments: ["headline", "minimal", "split"])
  func templatesRenderWithoutSubstitutedFontWarnings(template: String) throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium", template: template)))
    let board = try #require(drawing.screenshotRows.first?.boards.first)
    #expect(drawing.renderingWarnings.isEmpty)
    if template != "minimal" {
      let text = try #require(drawing.node(board.content)?.children.first(where: { $0.type == "text" }))
      #expect(!VectorText.parts(text).isEmpty)
      #expect(text.raw["kind"]["runs"].array.first?["style"]["font_family"].string == "Helvetica")
      #expect(text.raw["kind"]["runs"].array.first?["style"]["font_style"].string == "Bold")
    }
  }
  @Test func sameSizeReplacementPreservesNativeMoveScaleAndRotation() throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let board = try #require(drawing.screenshotRows.first?.boards.first)
    let bytes = try imageData()
    try drawing.perform(.screenshot(ScreenshotCommand(.replaceScreenshot, board: board.id, data: bytes)))
    try drawing.perform(.screenshot(ScreenshotCommand(.crop, board: board.id, scale: 1.2, cropX: 0.04, cropY: -0.03)))
    let id = try #require(drawing.node(board.screen)?.children.first(where: { $0.type == "image" })?.id)
    let pose = CGAffineTransform(translationX: 12, y: 30).rotated(by: .pi / 10).scaledBy(x: 0.8, y: 1.2)
    try drawing.perform(.transform([id], pose))
    let before = try #require(drawing.node(id))
    try drawing.perform(.screenshot(ScreenshotCommand(.replaceScreenshot, board: board.id, data: bytes)))
    let replaced = try #require(drawing.node(id))
    #expect(replaced.raw["kind"]["xf"] == before.raw["kind"]["xf"])
    #expect(replaced.bounds == before.bounds)
    #expect(replaced.raw["screenshotCrop"] == before.raw["screenshotCrop"])
  }

  private func imageData(outlined: Bool = false) throws -> Data {
    let side = outlined ? 128 : 2
    var pixels = Data([255, 0, 0, 255, 255, 0, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255])
    if outlined {
      var seed: UInt32 = 0x12345678
      var bytes = [UInt8](repeating: 255, count: side * side * 4)
      for index in bytes.indices where index % 4 != 3 {
        seed = seed &* 1664525 &+ 1013904223
        bytes[index] = UInt8(truncatingIfNeeded: seed >> 24)
      }
      pixels = Data(bytes)
    }
    let provider = try #require(CGDataProvider(data: pixels as CFData))
    let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
    let image = try #require(CGImage(width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 32,
      bytesPerRow: side * 4, space: space, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
      provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent))
    let data = NSMutableData()
    let destination = try #require(CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil))
    CGImageDestinationAddImage(destination, image, nil)
    #expect(CGImageDestinationFinalize(destination))
    return data as Data
  }
  private func sample(_ image: CGImage, x: Double, y: Double) throws -> [UInt8] {
    let pixel = try #require(image.cropping(to: CGRect(x: floor(x), y: floor(y), width: 1, height: 1)))
    let context = try #require(CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.draw(pixel, in: CGRect(x: 0, y: 0, width: 1, height: 1))
    let pointer = try #require(context.data?.assumingMemoryBound(to: UInt8.self))
    return Array(UnsafeBufferPointer(start: pointer, count: 4))
  }
  @Test func rowsRoundtripAndLimitAreRealNativeCommands() throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let row = try #require(drawing.screenshotRows.first)
    for _ in 1..<10 { try drawing.perform(.screenshot(ScreenshotCommand(.addBoard, row: row.id))) }
    try drawing.perform(.screenshot(ScreenshotCommand(.setLanguage, language: "he-IL")))
    let before = drawing
    #expect(throws: DrawingError.self) { try drawing.perform(.screenshot(ScreenshotCommand(.addBoard, row: row.id))) }
    #expect(drawing == before)
    let reopened = try NativeFormat.decode(NativeFormat.encode(drawing))
    #expect(reopened.envelope["document"] == drawing.envelope["document"])
    #expect(reopened.screenshotRows.first?.boards.count == 10)
  }
  @Test func screenshotIsUprightClippedCroppedAndExportedWithoutAlpha() throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let board = try #require(drawing.screenshotRows.first?.boards.first)
    try drawing.perform(.screenshot(ScreenshotCommand(.replaceScreenshot, board: board.id, data: imageData())))
    #expect(drawing.renderingWarnings.isEmpty)
    let clip = try #require(drawing.node(board.screen)?.children.first?.bounds)
    let png = try VectorRenderer.png(drawing)
    let source = try #require(CGImageSourceCreateWithData(png as CFData, nil))
    let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
    let top = try sample(image, x: clip.midX, y: clip.minY + clip.height * 0.15)
    let bottom = try sample(image, x: clip.midX, y: clip.minY + clip.height * 0.85)
    #expect(top[0] > 220 && top[1] < 30)
    #expect(bottom[1] > 220 && bottom[0] < 30)
    let outside = try sample(image, x: clip.minX - 5, y: clip.midY)
    #expect(outside[0] < 60 && outside[1] < 60)
    #expect(image.alphaInfo == .none || image.alphaInfo == .noneSkipLast || image.alphaInfo == .noneSkipFirst)
    let svg = String(decoding: try SVGExport.encode(drawing), as: UTF8.self)
    #expect(svg.contains("<clipPath") && svg.contains("data:image/png;base64,"))
    #expect(try PDFExport.encode(drawing).starts(with: Data("%PDF".utf8)))
    try drawing.perform(.screenshot(ScreenshotCommand(.crop, board: board.id, cropX: 1)))
    let shifted = try #require(drawing.node(board.screen)?.children.first(where: { $0.type == "image" }))
    #expect(shifted.bounds.midX > clip.maxX)
  }
  @Test func rotationReflowsOwnedArtworkWithoutLosingMultilineGlyphs() throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let row = try #require(drawing.screenshotRows.first), board = try #require(row.boards.first)
    try drawing.perform(.screenshot(ScreenshotCommand(.addBoard, row: row.id)))
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "duo-inner")))
    let oldIDs = drawing.node(board.content)?.children.map(\.id)
    let text = try #require(drawing.node(board.content)?.children.first(where: { $0.type == "text" }))
    func contours(_ node: VectorNode) -> Int {
      var count = 0
      for part in VectorText.parts(node) { part.path.applyWithBlock { if $0.pointee.type == .moveToPoint { count += 1 } } }
      return count
    }
    let original = contours(text)
    try drawing.perform(.screenshot(ScreenshotCommand(.rotateBoard, board: board.id)))
    #expect(drawing.artboards[0].width == 2622 && drawing.artboards[0].height == 1206)
    #expect(drawing.artboards[1].minX == drawing.artboards[0].maxX + 160)
    #expect(abs(drawing.artboards[2].minY - 2782) < 0.000001)
    #expect(drawing.node(board.content)?.children.map(\.id) == oldIDs)
    #expect(contours(try #require(drawing.node(text.id))) == original)
    #expect(drawing.artboards[0].contains(try #require(drawing.node(board.content)?.bounds)))
  }
  @Test func placedImageUsesExistingTransformClipboardAndNativeResourcePaths() throws {
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let board = try #require(drawing.screenshotRows.first?.boards.first), data = try imageData()
    try drawing.perform(.screenshot(ScreenshotCommand(.replaceScreenshot, board: board.id, data: data)))
    let id = try #require(drawing.node(board.screen)?.children.first(where: { $0.type == "image" })?.id)
    let old = try #require(drawing.node(id)?.bounds)
    try drawing.perform(.transform([id], CGAffineTransform(translationX: 12, y: 30)))
    #expect(drawing.node(id)?.bounds.origin == CGPoint(x: old.minX + 12, y: old.minY + 30))
    let fragment = try VectorFragment(copying: [id], from: drawing)
    var destination = Drawing()
    let selection = try destination.perform(.paste(fragment, .center(CGPoint(x: 400, y: 400)), container: 1, relativeTo: []))
    #expect(selection.count == 1 && destination.renderingWarnings.isEmpty)
    #expect(try #require(selection.first.flatMap(destination.node)).type == "image")
    let count = drawing.envelope["images"].object.count
    try drawing.perform(.screenshot(ScreenshotCommand(.replaceScreenshot, board: board.id, data: data)))
    #expect(drawing.envelope["images"].object.count == count)
    #expect(drawing.node(board.screen)?.children.first(where: { $0.type == "image" })?.id == id)
  }
  @Test func addingScreenshotRowsPreservesExistingIllustrationAndUnknownData() throws {
    var drawing = Drawing()
    let selected = try drawing.perform(.addPath([ShapePaths.rectangle(CGRect(x: 20, y: 20, width: 100, height: 100))], VectorStyle(), layer: 1))
    drawing.envelope["foreign"] = .string("preserve")
    let art = try #require(selected.first.flatMap(drawing.node))
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "ipad-13")))
    #expect(drawing.node(art.id) == art)
    #expect(drawing.artboards[0] == CGRect(x: 0, y: 0, width: 800, height: 800))
    #expect(drawing.artboards[1].minY == 960)
    #expect(drawing.envelope["foreign"].string == "preserve")
  }
}
