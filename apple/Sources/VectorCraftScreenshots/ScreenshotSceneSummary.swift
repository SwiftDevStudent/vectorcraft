import CoreGraphics
import CoreText
import Foundation
import VectorCraftCore

enum ScreenshotSceneSummary {
  static func make(_ drawing: Drawing) -> JSONValue {
    var nodes: [JSONValue] = []
    func walk(_ source: [VectorNode], parent: Int64?) {
      for node in source {
        var value: [String: JSONValue] = [
          "id": .integer(node.id), "name": .string(node.name), "type": .string(node.type),
          "parent": parent.map(JSONValue.integer) ?? .null, "bounds": rect(node.bounds),
          "visible": .bool(node.visible), "locked": .bool(node.locked),
          "editable": .bool(drawing.canEdit(node.id)), "opacity": .number(node.opacity),
        ]
        if node.type == "text" {
          value["text"] = .string(node.raw["kind"]["runs"].array.map { $0["text"].string }.joined())
          value["textKind"] = node.raw["kind"]["kind"]["kind"]
          value["inlineEditable"] = .bool(VectorText.canEditInline(node))
          value["overset"] = .bool(VectorText.isOverset(node))
          value["frame"] = VectorText.areaRect(node).map(rect) ?? .null
          value["transform"] = node.raw["kind"]["xf"].affine?.json ?? .null
          value["runs"] = .array(node.raw["kind"]["runs"].array.map { run in
            let style = run["style"], font = VectorText.font(style)
            return .object([
              "text": run["text"], "fontFamily": style["font_family"], "fontStyle": style["font_style"],
              "size": style["size"], "resolvedFamily": .string(CTFontCopyFamilyName(font) as String),
              "resolvedPostScriptName": .string(CTFontCopyPostScriptName(font) as String),
            ])
          })
        } else if node.type == "image" {
          let image = VectorImage.resolve(node, images: drawing.envelope["images"], blobs: drawing.nativeBlobData)
          let local = VectorImage.localURL(node)
          value["transform"] = node.raw["kind"]["xf"].affine?.json ?? .null
          value["resource"] = .object([
            "key": node.raw["kind"]["key"], "available": .bool(image != nil),
            "pixelWidth": image.map { .integer(Int64($0.width)) } ?? .null,
            "pixelHeight": image.map { .integer(Int64($0.height)) } ?? .null,
            "file": local.map { .string($0.path) } ?? .null,
            "bookmarked": .bool(!node.raw["kind"]["screenshotLocalFrame"]["bookmark"].string.isEmpty),
          ])
        }
        nodes.append(.object(value))
        walk(node.children, parent: node.id)
      }
    }
    walk(drawing.layers, parent: nil)
    let slots = drawing.screenshotSlots
    let rows: [JSONValue] = drawing.screenshotRows.map { row in
      .object([
        "id": .string(row.id), "name": .string(row.name), "preset": row.raw["preset"],
        "slots": .array(slots.filter { $0.row == row.id }.map { slot in
          let board = slot.boardID.flatMap(drawing.screenshotBoard)
          return .object([
            "slot": .integer(Int64(slot.index + 1)), "bounds": rect(slot.rect),
            "board": board.map { .integer($0.id) } ?? .null,
            "layer": board.map { .integer($0.layer) } ?? .null,
            "content": board.map { .integer($0.content) } ?? .null,
            "device": board.map { .integer($0.device) } ?? .null,
            "screen": board.map { .integer($0.screen) } ?? .null,
            "template": board?.raw["template"] ?? .null, "display": board?.raw["display"] ?? .null,
            "included": .bool(board.map(drawing.screenshotIsIncluded) ?? false),
          ])
        }),
      ])
    }
    return .object([
      "schemaVersion": .integer(1), "format": drawing.envelope["format"],
      "nativeVersion": .integer(drawing.version), "title": .string(drawing.title),
      "coordinateSpace": .string("document points"), "slotNumbers": .string("one-based"),
      "artboards": .array(drawing.envelope["document"]["artboards"].array.map {
        .object(["id": $0["id"], "name": $0["name"], "bounds": $0["rect"].rect.map(rect) ?? .null])
      }),
      "screenshotRows": .array(rows), "nodes": .array(nodes),
      "includedScreenshots": .integer(Int64(drawing.includedScreenshotBoards.count)),
      "renderingWarnings": .array(drawing.renderingWarnings.map(JSONValue.string)),
    ])
  }
  private static func rect(_ value: CGRect) -> JSONValue {
    guard !value.isNull, [value.minX, value.minY, value.width, value.height].allSatisfy(\.isFinite)
    else { return .null }
    return .object(["x": .number(value.minX), "y": .number(value.minY),
      "width": .number(value.width), "height": .number(value.height)])
  }
}
