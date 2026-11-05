import CoreGraphics
import Foundation

public struct VectorFragment: Equatable, Sendable {
  public private(set) var drawing: Drawing
  public var nodes: [VectorNode] { drawing.layers.first?.children ?? [] }
  public var sourceArtboard: CGRect {
    drawing.envelope["swift_clipboard"]["artboard"].rect ?? drawing.artboard
  }
  public var bounds: CGRect { nodes.reduce(CGRect.null) { $0.union($1.bounds) } }

  public init(
    copying selection: Set<Int64>, from source: Drawing, artboard: Int = 0,
    within isolation: Int64? = nil
  ) throws {
    guard !selection.isEmpty, source.artboards.indices.contains(artboard),
      selection.allSatisfy({
        source.isInside($0, isolation: isolation) && source.node($0)?.type != "layer"
      })
    else { throw DrawingError.invalid("Select artwork to copy.") }
    var selected = selection
    // Compound children share their parent's appearance, so carry that whole compound.
    for id in selection {
      for ancestor in source.ancestry(of: id) ?? [] where ancestor.type == "compound" {
        guard source.isInside(ancestor.id, isolation: isolation) else { continue }
        selected.insert(ancestor.id)
      }
    }
    func roots(_ nodes: [VectorNode]) -> [VectorNode] {
      nodes.flatMap { selected.contains($0.id) ? [$0] : roots($0.children) }
    }
    let copied = roots(source.layers)
    var copiedIDs = Set<Int64>()
    var pending = Set<ClipboardResource>()
    for node in copied {
      var raw = node.raw
      try ClipboardResource.editNode(
        &raw,
        reference: {
          pending.insert($0)
          return $0
        },
        nodeID: {
          copiedIDs.insert($0)
          return $0
        })
    }
    if source.envelope["document"]["text_threads"].array.contains(where: {
      !$0.array.compactMap(\.int).filter(copiedIDs.contains).isEmpty
    }) {
      throw DrawingError.invalid(
        "Copying threaded text is not supported yet. Native saving preserves it.")
    }
    var fragment = Drawing()
    var resourceBudget = NativeFormat.maximumBytes
    if source.envelope["profiles"] != .null {
      fragment.envelope["profiles"] =
        source.version == 4
        ? try NativeBlob.materializedMap(
          source.envelope["profiles"], blobs: source.nativeBlobData, remaining: &resourceBudget)
        : source.envelope["profiles"]
    }
    fragment.envelope["version"] = .integer(source.version)
    fragment.envelope["swift_clipboard"] = .object([
      "version": .integer(1), "artboard": source.artboards[artboard].clipboardJSON,
    ])
    for key in ["color_mode", "color_profiles"] where source.envelope["document"][key] != .null {
      fragment.envelope["document"][key] = source.envelope["document"][key]
    }
    if source.envelope["document"]["unknown"]["colorProfiles"] != .null {
      fragment.envelope["document"]["unknown"]["colorProfiles"] =
        source.envelope["document"]["unknown"]["colorProfiles"]
    }
    var seen = Set<ClipboardResource>()
    while let ref = pending.sorted().first {
      pending.remove(ref)
      guard seen.insert(ref).inserted else { continue }
      if source.version == 4, ref.kind == "images" {
        try NativeBlob.reserve(
          source.envelope["images"][ref.name], blobs: source.nativeBlobData,
          remaining: &resourceBudget)
      }
      guard seen.count <= 100_000, var definition = ref.definition(in: source) else {
        throw DrawingError.invalid(
          "The copied artwork references a missing \(ref.kind) definition: \(ref.name).")
      }
      let original = definition
      try ref.editDefinition(
        &definition,
        reference: {
          if !seen.contains($0) { pending.insert($0) }
          return $0
        },
        nodeID: {
          copiedIDs.insert($0)
          return $0
        })
      ref.store(original, in: &fragment)
    }
    guard let maximum = copiedIDs.max(), maximum < Int64.max - 100_002 else {
      throw DrawingError.invalid("Clipboard artwork has invalid object IDs.")
    }
    var layer = fragment.layers[0].raw
    layer["id"] = .integer(maximum + 1)
    layer["kind"]["children"] = .array(copied.map(\.raw))
    fragment.envelope["document"]["layers"] = .array([layer])
    fragment.envelope["document"]["next_id"] = .integer(maximum + 2)
    try fragment.validate()
    drawing = fragment
  }

  public init(data: Data) throws {
    let decoded = try NativeFormat.decode(data)
    guard decoded.envelope["swift_clipboard"]["version"].int == 1,
      decoded.envelope["swift_clipboard"]["artboard"].rect != nil,
      decoded.layers.count == 1, !decoded.layers[0].children.isEmpty
    else {
      throw DrawingError.invalid("This clipboard does not contain a supported artwork fragment.")
    }
    // Rebuild from the bounded document to validate reference closure and discard unselected data.
    var checked = try Self(copying: Set(decoded.layers[0].children.map(\.id)), from: decoded)
    checked.drawing.envelope["swift_clipboard"]["artboard"] =
      decoded.envelope["swift_clipboard"]["artboard"]
    drawing = checked.drawing
  }
  public func encoded() throws -> Data { try NativeFormat.encode(drawing) }

  /// Export only the copied art, cropped with enough margin for supported strokes and joins.
  public func exportDrawing() throws -> Drawing {
    guard drawing.renderingWarnings.isEmpty, !bounds.isNull else {
      throw DrawingError.invalid(
        "This clipboard contains artwork the Swift renderer cannot export yet.")
    }
    func margin(_ node: VectorNode) -> CGFloat {
      let own =
        node.raw["appearance"]["items"].array.filter { $0["kind"].string == "stroke" }.map {
          min(10000, max(0, $0["width"].double ?? 1))
            * max(1, min(10000, $0["miter_limit"].double ?? 10)) / 2
        }.max() ?? 0
      let text =
        node.raw["kind"]["runs"].array.map { $0["style"]["stroke_width"].double ?? 0 }.max() ?? 0
      return max(own, text, node.children.map(margin).max() ?? 0)
    }
    let padding = max(1, nodes.map(margin).max() ?? 0)
    let rect = bounds.insetBy(dx: -padding, dy: -padding)
    var result = drawing
    var boards = result.envelope["document"]["artboards"].array
    boards[0]["rect"] = rect.clipboardJSON
    result.envelope["document"]["artboards"] = .array(boards)
    return result
  }
}

extension CGRect {
  var clipboardJSON: JSONValue {
    .object(["x0": .number(minX), "y0": .number(minY), "x1": .number(maxX), "y1": .number(maxY)])
  }
}
