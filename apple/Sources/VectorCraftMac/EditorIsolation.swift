import VectorCraftCore

extension EditorState {
  var isolationID: Int64? { isolationStack.last }
  var insertionContainer: Int64 { isolationID ?? activeLayer }

  func insertionContainer(in drawing: Drawing) -> Int64 {
    let container: Int64 = insertionContainer
    guard isolationID == nil else { return container }
    return drawing.screenshotInsertionContainer(for: container)
  }

  @discardableResult
  func enterIsolation(_ id: Int64, in drawing: Drawing) -> Bool {
    guard tool != .pen, textEditingSession == nil,
      drawing.canIsolate(id, within: isolationID)
    else { return false }
    isolationStack.append(id)
    selection = []
    nodeSelection = nil
    canvasAction = .cancelPath
    tool = .select
    return true
  }

  func exitIsolation(in drawing: Drawing, retaining depth: Int? = nil) {
    guard !isolationStack.isEmpty else { return }
    let depth = min(max(0, depth ?? isolationStack.count - 1), isolationStack.count - 1)
    let exited = isolationStack[depth]
    isolationStack = Array(isolationStack.prefix(depth))
    selection = drawing.isInside(exited, isolation: isolationID) ? [exited] : []
    nodeSelection = nil
    canvasAction = .cancelPath
    tool = .select
  }

  func reconcileIsolation(in drawing: Drawing) {
    var valid: [Int64] = []
    for id in isolationStack {
      guard drawing.canIsolate(id, within: valid.last) else { break }
      valid.append(id)
    }
    if valid != isolationStack {
      isolationStack = valid
      canvasAction = .cancelPath
      nodeSelection = nil
    }
    selection = selection.filter { drawing.isInside($0, isolation: isolationID) }
  }

  func canEnterIsolation(in drawing: Drawing) -> Bool {
    guard selection.count == 1, let id = selection.first,
      tool != .pen, textEditingSession == nil
    else { return false }
    return drawing.canIsolate(id, within: isolationID)
  }
}
