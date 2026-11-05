import AppKit
import Testing
import VectorCraftCore

@testable import VectorCraftMac

@MainActor
struct CanvasClippingTests {
  @Test func enlargedArtboardCannotPaintOutsideTheCanvasViewport() throws {
    let view = VectorCanvasView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
    let state = EditorState()
    view.update(drawing: Drawing(), state: state, command: { _ in })
    view.layout()
    state.canvasAction = .actualSize
    view.update(drawing: Drawing(), state: state, command: { _ in })
    let bitmap = try #require(NSBitmapImageRep(
      bitmapDataPlanes: nil, pixelsWide: 100, pixelsHigh: 100, bitsPerSample: 8,
      samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
      colorSpaceName: .deviceRGB, bytesPerRow: 400, bitsPerPixel: 32))
    let graphics = try #require(NSGraphicsContext(bitmapImageRep: bitmap))
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = graphics
    let context = graphics.cgContext
    context.setFillColor(NSColor.magenta.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
    context.translateBy(x: 20, y: 20)
    view.draw(view.bounds)
    let outside = try #require(bitmap.colorAt(x: 5, y: 5)?.usingColorSpace(.deviceRGB))
    #expect(outside.redComponent > 0.9 && outside.blueComponent > 0.9)
    #expect(outside.greenComponent < 0.1)
    let inside = try #require(bitmap.colorAt(x: 50, y: 50)?.usingColorSpace(.deviceRGB))
    #expect(inside.redComponent > 0.9 && inside.greenComponent > 0.9 && inside.blueComponent > 0.9)
  }
}
