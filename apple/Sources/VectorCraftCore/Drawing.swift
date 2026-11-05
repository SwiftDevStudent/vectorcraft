import CoreGraphics
import Foundation

public struct VectorNode: Equatable, Sendable, Identifiable {
  public var raw: JSONValue
  public init(raw: JSONValue) { self.raw = raw }
  public var id: Int64 { raw["id"].int ?? 0 }
  public var name: String { raw["name"].string.isEmpty ? type.capitalized : raw["name"].string }
  public var type: String { raw["kind"]["type"].string }
  public var visible: Bool { raw["visible"].boolean ?? true }
  public var locked: Bool { raw["locked"].boolean ?? false }
  public var opacity: Double { raw["opacity"].double ?? 1 }
  public var children: [VectorNode] { raw["kind"]["children"].array.map(VectorNode.init) }
  public var subpaths: [VectorSubpath] {
    if type == "compound" { return children.flatMap(\.subpaths) }
    return
      raw["kind"]["path"]["subpaths"].array.map {
        VectorSubpath(
          anchors: $0["anchors"].array.compactMap(VectorAnchor.init),
          closed: $0["closed"].boolean ?? false)
      }
  }
  public var cgPath: CGPath {
    let path = CGMutablePath()
    if type == "compound" {
      for child in children { path.addPath(child.cgPath) }
    } else {
      for subpath in subpaths { path.addPath(subpath.cgPath) }
    }
    return path
  }
  public var bounds: CGRect {
    if type == "path" || type == "compound" { return cgPath.boundingBoxOfPath }
    if type == "image" { return VectorImage.bounds(self) }
    if type == "text" {
      if let rect = VectorText.areaRect(self) {
        return rect.applying(raw["kind"]["xf"].affine ?? .identity)
      }
      return VectorText.parts(self).reduce(CGRect.null) { $0.union($1.path.boundingBoxOfPath) }
    }
    if ["layer", "group"].contains(type), raw["kind"]["clip"].boolean == true, let clip = children.first { return clip.bounds }
    return children.reduce(CGRect.null) { $0.union($1.bounds) }
  }
  public var editable: Bool {
    ["path", "group", "layer", "compound", "text", "image"].contains(type) && raw["mask"] == .null
      && raw["graph"] == .null
      && (type != "compound" || children.allSatisfy { ["path", "compound"].contains($0.type) })
      && children.allSatisfy(\.editable)
  }
}

public struct Drawing: Equatable, Sendable {
  public var envelope: JSONValue
  /// Keep the wire arena intact so unsupported fields' offsets remain meaningful on save.
  public let nativeBlobData: Data
  public init(envelope: JSONValue, nativeBlobData: Data = Data()) {
    self.envelope = envelope
    self.nativeBlobData = nativeBlobData
  }
  public init(width: Double = 800, height: Double = 800) {
    nativeBlobData = Data()
    let layer: JSONValue = .object([
      "id": .integer(1), "name": .string("Layer 1"),
      "kind": .object([
        "type": .string("layer"), "color": .object(["Preset": .integer(0)]), "children": .array([]),
      ]),
    ])
    envelope = .object([
      "format": .string("vectorcraft"), "version": .integer(4), "images": .object([:]),
      "document": .object([
        "version": .integer(1), "title": .string("Untitled"), "units": .string("Points"),
        "color_mode": .string("Rgb"),
        "next_id": .integer(2), "layers": .array([layer]),
        "artboards": .array([
          .object([
            "id": .integer(1), "name": .string("Artboard 1"),
            "rect": .object([
              "x0": .number(0), "y0": .number(0), "x1": .number(width), "y1": .number(height),
            ]),
          ])
        ]),
      ]),
    ])
  }
  public var version: Int64 { envelope["version"].int ?? 4 }
  public var layers: [VectorNode] { envelope["document"]["layers"].array.map(VectorNode.init) }
  public var artboards: [CGRect] {
    envelope["document"]["artboards"].array.compactMap { $0["rect"].rect }
  }
  public var artboard: CGRect { artboards.first ?? CGRect(x: 0, y: 0, width: 800, height: 800) }
  public var title: String { envelope["document"]["title"].string }

  public func node(_ id: Int64) -> VectorNode? {
    func find(_ nodes: [VectorNode]) -> VectorNode? {
      for node in nodes {
        if node.id == id { return node }
        if let match = find(node.children) { return match }
      }
      return nil
    }
    return find(layers)
  }

  public func hitTest(
    _ point: CGPoint, tolerance: CGFloat, selectingGroups: Bool = false,
    within isolation: Int64? = nil
  ) -> Int64? {
    func hit(_ nodes: [VectorNode]) -> Int64? {
      for node in nodes.reversed() where node.visible && !node.locked {
        if ["layer", "group"].contains(node.type) {
          if let id = hit(node.children) {
            return selectingGroups && node.type == "group" ? node.id : id
          }
        } else if node.editable {
          if ["text", "image"].contains(node.type),
            node.bounds.insetBy(dx: -tolerance, dy: -tolerance).contains(point)
          {
            return node.id
          }
          let path = node.cgPath
          let filled = node.raw["appearance"]["items"].array.contains {
            $0["kind"].string == "fill" && $0["paint"]["type"].string != "none"
          }
          if (filled
            && path.contains(
              point, using: node.raw["kind"]["rule"].string == "EvenOdd" ? .evenOdd : .winding))
            || path.copy(
              strokingWithWidth: max(tolerance * 2, 1), lineCap: .round, lineJoin: .round,
              miterLimit: 10
            ).contains(point)
          {
            return node.id
          }
        }
      }
      return nil
    }
    return hit(selectionRoots(within: isolation))
  }

  public func canEdit(_ id: Int64) -> Bool {
    func check(_ nodes: [VectorNode], ancestorsAllowed: Bool) -> Bool {
      for node in nodes {
        let allowed = ancestorsAllowed && node.visible && !node.locked
        if node.id == id { return allowed && node.editable }
        if check(node.children, ancestorsAllowed: allowed) { return true }
      }
      return false
    }
    return check(layers, ancestorsAllowed: true)
  }

  public func canInsert(on id: Int64) -> Bool {
    func check(_ nodes: [VectorNode], allowed: Bool) -> Bool {
      for node in nodes {
        let available = allowed && node.visible && !node.locked
        if node.id == id { return available && ["layer", "group"].contains(node.type) }
        if check(node.children, allowed: available) { return true }
      }
      return false
    }
    return check(layers, allowed: true)
  }

  public mutating func updateNode(_ id: Int64, _ body: (inout JSONValue) throws -> Void) rethrows {
    func update(_ value: inout JSONValue) throws {
      if value["id"].int == id {
        try body(&value)
        return
      }
      var kind = value["kind"]
      var children = kind["children"].array
      for index in children.indices { try update(&children[index]) }
      if !children.isEmpty {
        kind["children"] = .array(children)
        value["kind"] = kind
      }
    }
    var nodes = envelope["document"]["layers"].array
    for index in nodes.indices { try update(&nodes[index]) }
    envelope["document"]["layers"] = .array(nodes)
  }

  public func validate() throws {
    func checkNumbers(_ value: JSONValue) throws {
      switch value {
      case .number(let n):
        guard n.isFinite else {
          throw DrawingError.invalid("The document contains a non-finite number.")
        }
      case .object(let values): for value in values.values { try checkNumbers(value) }
      case .array(let values): for value in values { try checkNumbers(value) }
      default: break
      }
    }
    try checkNumbers(envelope)
    guard !layers.isEmpty, !artboards.isEmpty,
      envelope["document"]["artboards"].array.count == artboards.count
    else {
      throw DrawingError.invalid("The document needs valid layers and artboards.")
    }
    var ids = Set<Int64>()
    var count = 0
    func walk(_ nodes: [VectorNode]) throws {
      for node in nodes {
        count += 1
        guard count <= 100_000, node.id > 0, ids.insert(node.id).inserted, !node.type.isEmpty else {
          throw DrawingError.invalid(
            "The document has invalid or duplicate object IDs, or too many objects.")
        }
        if node.type == "path" {
          for subpath in node.raw["kind"]["path"]["subpaths"].array {
            for anchor in subpath["anchors"].array {
              func valid(_ value: JSONValue, optional: Bool) -> Bool {
                if optional && value == .null { return true }
                guard let p = value.point else { return false }
                return abs(p.x) <= 1_000_000 && abs(p.y) <= 1_000_000
              }
              guard valid(anchor["p"], optional: false), valid(anchor["in"], optional: true),
                valid(anchor["out"], optional: true)
              else {
                throw DrawingError.invalid("The document contains invalid path coordinates.")
              }
            }
          }
        }
        if node.type == "text" {
          let kind = node.raw["kind"]
          guard kind["xf"].affine != nil,
            kind["xf"].array.allSatisfy({ abs($0.double ?? .infinity) <= 1_000_000 }),
            kind["runs"].array.reduce(0, { $0 + $1["text"].string.utf16.count }) <= 100_000,
            kind["runs"].array.allSatisfy({ run in
              let style = run["style"]
              return (0.1...10000).contains(style["size"].double ?? 0)
                && abs(style["tracking"].double ?? 0) <= 100_000
                && abs(style["baseline_shift"].double ?? 0) <= 100_000
                && (0...10000).contains(style["leading"].double ?? 0)
            })
          else {
            throw DrawingError.invalid("The document has invalid or oversized text.")
          }
        }
        try walk(node.children)
      }
    }
    try walk(layers)
    guard let next = envelope["document"]["next_id"].int, next > (ids.max() ?? 0),
      next < Int64.max - 100_000
    else {
      throw DrawingError.invalid("The document has an invalid object ID counter.")
    }
  }

  public var renderingWarnings: [String] {
    var unsupported = Set<String>()
    func checkColor(_ color: JSONValue) {
      switch color["model"].string {
      case "lab": unsupported.insert("Lab colors")
      case "cmyk": unsupported.insert("CMYK color conversion")
      case "rgb", "gray", "": break
      default: unsupported.insert("unknown color models")
      }
    }
    func walk(_ nodes: [VectorNode]) {
      for node in nodes {
        if node.type == "compound",
          node.children.contains(where: { !["path", "compound"].contains($0.type) })
        {
          unsupported.insert("non-path compound content")
        }
        if !["path", "layer", "group", "compound", "text", "image"].contains(node.type) {
          unsupported.insert(node.type)
        }
        if node.type == "text" { unsupported.formUnion(VectorText.warnings(node)) }
        if node.type == "image", VectorImage.resolve(node, images: envelope["images"], blobs: nativeBlobData) == nil { unsupported.insert("unavailable image resources") }
        for run in node.raw["kind"]["runs"].array {
          checkColor(run["style"]["fill"]["color"])
          checkColor(run["style"]["stroke"]["color"])
        }
        if node.raw["mask"] != .null { unsupported.insert("opacity masks") }
        if node.raw["knockout"].boolean == true
          || node.raw["knockout"].string.caseInsensitiveCompare("on") == .orderedSame
          || node.raw["knockout_shape"].boolean == true
        {
          unsupported.insert("knockout groups")
        }
        if node.raw["kind"]["clip"].boolean == true, let clip = node.children.first,
          !["path", "compound"].contains(clip.type) || clip.raw["kind"]["rule"].string == "EvenOdd"
        {
          unsupported.insert("complex clipping")
        }
        if !node.raw["appearance"]["effects"].array.isEmpty { unsupported.insert("effects") }
        if ["layer", "group"].contains(node.type), !node.raw["appearance"]["items"].array.isEmpty {
          unsupported.insert("container appearance")
        }
        if node.raw["blend"].string != "" && node.raw["blend"].string != "Normal" {
          unsupported.insert("blend modes")
        }
        for item in node.raw["appearance"]["items"].array {
          if item["kind"].string == "effect" || !item["effects"].array.isEmpty {
            unsupported.insert("effects")
          }
          if !["", "none", "solid", "gradient"].contains(item["paint"]["type"].string) {
            unsupported.insert("complex paints")
          }
          if item["paint"]["type"].string == "gradient" {
            let paint = item["paint"]
            for stop in paint["gradient"]["stops"].array { checkColor(stop["color"]) }
            if !["Linear", "Radial"].contains(paint["gradient"]["kind"].string)
              || paint["freeform"] != .null
            {
              unsupported.insert("complex gradients")
            }
            if paint["geom"]["focal"] != .null { unsupported.insert("focal gradients") }
            if paint["gradient"]["stops"].array.contains(where: {
              ($0["midpoint"].double ?? 0.5) != 0.5
            }) {
              unsupported.insert("gradient midpoints")
            }
          }
          if item["blend"].string != "" && item["blend"].string != "Normal" {
            unsupported.insert("appearance blend modes")
          }
          if item["kind"].string == "stroke", !["", "Center"].contains(item["align"].string) {
            unsupported.insert("stroke alignment")
          }
          if item["start_arrow"] != .null || item["end_arrow"] != .null {
            unsupported.insert("arrowheads")
          }
          if item["profile"] != .null { unsupported.insert("width profiles") }
          if item["brush"] != .null { unsupported.insert("brushes") }
          if item["overprint"].boolean == true { unsupported.insert("overprint") }
          if item["dash"]["align_corners"].boolean == true { unsupported.insert("aligned dashes") }
          if !["", "Within"].contains(item["gradient_mode"].string) {
            unsupported.insert("stroke gradient modes")
          }
          checkColor(item["paint"]["color"])
          if (item["width"].double ?? 1) > 10000 { unsupported.insert("oversized strokes") }
        }
        walk(node.children)
      }
    }
    walk(layers)
    if envelope["document"]["color_mode"].string == "Cmyk" {
      unsupported.insert("CMYK color conversion")
    }
    for profiles in [
      envelope["document"]["color_profiles"], envelope["document"]["unknown"]["colorProfiles"],
    ] {
      if !profiles["rgb"].string.isEmpty || !profiles["cmyk"].string.isEmpty {
        unsupported.insert("color profiles")
      }
    }
    if !envelope["profiles"].object.isEmpty { unsupported.insert("color profiles") }
    return unsupported.sorted()
  }
}
