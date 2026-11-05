import CoreGraphics
import Foundation
import ImageIO
import CryptoKit

public struct ScreenshotPreset: Identifiable, Sendable {
  public let id: String
  public let name: String
  public let width: Double
  public let height: Double
  public static let all: [Self] = [
    .init(id: "iphone-medium", name: "iPhone Medium", width: 1206, height: 2622),
    .init(id: "iphone-large", name: "iPhone Large", width: 1320, height: 2868),
    .init(id: "iphone-duo", name: "iPhone Duo", width: 2007, height: 2853),
    .init(id: "ipad-13", name: "iPad 13-inch", width: 2064, height: 2752),
  ]
  public static func find(_ id: String) -> Self? {
    if id == "duo-inner" { return .init(id: id, name: "Duo Inner", width: 2007, height: 2853) }
    if id == "duo-outer" { return .init(id: id, name: "Duo Outer", width: 1398, height: 2034) }
    return all.first { $0.id == id }
  }
}
public enum ScreenshotAction: String, Codable, Sendable {
  case addRow, addBoard, rotateBoard, replaceScreenshot, setLanguage, crop, setFrame, setTemplate, setDisplay, setExport, placeScreenshots, moveBoard
}
public struct ScreenshotCommand: Codable, Sendable {
  public var action: ScreenshotAction
  public var preset: String?
  public var row: String?
  public var board: Int64?
  public var template: String?
  public var language: String?
  public var data: Data?
  public var scale: Double?
  public var cropX: Double?
  public var cropY: Double?
  public var fit: Bool?
  public var frame: JSONValue?
  public var slot: Int?
  public var included: Bool?
  public var images: [Data]?
  public init(_ action: ScreenshotAction, preset: String? = nil, row: String? = nil,
              board: Int64? = nil, template: String? = nil, language: String? = nil,
              data: Data? = nil, scale: Double? = nil, cropX: Double? = nil,
              cropY: Double? = nil, fit: Bool? = nil, frame: JSONValue? = nil,
              slot: Int? = nil, included: Bool? = nil, images: [Data]? = nil) {
    self.action = action; self.preset = preset; self.row = row; self.board = board
    self.template = template; self.language = language; self.data = data
    self.scale = scale; self.cropX = cropX; self.cropY = cropY; self.fit = fit; self.frame = frame; self.slot = slot; self.included = included
    self.images = images
  }
  public var label: String {
    switch action {
    case .addRow: "Add Screenshot Row"
    case .addBoard: "Add Screenshot Artboard"
    case .rotateBoard: "Rotate Screenshot Artboard"
    case .replaceScreenshot: "Replace Screenshot"
    case .setLanguage: "Set Screenshot Language"
    case .crop: "Crop Screenshot"
    case .setFrame: "Set Device Frame"
    case .setTemplate: "Set Screenshot Layout"
    case .setDisplay: "Set Duo Display"
    case .setExport: "Include Screenshot in Export"
    case .placeScreenshots: "Place Screenshots"
    case .moveBoard: "Move Screenshot Slot"
    }
  }
}
public struct ScreenshotBoard: Identifiable, Sendable {
  public let raw: JSONValue
  public var id: Int64 { raw["id"].int ?? 0 }
  public var layer: Int64 { raw["layer"].int ?? 0 }
  public var content: Int64 { raw["content"].int ?? 0 }
  public var device: Int64 { raw["device"].int ?? 0 }
  public var screen: Int64 { raw["screen"].int ?? 0 }
  public var background: Int64 { raw["background"].int ?? 0 }
  public var landscape: Bool { raw["landscape"].boolean ?? false }
}
public struct ScreenshotRow: Identifiable, Sendable {
  public let raw: JSONValue
  public var id: String { raw["id"].string }
  public var name: String { ["duo-inner", "duo-outer"].contains(raw["preset"].string) ? "iPhone Duo" : raw["name"].string }
  public var boards: [ScreenshotBoard] { raw["boards"].array.map { ScreenshotBoard(raw: $0) } }
}
extension Drawing {
  public var screenshotRows: [ScreenshotRow] {
    envelope["document"]["unknown"]["screenshots"]["rows"].array.map { ScreenshotRow(raw: $0) }
  }
  public func screenshotBoard(_ id: Int64) -> ScreenshotBoard? {
    screenshotRows.flatMap(\.boards).first { $0.id == id }
  }
  public func screenshotBoard(at index: Int) -> ScreenshotBoard? {
    let boards = envelope["document"]["artboards"].array
    return boards.indices.contains(index) ? boards[index]["id"].int.flatMap(screenshotBoard) : nil
  }
  /// Layers selection may target the outer board layer; new artwork belongs in its content group.
  public func screenshotInsertionContainer(for container: Int64) -> Int64 {
    screenshotRows.flatMap(\.boards).first { $0.layer == container }?.content ?? container
  }
  public func artboardIndex(id: Int64) -> Int? {
    envelope["document"]["artboards"].array.firstIndex { $0["id"].int == id }
  }
  mutating func applyScreenshot(_ c: ScreenshotCommand) throws -> Set<Int64> {
    let formatVersion = version
    if c.action == .placeScreenshots { return try placeScreenshotImages(c) }
    if c.action == .moveBoard { return try moveScreenshotBoard(c) }
    if c.action == .setLanguage {
      envelope["document"]["unknown"]["screenshots"]["language"] = .string(c.language ?? "en-US")
      return []
    }
    if c.action == .addRow {
      guard let preset = ScreenshotPreset.find(c.preset ?? "iphone-medium") else {
        throw DrawingError.invalid("Unknown screenshot preset.")
      }
      let empty = layers.allSatisfy { $0.children.isEmpty } && screenshotRows.isEmpty
      if screenshotRows.isEmpty {
        envelope["document"]["unknown"]["screenshots"]["originY"] = .number(empty ? 0 : Double(artboards.map(\.maxY).max() ?? 0) + 160)
      }
      var rows = envelope["document"]["unknown"]["screenshots"]["rows"].array
      rows.append(.object(["id": .string(UUID().uuidString), "preset": .string(preset.id),
        "name": .string(preset.name), "width": .number(preset.width), "height": .number(preset.height), "boards": .array([])]))
      envelope["document"]["unknown"]["screenshots"]["rows"] = .array(rows)
      return try addScreenshotBoard(rowIndex: rows.count - 1, template: c.template ?? "headline", reuseEmptyBoard: empty)
    }
    if c.action == .addBoard {
      guard let index = screenshotRows.firstIndex(where: { $0.id == c.row }) else { throw DrawingError.invalid("Choose a screenshot row.") }
      return try addScreenshotBoard(rowIndex: index, template: c.template ?? "headline", reuseEmptyBoard: false, slot: c.slot)
    }
    guard let id = c.board, let board = screenshotBoard(id), let index = artboardIndex(id: id),
      node(board.content) != nil, node(board.screen) != nil else { throw DrawingError.invalid("Choose an intact screenshot artboard.") }
    switch c.action {
    case .rotateBoard:
      let old = artboards[index]
      let new = CGRect(origin: old.origin, size: CGSize(width: old.height, height: old.width))
      let source = node(board.content)?.bounds ?? .null
      if !source.isNull, source.width > 0, source.height > 0 {
        let target = new.insetBy(dx: new.width * 0.05, dy: new.height * 0.05)
        let scale = min(target.width / source.width, target.height / source.height)
        let xf = CGAffineTransform(translationX: -source.midX, y: -source.midY)
          .concatenating(.init(scaleX: scale, y: scale))
          .concatenating(.init(translationX: target.midX, y: target.midY))
        try updateNode(board.content) { try Self.transformNode(&$0, xf, version: formatVersion) }
      }
      setScreenshotRect(index: index, rect: new)
      updateNode(board.background) { $0["kind"]["path"]["subpaths"] = .array([ShapePaths.rectangle(new).json(version: formatVersion)]) }
      var rows = envelope["document"]["unknown"]["screenshots"]["rows"].array
      for r in rows.indices {
        var boards = rows[r]["boards"].array
        for b in boards.indices where boards[b]["id"].int == id { boards[b]["landscape"] = .bool(!board.landscape) }
        rows[r]["boards"] = .array(boards)
      }
      envelope["document"]["unknown"]["screenshots"]["rows"] = .array(rows)
      try reflowScreenshots()
      return [board.content]
    case .setTemplate:
      try applyScreenshotTemplate(board, template: c.template ?? "headline", rect: artboards[index])
      return [board.content]
    case .setDisplay:
      guard ["duo-inner", "duo-outer"].contains(c.preset ?? ""),
        screenshotRows.contains(where: { ["iphone-duo", "duo-inner", "duo-outer"].contains($0.raw["preset"].string) && $0.boards.contains(where: { $0.id == id }) }),
        let preset = ScreenshotPreset.find(c.preset ?? "") else { throw DrawingError.invalid("Choose a Duo display.") }
      let old = artboards[index]
      let size = board.landscape ? CGSize(width: preset.height, height: preset.width) : CGSize(width: preset.width, height: preset.height)
      let next = CGRect(origin: old.origin, size: size)
      setScreenshotRect(index: index, rect: next)
      updateNode(board.background) { $0["kind"]["path"]["subpaths"] = .array([ShapePaths.rectangle(next).json(version: formatVersion)]) }
      updateScreenshotBoard(id) { $0["display"] = .string(preset.id) }
      try applyScreenshotTemplate(board, template: board.raw["template"].string, rect: next)
      try reflowScreenshots()
      return [board.content]
    case .setExport:
      updateScreenshotBoard(id) { $0["included"] = .bool(c.included ?? true) }
      return []
    case .replaceScreenshot:
      guard let data = c.data, data.count <= 16 * 1024 * 1024,
        let source = CGImageSourceCreateWithData(data as CFData, nil),
        let type = CGImageSourceGetType(source) as String?, ["public.png", "public.jpeg"].contains(type),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        throw DrawingError.invalid("Choose a PNG or JPEG screenshot no larger than16 MB.")
      }
      let key = "screenshot-" + SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
      // Keep an existing v4 blob descriptor when its bytes already match; rewriting it inline
      // would append the same PNG to the retained binary arena on every replacement/save.
      if (try? NativeBlob.data(envelope["images"][key], in: nativeBlobData)) != data {
        envelope["images"][key] = .object(["mime": .string(type == "public.png" ? "image/png" : "image/jpeg"), "data": .string(data.base64EncodedString())])
      }
      let current = node(board.screen)?.children.first { $0.type == "image" }
      let sameDimensions = current?.raw["kind"]["width"].double == Double(image.width)
        && current?.raw["kind"]["height"].double == Double(image.height)
        && current?.raw["kind"]["xf"].affine != nil
      let imageID = try current?.id ?? allocateID()
      var raw = current?.raw ?? .object(["id": .integer(imageID), "name": .string("Screenshot"), "kind": .object(["type": .string("image")])])
      raw["kind"]["key"] = .string(key); raw["kind"]["width"] = .integer(Int64(image.width)); raw["kind"]["height"] = .integer(Int64(image.height))
      if !sameDimensions { raw["kind"]["xf"] = CGAffineTransform.identity.json }
      updateNode(board.screen) { value in
        var children = value["kind"]["children"].array.filter { $0["id"].int != imageID }
        children.append(raw); value["kind"]["children"] = .array(children)
      }
      // Existing Move/Scale/Rotate edits are authoritative for same-size replacements.
      // A differently sized image uses the stored fit/crop settings for its new pixel space.
      if !sameDimensions {
        try cropScreenshot(board, scale: current?.raw["screenshotCrop"]["scale"].double ?? 1,
          x: current?.raw["screenshotCrop"]["x"].double ?? 0, y: current?.raw["screenshotCrop"]["y"].double ?? 0,
          fit: current?.raw["screenshotCrop"]["fit"].boolean ?? false)
      }
      updateScreenshotBoard(id) { $0["used"] = .bool(true) }
      return [imageID]
    case .crop:
      try cropScreenshot(board, scale: c.scale ?? 1, x: c.cropX ?? 0, y: c.cropY ?? 0, fit: c.fit ?? false)
      return [board.screen]
    case .setFrame:
      return try setScreenshotFrame(board, metadata: c.frame)
    default: throw DrawingError.invalid("Invalid screenshot command target.")
    }
  }

  private mutating func addScreenshotBoard(rowIndex r: Int, template: String, reuseEmptyBoard: Bool, slot: Int? = nil) throws -> Set<Int64> {
    guard ScreenshotTemplate.all.contains(where: { $0.id == template }) else { throw DrawingError.invalid("Unknown screenshot template.") }
    var rows = envelope["document"]["unknown"]["screenshots"]["rows"].array
    guard rows.indices.contains(r), rows[r]["boards"].array.count < 10,
      let w = rows[r]["width"].double, let h = rows[r]["height"].double else { throw DrawingError.invalid("A screenshot row supports up to ten artboards.") }
    let occupied = Set(screenshotRows[r].boards.enumerated().map { Int($0.element.raw["slot"].int ?? Int64($0.offset)) })
    guard let slot = slot ?? (0..<10).first(where: { !occupied.contains($0) }),
      (0..<10).contains(slot), !occupied.contains(slot) else { throw DrawingError.invalid("Choose an empty screenshot slot.") }
    let layer = try perform(.addLayer).first ?? 0
    let rect = CGRect(x: 0, y: 0, width: w, height: h)
    func style(_ r: Double, _ g: Double, _ b: Double) -> VectorStyle { VectorStyle(fill: VectorStyle.solid(r, g, b), stroke: VectorStyle.none, width: 0) }
    let background = try perform(.addPath([ShapePaths.rectangle(rect)], style(0.078, 0.243, 0.388), layer: layer)).first ?? 0
    let body = ScreenshotTemplate.deviceRect(template, in: rect)
    let screen = body.insetBy(dx: w * 0.022, dy: w * 0.022)
    let bodyPath = try PathGeometry.subpaths(CGPath(roundedRect: body, cornerWidth: w * 0.06, cornerHeight: w * 0.06, transform: nil))
    let screenPath = try PathGeometry.subpaths(CGPath(roundedRect: screen, cornerWidth: w * 0.045, cornerHeight: w * 0.045, transform: nil))
    let bodyID = try perform(.addPath(bodyPath, style(0.07, 0.07, 0.07), layer: layer)).first ?? 0
    updateNode(bodyID) { $0["screenshotFrameBody"] = .bool(true) }
    let mask = try perform(.addPath(screenPath, style(1, 1, 1), layer: layer)).first ?? 0
    let placeholder = try perform(.addPath(screenPath, style(0.92, 0.92, 0.92), layer: layer)).first ?? 0
    let clip = try perform(.group([mask, placeholder])).first ?? 0
    updateNode(clip) { $0["kind"]["clip"] = .bool(true); $0["name"] = .string("Device Screen") }
    let device = try perform(.group([bodyID, clip])).first ?? 0
    updateNode(device) { $0["name"] = .string("Generic Device Frame") }
    var content = device
    do {
      let headline = try perform(.addAreaText(template == "split" ? "Made for\nEvery Day" : "Find Every\nBusiness",
        ScreenshotTemplate.textRect(template, in: rect),
        font: "Helvetica", size: w * 0.07, fill: VectorStyle.solid(1, 1, 1), layer: layer)).first ?? 0
      updateNode(headline) { value in
        var runs = value["kind"]["runs"].array
        for index in runs.indices { runs[index]["style"]["font_style"] = .string("Bold") }
        value["kind"]["runs"] = .array(runs)
      }
      content = try perform(.group([device, headline])).first ?? 0
      updateNode(headline) { $0["visible"] = .bool(template != "minimal") }
      updateNode(content) { $0["name"] = .string("Screenshot Artwork") }
    }
    var artboards = envelope["document"]["artboards"].array
    let largestID = artboards.compactMap { $0["id"].int }.max() ?? 0
    guard largestID < Int64.max else { throw DrawingError.invalid("No artboard IDs remain.") }
    let id = reuseEmptyBoard ? artboards.first?["id"].int ?? 1 : largestID + 1
    let rawBoard: JSONValue = .object(["id": .integer(id), "name": .string("\(rows[r]["name"].string) \(slot + 1)"), "rect": screenshotRect(rect)])
    if reuseEmptyBoard { artboards[0] = rawBoard } else { artboards.append(rawBoard) }
    envelope["document"]["artboards"] = .array(artboards)
    var boards = rows[r]["boards"].array
    boards.append(.object(["id": .integer(id), "layer": .integer(layer), "content": .integer(content), "device": .integer(device),
      "screen": .integer(clip), "background": .integer(background), "landscape": .bool(false), "template": .string(template), "slot": .integer(Int64(slot)), "used": .bool(false)]))
    rows[r]["boards"] = .array(boards)
    envelope["document"]["unknown"]["screenshots"]["rows"] = .array(rows)
    updateNode(layer) { $0["name"] = .string("\(rows[r]["name"].string) · \(boards.count)") }
    try reflowScreenshots()
    return [content]
  }
  private func screenshotRect(_ rect: CGRect) -> JSONValue {
    .object(["x0": .number(rect.minX), "y0": .number(rect.minY), "x1": .number(rect.maxX), "y1": .number(rect.maxY)])
  }
  private mutating func setScreenshotRect(index: Int, rect: CGRect) {
    var boards = envelope["document"]["artboards"].array
    boards[index]["rect"] = screenshotRect(rect)
    envelope["document"]["artboards"] = .array(boards)
  }
  mutating func reflowScreenshots() throws {
    let version = version
    for slot in screenshotSlots {
      guard let id = slot.boardID else { continue }
      guard let board = screenshotBoard(id), let index = artboardIndex(id: id) else { throw DrawingError.invalid("Missing screenshot artboard.") }
      let old = artboards[index], next = slot.rect
      let delta = CGAffineTransform(translationX: next.minX - old.minX, y: next.minY - old.minY)
      try updateNode(board.layer) { try Self.transformNode(&$0, delta, version: version) }
      setScreenshotRect(index: index, rect: next)
    }
  }
  private func screenshotCropGeometry(_ board: ScreenshotBoard) -> (rect: CGRect, transform: CGAffineTransform)? {
    guard let frame = node(board.device)?.children.first(where: { $0.raw["kind"]["screenshotLocalFrame"] != .null }),
      let transform = frame.raw["kind"]["xf"].affine else { return nil }
    let screen = frame.raw["kind"]["screenshotLocalFrame"]["screen"]
    guard let x = screen["x"].double, let y = screen["y"].double,
      let width = screen["width"].double, let height = screen["height"].double,
      [x, y, width, height].allSatisfy(\.isFinite), width > 0, height > 0 else { return nil }
    return (CGRect(x: x, y: y, width: width, height: height), transform)
  }
  private mutating func cropScreenshot(_ board: ScreenshotBoard, scale: Double, x: Double, y: Double, fit: Bool) throws {
    guard scale.isFinite, (0.1...10).contains(scale), x.isFinite, y.isFinite,
      let clip = node(board.screen)?.children.first?.bounds,
      let image = node(board.screen)?.children.first(where: { $0.type == "image" }),
      let w = image.raw["kind"]["width"].double, let h = image.raw["kind"]["height"].double else {
      throw DrawingError.invalid("Insert a screenshot before cropping; use a scale between0.1and10.")
    }
    // An alpha-derived clip may extend beneath the bezel's antialias edge. Its bounds are
    // not the logical display rectangle, and arbitrary device transforms must remain intact.
    let geometry = screenshotCropGeometry(board)
    let target = geometry?.rect ?? clip
    let factor = (fit ? min(target.width / w, target.height / h) : max(target.width / w, target.height / h)) * scale
    let xf = CGAffineTransform(a: factor, b: 0, c: 0, d: factor,
      tx: target.midX - w * factor / 2 + x * target.width, ty: target.midY - h * factor / 2 + y * target.height)
      .concatenating(geometry?.transform ?? .identity)
    updateNode(image.id) { $0["kind"]["xf"] = xf.json
      $0["screenshotCrop"] = .object(["scale": .number(scale), "x": .number(x), "y": .number(y), "fit": .bool(fit)]) }
  }
}
