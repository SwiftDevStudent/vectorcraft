import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum VectorRenderer {
  public static func render(
    _ drawing: Drawing, in context: CGContext, excluding excluded: Int64? = nil,
    isolating isolated: Int64? = nil, clippingScreenshotBoards: Bool = false,
    previewImages: VectorImagePreviewCache? = nil
  ) {
    previewImages?.prepare(images: drawing.envelope["images"], blobs: drawing.nativeBlobData)
    let scope = isolated.flatMap { id in drawing.ancestry(of: id).map { (id, Set($0.map(\.id))) } }
    var clips: [Int64: CGRect] = [:]
    if clippingScreenshotBoards {
      for board in drawing.screenshotRows.flatMap(\.boards) {
        if let index = drawing.artboardIndex(id: board.id), drawing.artboards.indices.contains(index) {
          clips[board.layer] = drawing.artboards[index]
        }
      }
    }
    for layer in drawing.layers {
      if let rect = clips[layer.id] {
        guard rect.intersects(context.boundingBoxOfClipPath) else { continue }
        context.saveGState(); context.clip(to: rect)
      }
      renderNode(layer, images: drawing.envelope["images"], blobs: drawing.nativeBlobData,
        in: context, excluding: excluded, isolation: scope, previewImages: previewImages)
      if clips[layer.id] != nil { context.restoreGState() }
    }
  }

  private static func renderNode(
    _ node: VectorNode, images: JSONValue, blobs: Data, in context: CGContext, excluding excluded: Int64?,
    isolation: (id: Int64, ancestors: Set<Int64>)?, previewImages: VectorImagePreviewCache?
  ) {
    guard node.id != excluded, node.visible, node.raw["kind"]["guide"].boolean != true else {
      return
    }
    context.saveGState()
    defer { context.restoreGState() }
    let outside = isolation.map { !$0.ancestors.contains(node.id) } ?? false
    let childScope = outside || node.id == isolation?.id ? nil : isolation
    context.setAlpha(min(1, max(0, node.opacity)) * (outside ? 0.2 : 1))
    context.beginTransparencyLayer(auxiliaryInfo: nil)
    defer { context.endTransparencyLayer() }
    if ["layer", "group"].contains(node.type) {
      var children = node.children
      if node.raw["kind"]["clip"].boolean == true, let clip = children.first {
        context.addPath(clip.cgPath)
        context.clip(using: .winding)
        children = Array(children.dropFirst())
      }
      for child in children {
        renderNode(child, images: images, blobs: blobs, in: context, excluding: excluded,
          isolation: childScope, previewImages: previewImages)
      }
      return
    }
    if node.type == "image" {
      VectorImage.render(node, images: images, blobs: blobs, context: context, previewImages: previewImages)
      return
    }
    if node.type == "text" {
      for part in VectorText.parts(node) {
        let style = part.style
        context.addPath(part.path)
        if style["fill"]["type"].string == "solid" {
          context.setFillColor(color(style["fill"]["color"]))
          context.fillPath()
        }
        if style["stroke"]["type"].string == "solid", let width = style["stroke_width"].double,
          width > 0
        {
          context.addPath(part.path)
          context.setStrokeColor(color(style["stroke"]["color"]))
          context.setLineWidth(min(width, 10000))
          context.strokePath()
        }
      }
      return
    }
    guard ["path", "compound"].contains(node.type) else { return }
    let path = node.cgPath
    guard !path.boundingBoxOfPath.isNull else { return }
    let rule: CGPathFillRule = node.raw["kind"]["rule"].string == "EvenOdd" ? .evenOdd : .winding
    for item in node.raw["appearance"]["items"].array where item["visible"].boolean != false {
      let paint = item["paint"]
      guard paint["type"].string != "none" else { continue }
      context.saveGState()
      context.setAlpha(min(1, max(0, item["opacity"].double ?? 1)))
      if item["kind"].string == "stroke" {
        let width = item["width"].double ?? 1
        if width > 0, width.isFinite {
          context.setLineWidth(min(width, 10000))
          context.setLineCap(
            item["cap"].string == "Round"
              ? .round : item["cap"].string == "Square" ? .square : .butt)
          context.setLineJoin(
            item["join"].string == "Round"
              ? .round : item["join"].string == "Bevel" ? .bevel : .miter)
          context.setMiterLimit(min(10000, max(1, item["miter_limit"].double ?? 10)))
          let dash = item["dash"]["pattern"].array.compactMap(\.double)
          if !dash.isEmpty, dash.allSatisfy({ $0.isFinite && $0 >= 0 }),
            dash.contains(where: { $0 > 0 })
          {
            context.setLineDash(
              phase: item["dash"]["offset"].double ?? 0, lengths: dash.map { CGFloat($0) })
          }
          context.addPath(path)
          context.replacePathWithStrokedPath()
          context.clip()
          drawPaint(
            paint, bounds: path.boundingBoxOfPath.insetBy(dx: -width / 2, dy: -width / 2),
            in: context)
        }
      } else if item["kind"].string == "fill" {
        context.addPath(path)
        context.clip(using: rule)
        drawPaint(paint, bounds: path.boundingBoxOfPath, in: context)
      }
      context.restoreGState()
    }
  }

  public static func color(_ value: JSONValue, opacity: Double = 1) -> CGColor {
    func unit(_ key: String, _ fallback: Double = 0) -> CGFloat {
      CGFloat(min(1, max(0, value[key].double ?? fallback)))
    }
    let components: [CGFloat]
    let alpha = CGFloat(min(1, max(0, opacity)))
    if value["model"].string == "cmyk" {
      let k = unit("k")
      components = [
        (1 - unit("c")) * (1 - k), (1 - unit("m")) * (1 - k), (1 - unit("y")) * (1 - k), alpha,
      ]
    } else if value["model"].string == "gray" {
      let gray = 1 - unit("k")
      components = [gray, gray, gray, alpha]
    } else {
      components = [unit("r"), unit("g"), unit("b"), alpha]
    }
    let space = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
    return CGColor(colorSpace: space, components: components) ?? CGColor(gray: 0, alpha: alpha)
  }

  private static func drawPaint(_ paint: JSONValue, bounds: CGRect, in context: CGContext) {
    if paint["type"].string == "solid" {
      context.setFillColor(color(paint["color"]))
      context.fill(context.boundingBoxOfClipPath)
    } else if paint["type"].string == "gradient" {
      let stops = paint["gradient"]["stops"].array.sorted {
        ($0["offset"].double ?? 0) < ($1["offset"].double ?? 0)
      }
      guard !stops.isEmpty, let space = CGColorSpace(name: CGColorSpace.sRGB),
        let gradient = CGGradient(
          colorsSpace: space,
          colors: stops.map { color($0["color"], opacity: $0["opacity"].double ?? 1) } as CFArray,
          locations: stops.map { min(1, max(0, $0["offset"].double ?? 0)) })
      else { return }
      let radial = paint["gradient"]["kind"].string == "Radial"
      let geometry = GradientGeometry(paint: paint, bounds: bounds)
      if radial {
        context.translateBy(x: geometry.start.x, y: geometry.start.y)
        context.rotate(
          by: atan2(geometry.end.y - geometry.start.y, geometry.end.x - geometry.start.x))
        context.scaleBy(x: 1, y: max(0.000001, geometry.aspect))
        context.drawRadialGradient(
          gradient, startCenter: .zero, startRadius: 0, endCenter: .zero,
          endRadius: max(geometry.start.distance(to: geometry.end), 0.001),
          options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
      } else {
        context.drawLinearGradient(
          gradient, start: geometry.start, end: geometry.end,
          options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
      }
    }
  }

  public static func png(_ drawing: Drawing, artboard index: Int = 0, scale: Double = 1,
    previewImages: VectorImagePreviewCache? = nil) throws
    -> Data
  {
    guard drawing.renderingWarnings.isEmpty else {
      throw DrawingError.invalid(
        "Export is unavailable while this document contains unsupported rendering features. Native saving retains them."
      )
    }
    guard drawing.artboards.indices.contains(index), scale.isFinite, scale > 0 else {
      throw DrawingError.invalid("Invalid export dimensions.")
    }
    let rect = drawing.artboards[index]
    let w = ceil(rect.width * scale)
    let h = ceil(rect.height * scale)
    guard w > 0, h > 0, w <= 16384, h <= 16384, w * h <= 32_000_000,
      let space = CGColorSpace(name: CGColorSpace.sRGB),
      let context = CGContext(
        data: nil, width: Int(w), height: Int(h), bitsPerComponent: 8, bytesPerRow: 0, space: space,
        bitmapInfo: drawing.screenshotRows.isEmpty ? CGImageAlphaInfo.premultipliedLast.rawValue : CGImageAlphaInfo.noneSkipLast.rawValue)
    else {
      throw DrawingError.invalid(
        "PNG export is limited to 32 megapixels and 16,384 pixels per side.")
    }
    context.translateBy(x: 0, y: h)
    context.scaleBy(x: scale, y: -scale)
    context.translateBy(x: -rect.minX, y: -rect.minY)
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fill(rect)
    render(drawing, in: context, previewImages: previewImages)
    guard let image = context.makeImage() else {
      throw DrawingError.invalid("Could not render the document.")
    }
    let data = NSMutableData()
    guard
      let destination = CGImageDestinationCreateWithData(
        data, UTType.png.identifier as CFString, 1, nil)
    else { throw DrawingError.invalid("Could not create the PNG.") }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
      throw DrawingError.invalid("Could not finish the PNG.")
    }
    return data as Data
  }
}
