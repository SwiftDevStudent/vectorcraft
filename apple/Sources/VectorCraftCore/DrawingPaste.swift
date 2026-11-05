import CoreGraphics
import Foundation

public enum PastePlacement: Equatable, Sendable {
  case center(CGPoint)
  case inPlace(artboard: Int)
  case front, back
}

extension Drawing {
  mutating func paste(
    _ fragment: VectorFragment, placement: PastePlacement, container: Int64,
    relativeTo selection: Set<Int64>
  ) throws -> Set<Int64> {
    let source = fragment.drawing
    for key in ["color_mode", "color_profiles"] {
      guard source.envelope["document"][key] == envelope["document"][key] else {
        throw DrawingError.invalid(
          "Pasting between different document color settings is not supported yet.")
      }
    }
    guard
      source.envelope["document"]["unknown"]["colorProfiles"]
        == envelope["document"]["unknown"]["colorProfiles"],
      source.envelope["profiles"].object.isEmpty, envelope["profiles"].object.isEmpty
    else { throw DrawingError.invalid("Clipboard color profile conversion is not supported yet.") }

    var parent = container
    var anchor: Int64?
    if placement == .front || placement == .back {
      func collect(_ nodes: [VectorNode]) -> [Int64] {
        nodes.flatMap {
          selection.contains($0.id) && $0.type != "layer" ? [$0.id] : collect($0.children)
        }
      }
      let ordered = collect(layers)
      anchor = placement == .front ? ordered.last : ordered.first
      if let anchor, let path = ancestry(of: anchor), path.count >= 2 {
        parent = path[path.count - 2].id
      }
    }
    guard canInsert(on: parent) else {
      throw DrawingError.invalid("Choose an unlocked, visible layer or group before pasting.")
    }
    let translation: CGPoint
    switch placement {
    case .center(let center):
      let bounds = fragment.bounds
      guard !bounds.isNull else {
        throw DrawingError.invalid("This artwork cannot be centered yet. Use Paste in Place.")
      }
      translation = CGPoint(x: center.x - bounds.midX, y: center.y - bounds.midY)
    case .inPlace(let board):
      guard artboards.indices.contains(board) else {
        throw DrawingError.invalid("Choose a valid artboard.")
      }
      translation = CGPoint(
        x: artboards[board].minX - fragment.sourceArtboard.minX,
        y: artboards[board].minY - fragment.sourceArtboard.minY)
    case .front, .back: translation = .zero
    }
    guard translation.x.isFinite, translation.y.isFinite else {
      throw DrawingError.invalid("Invalid paste position.")
    }

    let kinds = [
      "swatches", "symbols", "patterns", "char_styles", "para_styles", "graphic_styles", "brushes",
      "images",
    ]
    var definitions: [ClipboardResource: JSONValue] = [:]
    for kind in kinds {
      let values =
        kind == "brushes"
        ? source.envelope["document"]["unknown"][kind].array
        : source.envelope["document"][kind].array
      let names =
        kind == "images"
        ? Array(source.envelope["images"].object.keys)
        : values.compactMap { value in
          kind == "graphic_styles" ? value["id"].int.map(String.init) : value["name"].string
        }
      for name in names {
        let ref = ClipboardResource(kind: kind, name: name)
        if let definition = ref.definition(in: source) { definitions[ref] = definition }
      }
    }
    var mapping: [ClipboardResource: ClipboardResource] = [:]
    var used = Set<ClipboardResource>()
    var imports: [ClipboardResource] = []
    for ref in definitions.keys.sorted() {
      guard let definition = definitions[ref] else { continue }
      var probe = definition
      var dependencies = Set<ClipboardResource>()
      try ref.editDefinition(
        &probe,
        reference: {
          dependencies.insert($0)
          return $0
        })
      // Leaf definitions may be reused exactly. Definitions with links are imported after all
      // names are allocated, so a dependency collision cannot bind to unrelated destination art.
      if dependencies.isEmpty, ref.definition(in: self) == definition, ref.kind != "symbols",
        ref.kind != "patterns", ref.kind != "brushes"
      {
        mapping[ref] = ref
        used.insert(ref)
        continue
      }
      var target = ref
      var suffix = 2
      if ref.kind == "graphic_styles" {
        var id: Int64 = 1
        while ClipboardResource(kind: ref.kind, name: String(id)).definition(in: self) != nil
          || used.contains(ClipboardResource(kind: ref.kind, name: String(id)))
        {
          id += 1
          guard id < Int64(UInt32.max) else {
            throw DrawingError.invalid("No graphic style IDs remain.")
          }
        }
        target.name = String(id)
      } else {
        while target.definition(in: self) != nil || used.contains(target) {
          target.name = "\(ref.name) \(suffix)"
          suffix += 1
        }
      }
      mapping[ref] = target
      used.insert(target)
      imports.append(ref)
    }
    func mapped(_ ref: ClipboardResource) throws -> ClipboardResource {
      guard let value = mapping[ref] else {
        throw DrawingError.invalid("Clipboard resource references are incomplete.")
      }
      return value
    }
    // Include IDs in resource art and masks as well as the main tree.
    func maximumID(_ value: JSONValue) -> Int64 {
      switch value {
      case .object(let values):
        let own = value["kind"]["type"].string.isEmpty ? 0 : (value["id"].int ?? 0)
        return max(own, values.values.map(maximumID).max() ?? 0)
      case .array(let values): return values.map(maximumID).max() ?? 0
      default: return 0
      }
    }
    let existingMaximum = maximumID(envelope)
    guard existingMaximum < Int64.max - 100_002 else {
      throw DrawingError.invalid("No object IDs remain.")
    }
    var nextID = max(envelope["document"]["next_id"].int ?? 0, existingMaximum + 1)
    func allocate(_ old: Int64) throws -> Int64 {
      guard nextID > 0, nextID < Int64.max - 100_001 else {
        throw DrawingError.invalid("No object IDs remain.")
      }
      defer { nextID += 1 }
      return nextID
    }
    for ref in imports {
      guard var value = definitions[ref], let target = mapping[ref] else { continue }
      try ref.editDefinition(&value, reference: mapped, nodeID: allocate)
      for key in ["art", "side", "outer_corner", "inner_corner", "start", "end"]
      where value[key] != .null {
        if case .array(var nodes) = value[key] {
          for i in nodes.indices { Self.convertClipboardPaths(&nodes[i], version: version) }
          value[key] = .array(nodes)
        } else {
          Self.convertClipboardPaths(&value[key], version: version)
        }
      }
      if ref.kind == "graphic_styles" {
        value["id"] = .integer(Int64(target.name) ?? 0)
      } else if ref.kind != "images" {
        value["name"] = .string(target.name)
      }
      target.store(value, in: &self)
    }
    var copies = fragment.nodes.map(\.raw)
    for i in copies.indices {
      try ClipboardResource.editNode(&copies[i], reference: mapped, nodeID: allocate)
      Self.convertClipboardPaths(&copies[i], version: version)
      if translation != .zero {
        guard VectorNode(raw: copies[i]).editable, source.renderingWarnings.isEmpty else {
          throw DrawingError.invalid(
            "This artwork cannot be repositioned safely yet. Use Paste in Place on an artboard with the same origin."
          )
        }
        try Self.transformNode(
          &copies[i], CGAffineTransform(translationX: translation.x, y: translation.y),
          version: version)
      }
    }
    envelope["document"]["next_id"] = .integer(nextID)
    updateNode(parent) { raw in
      var siblings = raw["kind"]["children"].array
      let index: Int
      if let anchor, let found = siblings.firstIndex(where: { $0["id"].int == anchor }) {
        index = placement == .front ? found + 1 : found
      } else {
        index = placement == .back ? 0 : siblings.count
      }
      siblings.insert(contentsOf: copies, at: index)
      raw["kind"]["children"] = .array(siblings)
    }
    return Set(copies.compactMap { $0["id"].int })
  }

  private static func convertClipboardPaths(_ raw: inout JSONValue, version: Int64) {
    func path(_ value: inout JSONValue) {
      guard value != .null else { return }
      var subpaths = value["subpaths"].array
      for i in subpaths.indices {
        var anchors = subpaths[i]["anchors"].array
        for j in anchors.indices {
          for key in ["p", "in", "out"] {
            if let point = anchors[j][key].point { anchors[j][key] = point.json(version: version) }
          }
        }
        subpaths[i]["anchors"] = .array(anchors)
      }
      value["subpaths"] = .array(subpaths)
    }
    if raw["kind"]["type"].string == "path" { path(&raw["kind"]["path"]) }
    if raw["kind"]["type"].string == "text", raw["kind"]["kind"]["frame"] != .null {
      path(&raw["kind"]["kind"]["frame"])
    }
    var children = raw["kind"]["children"].array
    for i in children.indices { convertClipboardPaths(&children[i], version: version) }
    if !children.isEmpty { raw["kind"]["children"] = .array(children) }
    if raw["mask"]["art"] != .null { convertClipboardPaths(&raw["mask"]["art"], version: version) }
  }
}
