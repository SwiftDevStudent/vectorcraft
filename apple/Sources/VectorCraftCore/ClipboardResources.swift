import Foundation

/// Visits model references, never arbitrary foreign metadata. Definitions are copied as raw JSON.
struct ClipboardResource: Hashable, Comparable {
  var kind: String
  var name: String
  static func < (a: Self, b: Self) -> Bool { (a.kind, a.name) < (b.kind, b.name) }

  func definition(in drawing: Drawing) -> JSONValue? {
    let doc = drawing.envelope["document"]
    if kind == "images" {
      guard drawing.envelope["images"][name] != .null else { return nil }
      var resource = drawing.envelope["images"][name]
      if drawing.version == 4, resource["blob"] != .null {
        // A copied definition must be independent of the source document's arena.
        guard let inline = try? NativeBlob.materialized(resource, blobs: drawing.nativeBlobData)
        else { return nil }
        resource = inline
      }
      return .object([
        "blob": resource, "metadata": doc["images"][name],
      ])
    }
    let values: [JSONValue]
    if kind == "brushes" {
      values = doc["unknown"]["brushes"].array
    } else if kind == "swatches" {
      values = doc["swatches"].array + doc["swatch_groups"].array.flatMap { $0["swatches"].array }
    } else {
      values = doc[kind].array
    }
    return values.first { value in
      kind == "graphic_styles"
        ? value["id"].int.map(String.init) == name : value["name"].string == name
    }
  }

  func store(_ value: JSONValue, in drawing: inout Drawing) {
    if kind == "images" {
      drawing.envelope["images"][name] = value["blob"]
      if value["metadata"] != .null {
        drawing.envelope["document"]["images"][name] = value["metadata"]
      }
    } else if kind == "brushes" {
      var values = drawing.envelope["document"]["unknown"]["brushes"].array
      values.append(value)
      drawing.envelope["document"]["unknown"]["brushes"] = .array(values)
    } else {
      var values = drawing.envelope["document"][kind].array
      values.append(value)
      drawing.envelope["document"][kind] = .array(values)
    }
  }

  static func editNode(
    _ raw: inout JSONValue, reference: (Self) throws -> Self,
    nodeID: (Int64) throws -> Int64 = { $0 }
  ) throws {
    guard let id = raw["id"].int, id > 0 else {
      throw DrawingError.invalid("Clipboard artwork has an invalid object ID.")
    }
    raw["id"] = .integer(try nodeID(id))
    if let style = raw["graphic_style"].int, style > 0 {
      let mapped = try reference(Self(kind: "graphic_styles", name: String(style)))
      guard let id = Int64(mapped.name) else {
        throw DrawingError.invalid("Invalid graphic style.")
      }
      raw["graphic_style"] = .integer(id)
    }
    if raw["appearance"] != .null { try editAppearance(&raw["appearance"], reference) }
    var kind = raw["kind"]
    switch kind["type"].string {
    case "path": break
    case "text":
      var runs = kind["runs"].array
      for i in runs.indices {
        try editAttributes(&runs[i]["style"], reference)
        try editName(&runs[i]["style"], "style_name", "char_styles", reference)
      }
      kind["runs"] = .array(runs)
      if kind["para"] != .null {
        try editName(&kind["para"], "style_name", "para_styles", reference)
      }
    case "image": try editName(&kind, "key", "images", reference)
    case "symbolinstance": try editName(&kind, "symbol", "symbols", reference)
    case "layer", "group", "compound", "blend":
      var children = kind["children"].array
      for i in children.indices { try editNode(&children[i], reference: reference, nodeID: nodeID) }
      kind["children"] = .array(children)
    default:
      throw DrawingError.invalid(
        "Copying \(kind["type"].string) artwork is not supported yet. Native saving preserves it.")
    }
    raw["kind"] = kind
    if raw["mask"]["art"] != .null {
      try editNode(&raw["mask"]["art"], reference: reference, nodeID: nodeID)
    }
  }

  func editDefinition(
    _ raw: inout JSONValue, reference: (Self) throws -> Self,
    nodeID: (Int64) throws -> Int64 = { $0 }
  ) throws {
    switch kind {
    case "symbols": try Self.editNode(&raw["art"], reference: reference, nodeID: nodeID)
    case "patterns":
      var art = raw["art"].array
      for i in art.indices { try Self.editNode(&art[i], reference: reference, nodeID: nodeID) }
      raw["art"] = .array(art)
    case "brushes":
      for key in ["art", "side", "outer_corner", "inner_corner", "start", "end"]
      where raw[key] != .null {
        try Self.editNode(&raw[key], reference: reference, nodeID: nodeID)
      }
    case "graphic_styles": try Self.editAppearance(&raw["appearance"], reference)
    case "swatches": try Self.editPaint(&raw["paint"], reference)
    case "char_styles", "para_styles": try Self.editAttributes(&raw["attrs"], reference)
    default: break
    }
  }

  private static func editName(
    _ value: inout JSONValue, _ key: String, _ kind: String, _ reference: (Self) throws -> Self
  ) throws {
    if case .string(let name) = value[key], !name.isEmpty {
      value[key] = .string(try reference(Self(kind: kind, name: name)).name)
    }
  }
  private static func editAttributes(
    _ value: inout JSONValue, _ reference: (Self) throws -> Self
  ) throws {
    for key in ["fill", "stroke"] where value[key] != .null {
      try editPaint(&value[key], reference)
    }
  }
  private static func editAppearance(
    _ value: inout JSONValue, _ reference: (Self) throws -> Self
  ) throws {
    guard case .object = value else { return }
    var items = value["items"].array
    for i in items.indices {
      if items[i]["paint"] != .null { try editPaint(&items[i]["paint"], reference) }
      try editName(&items[i], "brush", "brushes", reference)
    }
    value["items"] = .array(items)
  }
  private static func editPaint(
    _ value: inout JSONValue, _ reference: (Self) throws -> Self
  ) throws {
    guard case .object = value else { return }
    try editName(&value, "swatch", "swatches", reference)
    if value["type"].string == "pattern" { try editName(&value, "pattern", "patterns", reference) }
    if value["type"].string == "gradient" {
      if value["gradient"] != .null {
        try editName(&value["gradient"], "swatch", "swatches", reference)
      }
      var stops = value["gradient"]["stops"].array
      for i in stops.indices { try editName(&stops[i], "swatch", "swatches", reference) }
      value["gradient"]["stops"] = .array(stops)
    }
  }
}
