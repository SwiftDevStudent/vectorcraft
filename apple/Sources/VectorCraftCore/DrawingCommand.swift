import CoreGraphics
import Foundation

public struct VectorStyle: Equatable, Sendable {
  public var fill: JSONValue
  public var stroke: JSONValue
  public var width: Double
  public var opacity: Double
  public init(
    fill: JSONValue = Self.solid(0.25, 0.35, 0.95),
    stroke: JSONValue = Self.solid(0.12, 0.14, 0.23), width: Double = 2, opacity: Double = 1
  ) {
    self.fill = fill
    self.stroke = stroke
    self.width = width
    self.opacity = opacity
  }
  public static let none: JSONValue = .object(["type": .string("none")])
  public static func solid(_ r: Double, _ g: Double, _ b: Double) -> JSONValue {
    .object([
      "type": .string("solid"),
      "color": .object(["model": .string("rgb"), "r": .number(r), "g": .number(g), "b": .number(b)]
      ),
    ])
  }
  public var appearance: JSONValue {
    .object([
      "items": .array([
        .object(["kind": .string("fill"), "paint": fill]),
        .object([
          "kind": .string("stroke"), "paint": stroke, "width": .number(width),
          "cap": .string("Round"), "join": .string("Round"),
        ]),
      ])
    ])
  }
  public init(node: VectorNode) {
    if node.type == "text", let run = node.raw["kind"]["runs"].array.first {
      fill = run["style"]["fill"]
      stroke = run["style"]["stroke"] == .null ? Self.none : run["style"]["stroke"]
      width = min(10000, max(0, run["style"]["stroke_width"].double ?? 0))
      opacity = min(1, max(0, node.opacity))
      return
    }
    let items = node.raw["appearance"]["items"].array
    fill = items.first { $0["kind"].string == "fill" }?["paint"] ?? Self.none
    stroke = items.first { $0["kind"].string == "stroke" }?["paint"] ?? Self.none
    width = min(10000, max(0, items.first { $0["kind"].string == "stroke" }?["width"].double ?? 1))
    opacity = min(1, max(0, node.opacity))
  }
}

public enum DrawingCommand {
  case screenshot(ScreenshotCommand)
  case addPath([VectorSubpath], VectorStyle, layer: Int64)
  case addText(String, CGPoint, font: String, size: Double, fill: JSONValue, layer: Int64)
  case addAreaText(String, CGRect, font: String, size: Double, fill: JSONValue, layer: Int64)
  case editText(Int64, String, font: String, size: Double)
  case resizeTextFrame(Int64, CGRect)
  case transform(Set<Int64>, CGAffineTransform, copy: Bool = false)
  case transformEach(Set<Int64>, IndividualTransform, copy: Bool = false)
  case paste(VectorFragment, PastePlacement, container: Int64, relativeTo: Set<Int64>)
  case replacePath(Int64, [VectorSubpath])
  case deleteAnchor(Int64, subpath: Int, anchor: Int)
  case style(Set<Int64>, VectorStyle)
  case gradient(Set<Int64>, PaintTarget, GradientEdit)
  case delete(Set<Int64>)
  case cut(Set<Int64>)
  case duplicate(Set<Int64>)
  case group(Set<Int64>)
  case ungroup(Int64)
  case arrange(Set<Int64>, front: Bool)
  case addLayer
  case rename(Int64, String)
  case visibility(Int64, Bool)
  case lock(Int64, Bool)
  case resizeArtboard(Int, CGSize)
  case align(Set<Int64>, VectorAlignment, artboard: Int)
  case pathfinder(Set<Int64>, PathfinderOperation)
  case makeCompound(Set<Int64>)
  case releaseCompound(Set<Int64>)
  case fillRule(Set<Int64>, VectorFillRule)

  public var label: String {
    switch self {
    case .screenshot(let command): command.label
    case .addPath: "Draw Path"
    case .addText, .addAreaText: "Add Text"
    case .editText: "Edit Text"
    case .resizeTextFrame: "Resize Text Frame"
    case .transform(_, _, let copy): copy ? "Copy" : "Transform"
    case .transformEach(_, _, let copy): copy ? "Copy Each" : "Transform Each"
    case .paste: "Paste"
    case .replacePath: "Edit Nodes"
    case .deleteAnchor: "Delete Anchor"
    case .style: "Change Style"
    case .gradient: "Change Gradient"
    case .delete: "Delete"
    case .cut: "Cut"
    case .duplicate: "Duplicate"
    case .group: "Group"
    case .ungroup: "Ungroup"
    case .arrange: "Arrange"
    case .addLayer: "New Layer"
    case .rename: "Rename"
    case .visibility: "Change Visibility"
    case .lock: "Change Lock"
    case .resizeArtboard: "Resize Artboard"
    case .align: "Align"
    case .pathfinder(_, let operation): operation.rawValue
    case .makeCompound: "Make Compound Path"
    case .releaseCompound: "Release Compound Path"
    case .fillRule: "Change Fill Rule"
    }
  }
}

extension Drawing {
  /// All edits enter here. A failed command leaves the original document intact.
  @discardableResult
  public mutating func perform(_ command: DrawingCommand, within isolation: Int64? = nil) throws
    -> Set<Int64>
  {
    if let isolation, !permits(command, within: isolation) {
      throw DrawingError.invalid(
        "Exit isolation before editing outside the isolated group or layer.")
    }
    var candidate = self
    let selection = try candidate.execute(command)
    if case .screenshot = command {} else { candidate.markEditedScreenshots(comparedTo: self) }
    try candidate.validate()
    if case .screenshot = command { _ = try NativeFormat.encode(candidate) }
    if case .paste = command { _ = try NativeFormat.encode(candidate) }
    self = candidate
    return selection
  }

  mutating func allocateID() throws -> Int64 {
    guard let id = envelope["document"]["next_id"].int, id > 0, id < Int64.max - 1 else {
      throw DrawingError.invalid("No object IDs remain.")
    }
    envelope["document"]["next_id"] = .integer(id + 1)
    return id
  }

  private mutating func execute(_ command: DrawingCommand) throws -> Set<Int64> {
    switch command {
    case .screenshot(let command): return try applyScreenshot(command)
    case .cut(let ids): return try execute(.delete(ids))
    case .paste(let fragment, let placement, let container, let selection):
      return try paste(fragment, placement: placement, container: container, relativeTo: selection)
    case .addPath(let paths, let style, let layer):
      guard canInsert(on: layer), paths.contains(where: { $0.anchors.count >= 2 }) else {
        throw DrawingError.invalid("Choose an unlocked, visible layer or group before drawing.")
      }
      let id = try allocateID()
      let raw: JSONValue = .object([
        "id": .integer(id), "name": .string("Path"), "opacity": .number(style.opacity),
        "appearance": style.appearance,
        "kind": .object([
          "type": .string("path"),
          "path": .object(["subpaths": .array(paths.map { $0.json(version: version) })]),
        ]),
      ])
      updateNode(layer) { value in
        var children = value["kind"]["children"].array
        children.append(raw)
        value["kind"]["children"] = .array(children)
      }
      return [id]
    case .addText(let text, let point, let font, let size, let fill, let layer):
      guard canInsert(on: layer), !text.isEmpty, text.utf16.count <= 100_000,
        (0.1...10000).contains(size), point.x.isFinite, point.y.isFinite
      else {
        throw DrawingError.invalid(
          "Choose a visible, unlocked layer or group and valid text settings.")
      }
      let id = try allocateID()
      let raw: JSONValue = .object([
        "id": .integer(id), "name": .string(String(text.prefix(40))),
        "kind": .object([
          "type": .string("text"), "kind": .object(["kind": .string("point")]),
          "xf": CGAffineTransform(translationX: point.x, y: point.y).json,
          "runs": .array([
            .object([
              "text": .string(text),
              "style": .object(["font_family": .string(font), "size": .number(size), "fill": fill]),
            ])
          ]),
        ]),
      ])
      updateNode(layer) { value in
        var children = value["kind"]["children"].array
        children.append(raw)
        value["kind"]["children"] = .array(children)
      }
      return [id]
    case .addAreaText(let text, let rect, let font, let size, let fill, let layer):
      guard [rect.minX, rect.minY, rect.width, rect.height].allSatisfy(\.isFinite),
        rect.width > 0, rect.height > 0, rect.width <= 1_000_000, rect.height <= 1_000_000
      else {
        throw DrawingError.invalid("Invalid text frame.")
      }
      let selection = try execute(
        .addText(text, rect.origin, font: font, size: size, fill: fill, layer: layer))
      if let id = selection.first {
        let path = ShapePaths.rectangle(CGRect(origin: .zero, size: rect.size)).json(
          version: version)
        updateNode(id) { value in
          value["kind"]["kind"] = .object([
            "kind": .string("area"),
            "frame": .object(["subpaths": .array([path])]),
          ])
        }
      }
      return selection
    case .editText(let id, let text, let font, let size):
      try requireEditable([id])
      guard let node = node(id), node.type == "text", text.utf16.count <= 100_000,
        (0.1...10000).contains(size)
      else { throw DrawingError.invalid("Invalid point text.") }
      guard VectorText.canEditInline(node)
      else {
        throw DrawingError.invalid(
          "This text has formatting the inline editor cannot yet preserve. Its original data is retained."
        )
      }
      updateNode(id) { value in
        var run = value["kind"]["runs"].array.first ?? .object([:])
        var style = run["style"]
        style["font_family"] = .string(font)
        style["size"] = .number(size)
        run["text"] = .string(text)
        run["style"] = style
        value["kind"]["runs"] = .array([run])
        value["name"] = .string(String(text.prefix(40)))
      }
      return [id]
    case .resizeTextFrame(let id, let rect):
      try requireEditable([id])
      guard let node = node(id), let local = VectorText.areaRect(node),
        let xf = node.raw["kind"]["xf"].affine,
        xf.b == 0, xf.c == 0, xf.a > 0, xf.d > 0,
        [rect.minX, rect.minY, rect.width, rect.height].allSatisfy(\.isFinite),
        rect.width > 0, rect.height > 0, rect.width <= 1_000_000, rect.height <= 1_000_000
      else {
        throw DrawingError.invalid(
          "Choose a rectangular text frame with an axis-aligned transform.")
      }
      let path = ShapePaths.rectangle(
        CGRect(
          origin: local.origin,
          size: CGSize(width: rect.width / xf.a, height: rect.height / xf.d))
      ).json(version: version)
      let moved = CGAffineTransform(
        a: xf.a, b: 0, c: 0, d: xf.d,
        tx: rect.minX - local.minX * xf.a, ty: rect.minY - local.minY * xf.d)
      updateNode(id) { value in
        value["kind"]["kind"]["frame"]["subpaths"] = .array([path])
        value["kind"]["xf"] = moved.json
      }
      return [id]
    case .transform(let ids, let transform, let copy):
      try requireEditable(ids)
      guard
        [transform.a, transform.b, transform.c, transform.d, transform.tx, transform.ty].allSatisfy(
          \.isFinite)
      else {
        throw DrawingError.invalid("The transform is invalid.")
      }
      let version = version
      if copy {
        var copies: [Int64: JSONValue] = [:]
        var newIDs = Set<Int64>()
        for id in topmost(ids) {
          guard let node = node(id), node.type != "layer" else { continue }
          var raw = node.raw
          try assignIDs(&raw)
          try Self.transformNode(&raw, transform, version: version)
          copies[id] = raw
          if let id = raw["id"].int { newIDs.insert(id) }
        }
        guard !newIDs.isEmpty else { throw DrawingError.invalid("Select artwork to copy.") }
        rewriteSiblings { values in
          values = values.flatMap { value in
            if let copy = copies[value["id"].int ?? 0] { return [value, copy] }
            return [value]
          }
        }
        return newIDs
      }
      for id in topmost(ids) {
        try updateNode(id) { value in try Self.transformNode(&value, transform, version: version) }
      }
      return ids
    case .transformEach(let ids, let values, let copy):
      try requireEditable(ids)
      let targets = topmost(ids).sorted()
      var random = TransformRandom(state: values.seed)
      let transforms = try targets.map { id -> (Int64, CGAffineTransform) in
        guard let node = node(id), node.type != "layer" else {
          throw DrawingError.invalid("Select artwork to transform individually.")
        }
        return (id, try values.matrix(in: node.bounds, random: &random))
      }
      var selected = Set<Int64>()
      for (id, matrix) in transforms {
        selected.formUnion(try execute(.transform([id], matrix, copy: copy)))
      }
      return selected
    case .replacePath(let id, let paths):
      try requireEditable([id])
      guard let original = node(id), ["path", "compound"].contains(original.type),
        original.type != "compound" || paths.count == original.subpaths.count,
        paths.allSatisfy({ $0.anchors.count >= 2 })
      else {
        throw DrawingError.invalid("A path needs at least two anchors.")
      }
      let version = version
      updateNode(id) { value in
        Self.replaceGeometry(&value, paths: paths[...], version: version)
      }
      return [id]
    case .deleteAnchor(let id, let subpath, let anchor):
      try requireEditable([id])
      guard let node = node(id), ["path", "compound"].contains(node.type) else {
        throw DrawingError.invalid("Select a path anchor.")
      }
      if node.type == "compound" {
        guard let (childID, component) = compoundPathComponent(id, subpath: subpath) else {
          throw DrawingError.invalid("That subpath no longer exists.")
        }
        _ = try execute(.deleteAnchor(childID, subpath: component, anchor: anchor))
        if self.node(id)?.children.isEmpty == true {
          rewriteSiblings { $0.removeAll { $0["id"].int == id } }
          return []
        }
        return [id]
      }
      var paths = node.raw["kind"]["path"]["subpaths"].array
      guard paths.indices.contains(subpath) else {
        throw DrawingError.invalid("That subpath no longer exists.")
      }
      var anchors = paths[subpath]["anchors"].array
      guard anchors.indices.contains(anchor) else {
        throw DrawingError.invalid("That anchor no longer exists.")
      }
      anchors.remove(at: anchor)
      if anchors.count < 2 {
        paths.remove(at: subpath)
      } else {
        paths[subpath]["anchors"] = .array(anchors)
      }
      if paths.isEmpty {
        rewriteSiblings { $0.removeAll { $0["id"].int == id } }
        return []
      }
      updateNode(id) { value in
        value["kind"]["path"]["subpaths"] = .array(paths)
        var kind = value["kind"]
        kind.remove("live")
        value["kind"] = kind
      }
      return [id]
    case .style(let ids, let style):
      try requireEditable(ids)
      guard style.width.isFinite, (0...10000).contains(style.width), style.opacity.isFinite,
        (0...1).contains(style.opacity)
      else {
        throw DrawingError.invalid("The style is invalid.")
      }
      for id in topmost(ids) {
        updateNode(id) { value in Self.applyStyle(&value, style) }
      }
      return ids
    case .gradient(let ids, let target, let edit):
      return try editGradient(ids, target: target, edit: edit)
    case .delete(let ids):
      try requireEditable(ids)
      guard ids.allSatisfy({ node($0)?.type != "layer" }) else {
        throw DrawingError.invalid("Use the layer controls to manage layers.")
      }
      rewriteSiblings { values in values.removeAll { ids.contains($0["id"].int ?? 0) } }
      return []
    case .duplicate(let ids):
      return try execute(.transform(ids, .init(translationX: 20, y: 20), copy: true))
    case .group(let ids):
      try requireEditable(ids)
      guard ids.count > 1, let siblings = siblingIDs(containing: ids), ids.isSubset(of: siblings),
        ids.allSatisfy({ node($0)?.type != "layer" })
      else {
        throw DrawingError.invalid("Select at least two objects in the same layer or group.")
      }
      let id = try allocateID()
      rewriteSiblings { values in
        guard ids.isSubset(of: Set(values.compactMap { $0["id"].int })) else { return }
        let children = values.filter { ids.contains($0["id"].int ?? 0) }
        let index = values.firstIndex { ids.contains($0["id"].int ?? 0) } ?? values.count
        values.removeAll { ids.contains($0["id"].int ?? 0) }
        values.insert(
          .object([
            "id": .integer(id), "name": .string("Group"),
            "kind": .object([
              "type": .string("group"), "children": .array(children), "clip": .bool(false),
            ]),
          ]), at: min(index, values.count))
      }
      return [id]
    case .ungroup(let id):
      try requireEditable([id])
      guard let group = node(id), group.type == "group", group.opacity == 1,
        group.raw["kind"]["clip"].boolean != true, group.raw["appearance"]["items"].array.isEmpty
      else {
        throw DrawingError.invalid("Only plain groups can be ungrouped in this editor.")
      }
      rewriteSiblings { values in
        values = values.flatMap { $0["id"].int == id ? group.children.map(\.raw) : [$0] }
      }
      return Set(group.children.map(\.id))
    case .arrange(let ids, let front):
      try requireEditable(ids)
      rewriteSiblings { values in
        let selected = values.filter { ids.contains($0["id"].int ?? 0) }
        let rest = values.filter { !ids.contains($0["id"].int ?? 0) }
        values = front ? rest + selected : selected + rest
      }
      return ids
    case .addLayer:
      let id = try allocateID()
      var layers = envelope["document"]["layers"].array
      layers.append(
        .object([
          "id": .integer(id), "name": .string("Layer \(layers.count+1)"),
          "kind": .object([
            "type": .string("layer"),
            "color": .object(["Preset": .integer(Int64(layers.count % 27))]),
            "children": .array([]),
          ]),
        ]))
      envelope["document"]["layers"] = .array(layers)
      return [id]
    case .rename(let id, let name):
      guard node(id) != nil else { throw DrawingError.invalid("The object no longer exists.") }
      updateNode(id) { $0["name"] = .string(String(name.prefix(256))) }
      return [id]
    case .visibility(let id, let visible):
      updateNode(id) { $0["visible"] = .bool(visible) }
      return []
    case .lock(let id, let locked):
      updateNode(id) { $0["locked"] = .bool(locked) }
      return []
    case .resizeArtboard(let index, let size):
      guard artboards.indices.contains(index), size.width.isFinite, size.height.isFinite,
        (1...100000).contains(size.width), (1...100000).contains(size.height)
      else {
        throw DrawingError.invalid("Artboard dimensions must be between 1 and 100,000 points.")
      }
      var boards = envelope["document"]["artboards"].array
      let rect = artboards[index]
      boards[index]["rect"]["x1"] = .number(rect.minX + size.width)
      boards[index]["rect"]["y1"] = .number(rect.minY + size.height)
      envelope["document"]["artboards"] = .array(boards)
      return []
    case .align(let ids, let alignment, let index):
      try requireEditable(ids)
      guard artboards.indices.contains(index) else {
        throw DrawingError.invalid("Invalid artboard.")
      }
      let selected = topmost(ids)
      let boxes = selected.compactMap { id -> (Int64, CGRect)? in
        guard let bounds = node(id)?.bounds, !bounds.isNull else { return nil }
        return (id, bounds)
      }
      guard boxes.count == selected.count else {
        throw DrawingError.invalid("The selection has no usable bounds.")
      }
      let target =
        boxes.count == 1 ? artboards[index] : boxes.reduce(CGRect.null) { $0.union($1.1) }
      let version = version
      for (id, bounds) in boxes {
        let delta = alignment.translation(from: bounds, to: target)
        try updateNode(id) { value in
          try Self.transformNode(&value, .init(translationX: delta.x, y: delta.y), version: version)
        }
      }
      return ids
    case .pathfinder(let ids, let operation): return try performPathfinder(ids, operation)
    case .makeCompound(let ids): return try makeCompound(ids)
    case .releaseCompound(let ids): return try releaseCompound(ids)
    case .fillRule(let ids, let rule):
      try requireEditable(ids)
      guard ids.allSatisfy({ node($0).map { ["path", "compound"].contains($0.type) } == true })
      else {
        throw DrawingError.invalid("Select paths to change their fill rule.")
      }
      for id in ids { updateNode(id) { $0["kind"]["rule"] = .string(rule.rawValue) } }
      return ids
    }
  }

  private func requireEditable(_ ids: Set<Int64>) throws {
    guard !ids.isEmpty, ids.allSatisfy(canEdit) else {
      throw DrawingError.invalid("Select unlocked, visible objects supported by this editor.")
    }
  }
  private func topmost(_ ids: Set<Int64>) -> Set<Int64> {
    var result = ids
    func walk(_ nodes: [VectorNode], selectedAncestor: Bool) {
      for node in nodes {
        if selectedAncestor { result.remove(node.id) }
        walk(node.children, selectedAncestor: selectedAncestor || ids.contains(node.id))
      }
    }
    walk(layers, selectedAncestor: false)
    return result
  }
  private mutating func assignIDs(_ value: inout JSONValue) throws {
    value["id"] = .integer(try allocateID())
    var children = value["kind"]["children"].array
    for index in children.indices { try assignIDs(&children[index]) }
    if !children.isEmpty { value["kind"]["children"] = .array(children) }
  }
  private func siblingIDs(containing ids: Set<Int64>) -> Set<Int64>? {
    func find(_ nodes: [VectorNode]) -> Set<Int64>? {
      let here = Set(nodes.map(\.id))
      if ids.isSubset(of: here) { return here }
      for node in nodes { if let found = find(node.children) { return found } }
      return nil
    }
    return find(layers)
  }
  mutating func rewriteSiblings(_ body: (inout [JSONValue]) -> Void) {
    func walk(_ values: inout [JSONValue]) {
      for index in values.indices {
        var children = values[index]["kind"]["children"].array
        if !children.isEmpty {
          walk(&children)
          values[index]["kind"]["children"] = .array(children)
        }
      }
      body(&values)
    }
    var values = envelope["document"]["layers"].array
    walk(&values)
    envelope["document"]["layers"] = .array(values)
  }
  private static func applyStyle(_ value: inout JSONValue, _ style: VectorStyle) {
    let type = value["kind"]["type"].string
    if ["layer", "group"].contains(type) {
      var children = value["kind"]["children"].array
      for index in children.indices {
        var childStyle = style
        childStyle.opacity = children[index]["opacity"].double ?? 1
        applyStyle(&children[index], childStyle)
      }
      value["kind"]["children"] = .array(children)
    } else if type == "text" {
      var runs = value["kind"]["runs"].array
      for index in runs.indices {
        runs[index]["style"]["fill"] = style.fill
        runs[index]["style"]["stroke"] = style.stroke
        runs[index]["style"]["stroke_width"] = .number(style.width)
      }
      value["kind"]["runs"] = .array(runs)
    } else {
      // Retain additional appearance items and effects when changing the first fill/stroke.
      var items = value["appearance"]["items"].array
      for (kind, paint) in [("fill", style.fill), ("stroke", style.stroke)] {
        if let index = items.firstIndex(where: { $0["kind"].string == kind }) {
          items[index]["paint"] = paint
          if kind == "stroke" { items[index]["width"] = .number(style.width) }
        } else {
          var item: JSONValue = .object(["kind": .string(kind), "paint": paint])
          if kind == "stroke" { item["width"] = .number(style.width) }
          items.append(item)
        }
      }
      value["appearance"]["items"] = .array(items)
    }
    value["opacity"] = .number(style.opacity)
    value.remove("graphic_style")
  }
  static func transformNode(
    _ raw: inout JSONValue, _ transform: CGAffineTransform, version: Int64
  ) throws {
    var items = raw["appearance"]["items"].array
    if items.contains(where: { $0["paint"]["type"].string == "gradient" }) {
      let bounds = VectorNode(raw: raw).bounds
      if !bounds.isNull {
        for index in items.indices where items[index]["paint"]["type"].string == "gradient" {
          var paint = items[index]["paint"]
          guard ["Linear", "Radial"].contains(paint["gradient"]["kind"].string) else {
            throw DrawingError.invalid(
              "This editor cannot transform freeform gradients yet. Native saving retains them.")
          }
          let width = max(0, items[index]["width"].double ?? 1)
          let paintBounds =
            items[index]["kind"].string == "stroke"
            ? bounds.insetBy(dx: -width / 2, dy: -width / 2) : bounds
          let geometry = GradientGeometry(paint: paint, bounds: paintBounds)
          let transformed = try geometry.transformed(
            transform, radial: paint["gradient"]["kind"].string == "Radial")
          let focal = paint["geom"]["focal"].point
          var geom = paint["geom"]
          for (key, value) in transformed.json().object { geom[key] = value }
          if let focal { geom["focal"] = focal.applying(transform).json(version: 1) }
          paint["geom"] = geom
          items[index]["paint"] = paint
        }
        raw["appearance"]["items"] = .array(items)
      }
    }
    if raw["kind"]["type"].string == "path" {
      var subpaths = raw["kind"]["path"]["subpaths"].array
      for si in subpaths.indices {
        var anchors = subpaths[si]["anchors"].array
        for ai in anchors.indices {
          for key in ["p", "in", "out"] {
            if let point = anchors[ai][key].point {
              anchors[ai][key] = point.applying(transform).json(version: version)
            }
          }
        }
        subpaths[si]["anchors"] = .array(anchors)
      }
      raw["kind"]["path"]["subpaths"] = .array(subpaths)
      var kind = raw["kind"]
      kind.remove("live")
      raw["kind"] = kind
    } else if ["text", "image"].contains(raw["kind"]["type"].string) {
      guard let current = raw["kind"]["xf"].affine else {
        throw DrawingError.invalid("Invalid text transform.")
      }
      raw["kind"]["xf"] = current.concatenating(transform).json
    } else {
      var children = raw["kind"]["children"].array
      for index in children.indices {
        try transformNode(&children[index], transform, version: version)
      }
      raw["kind"]["children"] = .array(children)
    }
  }
}
