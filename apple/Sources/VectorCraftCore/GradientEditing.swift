import CoreGraphics
import Foundation

public enum PaintTarget: String, CaseIterable, Sendable {
  case fill = "Fill"
  case stroke = "Stroke"
}
public enum GradientKind: String, CaseIterable, Sendable {
  case linear = "Linear"
  case radial = "Radial"
}

public enum GradientEdit: Equatable, Sendable {
  case kind(GradientKind)
  case angle(Double)
  case aspect(Double)
  case reverse
  case insertStop(Double)
  case removeStop(Int)
  case stopOffset(Int, Double)
  case stopOpacity(Int, Double)
  case stopColor(Int, JSONValue)
  case geometry(CGPoint, CGPoint)
}

/// Edits the existing paint tree rather than reconstructing its appearance or foreign fields.
public struct GradientPaint: Equatable, Sendable {
  public private(set) var raw: JSONValue
  public private(set) var selectedStop: Int?
  public let bounds: CGRect
  public var stops: [JSONValue] { raw["gradient"]["stops"].array }
  public var kind: GradientKind { raw["gradient"]["kind"].string == "Radial" ? .radial : .linear }
  public var start: CGPoint { GradientGeometry(paint: raw, bounds: bounds).start }
  public var end: CGPoint { GradientGeometry(paint: raw, bounds: bounds).end }
  public var aspect: Double { GradientGeometry(paint: raw, bounds: bounds).aspect }
  public var angle: Double { -atan2(end.y - start.y, end.x - start.x) * 180 / .pi }

  public init(_ paint: JSONValue, bounds: CGRect) throws {
    raw = paint
    self.bounds = bounds
    guard paint["type"].string == "gradient",
      GradientKind(rawValue: paint["gradient"]["kind"].string) != nil,
      paint["freeform"] == .null, paint["geom"]["focal"] == .null, paint["swatch"] == .null,
      !stops.isEmpty, stops.count <= 1024,
      !bounds.isNull,
      [bounds.minX, bounds.minY, bounds.width, bounds.height].allSatisfy(\.isFinite)
    else { throw DrawingError.invalid("Select a supported linear or radial path gradient.") }
    var previousOffset = 0.0
    for stop in stops {
      guard let offset = stop["offset"].double, offset.isFinite, (0...1).contains(offset),
        offset >= previousOffset,
        stop["swatch"] == .null, (stop["midpoint"].double ?? 0.5) == 0.5,
        stop["midpoint"] == .null || stop["midpoint"].double != nil,
        stop["opacity"] == .null || stop["opacity"].double != nil,
        (stop["opacity"].double ?? 1).isFinite,
        (0...1).contains(stop["opacity"].double ?? 1)
      else {
        throw DrawingError.invalid(
          "Linked stops or advanced gradient settings cannot be edited yet.")
      }
      _ = try Self.rgb(stop["color"])
      previousOffset = offset
    }
    try validateGeometry()
  }

  public static func paint(of node: VectorNode, target: PaintTarget) -> JSONValue {
    node.raw["appearance"]["items"].array.first {
      $0["kind"].string == target.rawValue.lowercased()
    }?["paint"] ?? VectorStyle.none
  }

  private static func initial(_ kind: GradientKind, bounds: CGRect) throws -> GradientPaint {
    var paint: JSONValue = .object([
      "type": .string("gradient"),
      "gradient": .object([
        "kind": .string(kind.rawValue),
        "stops": .array(
          [0.0, 1.0].map { offset in
            .object([
              "offset": .number(offset),
              "color": VectorStyle.solid(offset, offset, offset)["color"], "opacity": .number(1),
            ])
          }),
      ]),
    ])
    if kind == .linear, bounds.width <= 0.000001 { paint["angle"] = .number(90) }
    return try GradientPaint(paint, bounds: bounds)
  }

  public static func editing(
    _ paint: JSONValue, bounds: CGRect, with edit: GradientEdit, selecting index: Int? = nil
  ) throws
    -> GradientPaint
  {
    var gradient: GradientPaint
    if paint["type"].string == "gradient" {
      gradient = try GradientPaint(paint, bounds: bounds)
    } else {
      switch edit {
      case .kind(let kind): gradient = try initial(kind, bounds: bounds)
      case .geometry: gradient = try initial(.linear, bounds: bounds)
      default: throw DrawingError.invalid("Apply a gradient before editing its stops or geometry.")
      }
      guard ["none", "solid", ""].contains(paint["type"].string) else {
        throw DrawingError.invalid("This paint cannot be replaced by a supported gradient.")
      }
    }
    if let index, gradient.stops.indices.contains(index) { gradient.selectedStop = index }
    try gradient.apply(edit)
    return gradient
  }

  private mutating func apply(_ edit: GradientEdit) throws {
    var stops = self.stops
    func stopIndex(_ index: Int) throws {
      guard stops.indices.contains(index) else {
        throw DrawingError.invalid("Choose an existing gradient stop.")
      }
    }
    func unit(_ value: Double) throws {
      guard value.isFinite, (0...1).contains(value) else {
        throw DrawingError.invalid("Gradient stop values must be between 0 and 100%.")
      }
    }
    switch edit {
    case .kind(let newKind):
      if kind != newKind {
        raw["gradient"]["kind"] = .string(newKind.rawValue)
        var fitted = raw
        fitted.remove("geom")
        let geometry = GradientGeometry(paint: fitted, bounds: bounds)
        raw["geom"]["start"] = geometry.start.json(version: 1)
        raw["geom"]["end"] = geometry.end.json(version: 1)
        raw["geom"]["aspect"] = .number(1)
      }
    case .angle(let degrees):
      guard degrees.isFinite else { throw DrawingError.invalid("Enter a finite gradient angle.") }
      let length = start.distance(to: end)
      let radians = degrees.truncatingRemainder(dividingBy: 360) * .pi / 180
      let center =
        kind == .radial ? start : CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
      let radius = kind == .radial ? length : length / 2
      raw["geom"]["start"] =
        (kind == .radial
        ? center
        : CGPoint(x: center.x - cos(radians) * radius, y: center.y + sin(radians) * radius)).json(
          version: 1)
      raw["geom"]["end"] = CGPoint(
        x: center.x + cos(radians) * radius, y: center.y - sin(radians) * radius
      ).json(version: 1)
    case .aspect(let value):
      guard kind == .radial, value.isFinite, value > 0.000001, value <= 1_000_000 else {
        throw DrawingError.invalid("Enter a positive radial gradient aspect ratio.")
      }
      let first = start
      let last = end
      raw["geom"]["start"] = first.json(version: 1)
      raw["geom"]["end"] = last.json(version: 1)
      raw["geom"]["aspect"] = .number(value)
    case .geometry(let first, let last):
      raw["geom"]["start"] = first.json(version: 1)
      raw["geom"]["end"] = last.json(version: 1)
    case .reverse:
      if let index = selectedStop { selectedStop = stops.count - 1 - index }
      stops = stops.reversed().map { stop in
        var result = stop
        result["offset"] = .number(1 - (stop["offset"].double ?? 0))
        return result
      }
    case .insertStop(let offset):
      try unit(offset)
      guard stops.count < 1024 else {
        throw DrawingError.invalid("A gradient is limited to 1,024 editable stops.")
      }
      let sorted = stops.sorted { ($0["offset"].double ?? 0) < ($1["offset"].double ?? 0) }
      let a = sorted.last { ($0["offset"].double ?? 0) <= offset } ?? sorted.first ?? .null
      let b = sorted.first { ($0["offset"].double ?? 0) >= offset } ?? sorted.last ?? .null
      let span = (b["offset"].double ?? 0) - (a["offset"].double ?? 0)
      let t = span > 0 ? (offset - (a["offset"].double ?? 0)) / span : 0
      let ca = try Self.rgb(a["color"])
      let cb = try Self.rgb(b["color"])
      let color = zip(ca, cb).map { pair in pair.0 + (pair.1 - pair.0) * t }
      let opacity =
        (a["opacity"].double ?? 1) + ((b["opacity"].double ?? 1) - (a["opacity"].double ?? 1)) * t
      let inserted: JSONValue = .object([
        "offset": .number(offset),
        "color": VectorStyle.solid(color[0], color[1], color[2])["color"],
        "opacity": .number(opacity),
      ])
      let position = stops.firstIndex { ($0["offset"].double ?? 0) > offset } ?? stops.count
      stops.insert(inserted, at: position)
      selectedStop = position
    case .removeStop(let index):
      try stopIndex(index)
      guard stops.count > 2 else { throw DrawingError.invalid("Keep at least two gradient stops.") }
      stops.remove(at: index)
      selectedStop = min(index, stops.count - 1)
    case .stopOffset(let index, let value):
      try stopIndex(index)
      try unit(value)
      var stop = stops.remove(at: index)
      stop["offset"] = .number(value)
      let position = stops.firstIndex { ($0["offset"].double ?? 0) > value } ?? stops.count
      stops.insert(stop, at: position)
      selectedStop = position
    case .stopOpacity(let index, let value):
      try stopIndex(index)
      try unit(value)
      stops[index]["opacity"] = .number(value)
      selectedStop = index
    case .stopColor(let index, let color):
      try stopIndex(index)
      _ = try Self.rgb(color)
      stops[index]["color"] = color
      stops[index].remove("tint")
      selectedStop = index
    }
    raw["gradient"]["stops"] = .array(stops)
    try validateGeometry()
  }

  private func validateGeometry() throws {
    switch raw["geom"] {
    case .null: break
    case .object:
      guard raw["geom"]["start"].point != nil, raw["geom"]["end"].point != nil else {
        throw DrawingError.invalid("The gradient contains unsupported endpoint data.")
      }
    default: throw DrawingError.invalid("The gradient contains unsupported geometry data.")
    }
    for value in [raw["angle"], raw["geom"]["aspect"]] {
      guard value == .null || value.double?.isFinite == true else {
        throw DrawingError.invalid("The gradient contains invalid geometry settings.")
      }
    }
    guard
      [start.x, start.y, end.x, end.y, aspect].allSatisfy({ $0.isFinite && abs($0) <= 1_000_000 }),
      start.distance(to: end) > 0.000001, aspect > 0.000001
    else {
      throw DrawingError.invalid(
        "The gradient needs finite, distinct endpoints and a positive aspect ratio.")
    }
  }
  private static func rgb(_ color: JSONValue) throws -> [Double] {
    let values: [Double]
    switch color["model"].string {
    case "rgb":
      values = [color["r"].double ?? .nan, color["g"].double ?? .nan, color["b"].double ?? .nan]
    case "gray": values = Array(repeating: 1 - (color["k"].double ?? .nan), count: 3)
    default:
      throw DrawingError.invalid("This gradient color model cannot be edited faithfully yet.")
    }
    guard values.allSatisfy({ $0.isFinite && (0...1).contains($0) }) else {
      throw DrawingError.invalid("Invalid gradient stop color.")
    }
    return values
  }
}

extension Drawing {
  public func gradientTargets(_ ids: Set<Int64>) throws -> [VectorNode] {
    guard !ids.isEmpty else { throw DrawingError.invalid("Select paths before editing gradients.") }
    var targets: [Int64: VectorNode] = [:]
    func collect(_ node: VectorNode) throws {
      guard canEdit(node.id) else {
        throw DrawingError.invalid("Gradient targets must be unlocked and visible.")
      }
      if node.type == "group" {
        for child in node.children { try collect(child) }
      } else {
        guard ["path", "compound"].contains(node.type) else {
          throw DrawingError.invalid(
            "Gradient authoring currently requires paths or compound paths.")
        }
        targets[node.id] = node
      }
    }
    for id in ids.sorted() {
      guard let node = node(id) else {
        throw DrawingError.invalid("The selected object no longer exists.")
      }
      try collect(node)
    }
    guard !targets.isEmpty else {
      throw DrawingError.invalid("Select paths before editing gradients.")
    }
    return targets.values.sorted { $0.id < $1.id }
  }

  mutating func editGradient(_ ids: Set<Int64>, target: PaintTarget, edit: GradientEdit) throws
    -> Set<Int64>
  {
    for node in try gradientTargets(ids) {
      let paint = try GradientPaint.editing(
        GradientPaint.paint(of: node, target: target), bounds: node.bounds, with: edit)
      updateNode(node.id) { raw in
        var items = raw["appearance"]["items"].array
        let kind = target.rawValue.lowercased()
        if let index = items.firstIndex(where: { $0["kind"].string == kind }) {
          items[index]["paint"] = paint.raw
        } else {
          var item: JSONValue = .object(["kind": .string(kind), "paint": paint.raw])
          if target == .stroke { item["width"] = .number(1) }
          items.append(item)
        }
        raw["appearance"]["items"] = .array(items)
        raw.remove("graphic_style")
      }
    }
    return ids
  }
}
