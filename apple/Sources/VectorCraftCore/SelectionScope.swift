import CoreGraphics

extension Drawing {
  public func ancestry(of id: Int64) -> [VectorNode]? {
    func find(_ nodes: [VectorNode]) -> [VectorNode]? {
      for node in nodes {
        if node.id == id { return [node] }
        if let children = find(node.children) { return [node] + children }
      }
      return nil
    }
    return find(layers)
  }

  public func isInside(_ id: Int64, isolation: Int64?) -> Bool {
    guard let path = ancestry(of: id) else { return false }
    guard let isolation else { return true }
    return id != isolation && path.contains { $0.id == isolation }
  }

  public func canIsolate(_ id: Int64, within isolation: Int64? = nil) -> Bool {
    guard let path = ancestry(of: id), let node = path.last,
      ["group", "layer"].contains(node.type),
      path.allSatisfy({ $0.visible && !$0.locked })
    else { return false }
    return isInside(id, isolation: isolation)
  }

  public func selectionRoots(within isolation: Int64? = nil) -> [VectorNode] {
    guard let isolation else { return layers }
    guard canIsolate(isolation), let root = node(isolation) else { return [] }
    return root.children
  }

  public func selectableIDs(
    within isolation: Int64? = nil, intersecting rect: CGRect? = nil
  ) -> Set<Int64> {
    func touches(_ node: VectorNode) -> Bool {
      guard node.visible, !node.locked else { return false }
      if ["layer", "group"].contains(node.type) { return node.children.contains(where: touches) }
      return node.editable && (rect.map { $0.intersects(node.bounds) } ?? true)
    }
    func collect(_ nodes: [VectorNode]) -> [Int64] {
      nodes.flatMap { node -> [Int64] in
        guard node.visible, !node.locked else { return [] }
        if node.type == "layer" { return collect(node.children) }
        return node.editable && touches(node) ? [node.id] : []
      }
    }
    return Set(collect(selectionRoots(within: isolation)))
  }

  func permits(_ command: DrawingCommand, within isolation: Int64) -> Bool {
    guard canIsolate(isolation) else { return false }
    let targets: Set<Int64>
    switch command {
    case .paste(_, _, let container, let selection):
      return (container == isolation || isInside(container, isolation: isolation))
        && selection.allSatisfy { isInside($0, isolation: isolation) }
    case .addPath(_, _, let container), .addText(_, _, _, _, _, let container),
      .addAreaText(_, _, _, _, _, let container):
      return container == isolation || isInside(container, isolation: isolation)
    case .addLayer, .resizeArtboard, .screenshot: return false
    case .transform(let ids, _, _), .transformEach(let ids, _, _), .style(let ids, _),
      .gradient(let ids, _, _),
      .delete(let ids), .cut(let ids), .duplicate(let ids),
      .group(let ids), .arrange(let ids, _), .align(let ids, _, _), .pathfinder(let ids, _),
      .makeCompound(let ids), .releaseCompound(let ids), .fillRule(let ids, _):
      targets = ids
    case .editText(let id, _, _, _), .resizeTextFrame(let id, _), .replacePath(let id, _),
      .deleteAnchor(let id, _, _), .ungroup(let id), .rename(let id, _),
      .visibility(let id, _), .lock(let id, _):
      targets = [id]
    }
    return !targets.isEmpty && targets.allSatisfy { isInside($0, isolation: isolation) }
  }
}
