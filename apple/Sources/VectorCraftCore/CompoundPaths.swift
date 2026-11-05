import CoreGraphics
import Foundation

extension Drawing {
  mutating func makeCompound(_ ids: Set<Int64>) throws -> Set<Int64> {
    let nodes = try pathSelection(ids, minimum: 1)
    guard let back = nodes.first else { throw DrawingError.invalid("Select paths to combine.") }
    var compound = back.raw
    let id = try allocateID()
    compound["id"] = .integer(id)
    compound["name"] = .string("Compound Path")
    compound["kind"] = .object([
      "type": .string("compound"), "rule": .string("NonZero"), "children": .array(nodes.map(\.raw)),
    ])
    replacePathSelection(ids, with: [compound])
    return [id]
  }

  mutating func releaseCompound(_ ids: Set<Int64>) throws -> Set<Int64> {
    guard canReleaseCompound(ids), let id = ids.first, let compound = node(id) else {
      throw DrawingError.invalid("Select one compound path to release.")
    }
    var outputs: [JSONValue] = []
    func leaves(_ node: VectorNode) -> [VectorNode] {
      node.type == "compound" ? node.children.flatMap(leaves) : [node]
    }
    for child in leaves(compound) {
      for path in child.subpaths {
        var raw = child.raw
        raw["id"] = .integer(try allocateID())
        raw["name"] = .string("Path")
        for key in ["appearance", "opacity", "blend", "graphic_style"] {
          if compound.raw[key] == .null { raw.remove(key) } else { raw[key] = compound.raw[key] }
        }
        raw["kind"]["type"] = .string("path")
        raw["kind"]["path"]["subpaths"] = .array([path.json(version: version)])
        raw["kind"]["rule"] = .string("NonZero")
        outputs.append(raw)
      }
    }
    replacePathSelection(ids, with: outputs)
    return Set(outputs.compactMap { $0["id"].int })
  }

  func compoundPathComponent(_ id: Int64, subpath index: Int) -> (Int64, Int)? {
    guard let node = node(id), index >= 0 else { return nil }
    if node.type == "path" { return node.subpaths.indices.contains(index) ? (id, index) : nil }
    var offset = index
    for child in node.children {
      let count = child.subpaths.count
      if offset < count { return (child.id, offset) }
      offset -= count
    }
    return nil
  }

  static func replaceGeometry(
    _ value: inout JSONValue, paths: ArraySlice<VectorSubpath>, version: Int64
  ) {
    if value["kind"]["type"].string == "compound" {
      var children = value["kind"]["children"].array
      var remaining = paths
      for index in children.indices {
        let count = VectorNode(raw: children[index]).subpaths.count
        replaceGeometry(&children[index], paths: remaining.prefix(count), version: version)
        remaining = remaining.dropFirst(count)
      }
      value["kind"]["children"] = .array(children)
    } else {
      value["kind"]["path"]["subpaths"] = .array(paths.map { $0.json(version: version) })
      var kind = value["kind"]
      kind.remove("live")
      value["kind"] = kind
    }
  }
}
