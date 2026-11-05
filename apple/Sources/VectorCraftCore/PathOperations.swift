import CoreGraphics
import Foundation

extension Drawing {
  public func canUsePathfinder(_ ids: Set<Int64>) -> Bool {
    (try? pathSelection(ids, minimum: 2)) != nil
  }
  public func canMakeCompound(_ ids: Set<Int64>) -> Bool {
    (try? pathSelection(ids, minimum: 1)) != nil
  }
  public func canReleaseCompound(_ ids: Set<Int64>) -> Bool {
    guard ids.count == 1, let id = ids.first, canEdit(id), let node = node(id) else { return false }
    return node.type == "compound" || (node.type == "path" && node.subpaths.count > 1)
  }

  func pathSelection(_ ids: Set<Int64>, minimum: Int) throws -> [VectorNode] {
    guard ids.count >= minimum, ids.count <= 1_000, ids.allSatisfy(canEdit) else {
      throw DrawingError.invalid("Select visible, unlocked paths in the same layer or group.")
    }
    func find(_ nodes: [VectorNode]) -> [VectorNode]? {
      if ids.isSubset(of: Set(nodes.map(\.id))) { return nodes.filter { ids.contains($0.id) } }
      for node in nodes { if let found = find(node.children) { return found } }
      return nil
    }
    guard let selected = find(layers),
      selected.allSatisfy({ ["path", "compound"].contains($0.type) && !$0.subpaths.isEmpty }),
      selected.reduce(0, { $0 + $1.subpaths.reduce(0, { $0 + $1.anchors.count }) }) <= 100_000
    else { throw DrawingError.invalid("Select supported paths in the same layer or group.") }
    return selected
  }

  mutating func performPathfinder(_ ids: Set<Int64>, _ operation: PathfinderOperation) throws
    -> Set<Int64>
  {
    let nodes = try pathSelection(ids, minimum: 2)
    let shapes = nodes.map {
      $0.cgPath.normalized(using: $0.raw["kind"]["rule"].string == "EvenOdd" ? .evenOdd : .winding)
    }
    guard let back = nodes.first, let front = nodes.last, let first = shapes.first,
      let last = shapes.last
    else {
      throw DrawingError.invalid("Select paths for Pathfinder.")
    }
    var pieces: [(CGPath, VectorNode)] = []
    var grouped = false
    switch operation {
    case .unite, .intersect, .exclude, .minusFront, .minusBack:
      var result = operation == .minusBack ? last : first
      let operands = operation == .minusBack ? Array(shapes.dropLast()) : Array(shapes.dropFirst())
      for shape in operands {
        switch operation {
        case .unite: result = result.union(shape)
        case .intersect: result = result.intersection(shape)
        case .exclude: result = result.symmetricDifference(shape)
        default: result = result.subtracting(shape)
        }
      }
      pieces = [(result, operation == .minusFront ? back : front)]
    case .divide:
      grouped = true
      for (shape, node) in zip(shapes, nodes) {
        var next: [(CGPath, VectorNode)] = []
        var remaining = shape
        for (piece, owner) in pieces {
          next.append((piece.subtracting(shape), owner))
          next.append((piece.intersection(shape), node))
          remaining = remaining.subtracting(piece)
        }
        next.append((remaining, node))
        pieces = next.filter { !$0.0.isEmpty }
        guard pieces.count <= 10_000 else {
          throw DrawingError.invalid("Divide produced too many regions.")
        }
      }
    case .trim, .merge, .crop:
      grouped = true
      let mask = operation == .crop ? last : nil
      let count = operation == .crop ? nodes.count - 1 : nodes.count
      for index in 0..<count {
        let node = nodes[index]
        var result = shapes[index]
        if let mask {
          result = shapes[index].intersection(mask)
          for shape in shapes.dropFirst(index + 1).dropLast() { result = result.subtracting(shape) }
        } else {
          for shape in shapes.dropFirst(index + 1) { result = result.subtracting(shape) }
        }
        if !result.isEmpty { pieces.append((result, node)) }
      }
      if operation == .merge {
        var merged: [(CGPath, VectorNode)] = []
        for (path, node) in pieces {
          if let index = merged.firstIndex(where: { sameFill($0.1, node) }) {
            merged[index].0 = merged[index].0.union(path)
          } else {
            merged.append((path, node))
          }
        }
        pieces = merged
      }
    }
    // Empty intersections are errors, so a mistaken click cannot erase the selection.
    var outputs: [JSONValue] = []
    var total = 0
    for (path, owner) in pieces {
      let components = grouped ? path.componentsSeparated() : [path]
      for component in components where !component.isEmpty {
        let paths = try PathGeometry.subpaths(component)
        guard !paths.isEmpty else { continue }
        total += paths.reduce(0) { $0 + $1.anchors.count }
        guard total <= 100_000, outputs.count < 10_000 else {
          throw DrawingError.invalid("The resulting artwork exceeds the supported geometry limits.")
        }
        var raw = owner.raw
        raw["id"] = .integer(try allocateID())
        raw["name"] = .string(operation.rawValue)
        var kind = raw["kind"]
        kind["type"] = .string("path")
        kind["path"] = .object(["subpaths": .array(paths.map { $0.json(version: version) })])
        kind["rule"] = .string("NonZero")
        kind.remove("children")
        kind.remove("live")
        raw["kind"] = kind
        if [.trim, .merge, .crop].contains(operation) {
          raw["appearance"]["items"] = .array(
            raw["appearance"]["items"].array.filter { $0["kind"].string != "stroke" })
        }
        outputs.append(raw)
      }
    }
    guard !outputs.isEmpty else { throw DrawingError.invalid("The paths have no resulting area.") }
    if grouped {
      let id = try allocateID()
      outputs = [
        .object([
          "id": .integer(id), "name": .string(operation.rawValue),
          "kind": .object([
            "type": .string("group"), "clip": .bool(false), "children": .array(outputs),
          ]),
        ])
      ]
    }
    replacePathSelection(ids, with: outputs)
    return Set(outputs.compactMap { $0["id"].int })
  }

  private func sameFill(_ a: VectorNode, _ b: VectorNode) -> Bool {
    let left = a.raw["appearance"]["items"].array.filter { $0["kind"].string != "stroke" }
    let right = b.raw["appearance"]["items"].array.filter { $0["kind"].string != "stroke" }
    return left == right && a.opacity == b.opacity && a.raw["blend"] == b.raw["blend"]
      && a.raw["appearance"]["effects"] == b.raw["appearance"]["effects"]
  }

  mutating func replacePathSelection(_ ids: Set<Int64>, with outputs: [JSONValue]) {
    rewriteSiblings { values in
      guard ids.isSubset(of: Set(values.compactMap { $0["id"].int })),
        let last = values.lastIndex(where: { ids.contains($0["id"].int ?? 0) })
      else { return }
      let position = values.prefix(last).filter { !ids.contains($0["id"].int ?? 0) }.count
      values.removeAll { ids.contains($0["id"].int ?? 0) }
      values.insert(contentsOf: outputs, at: min(position, values.count))
    }
  }
}
