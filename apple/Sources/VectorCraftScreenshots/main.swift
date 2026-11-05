import Foundation
import CoreGraphics
import VectorCraftCore

@main
struct ScreenshotCLI {
  static func main() async {
    do { try await run(Array(CommandLine.arguments.dropFirst())) }
    catch {
      // A closed stderr cannot receive an error; document writes already report failure via exit status.
      try? FileHandle.standardError.write(contentsOf: Data((error.localizedDescription + "\n").utf8))
      exit(1)
    }
  }

  static func run(_ arguments: [String], input: FileHandle = .standardInput,
    output: FileHandle = .standardOutput) async throws {
    var args = arguments, dryRun = false, compact = false
    while let flag = args.last, ["--dry-run", "--summary"].contains(flag) {
      if flag == "--dry-run" { dryRun = true } else { compact = true }
      args.removeLast()
    }
    guard let action = args.first, action != "help", args.count >= 2 else {
      try output.write(contentsOf: Data((usage + "\n").utf8)); return
    }
    guard !dryRun || ["apply", "edit"].contains(action) else {
      throw DrawingError.invalid("--dry-run is available for apply and edit.")
    }
    let url = URL(fileURLWithPath: args[1])
    var drawing: Drawing
    if action == "new" {
      guard !FileManager.default.fileExists(atPath: url.path) else { throw DrawingError.invalid("Document already exists.") }
      drawing = Drawing()
      try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: args.count > 2 ? args[2] : "iphone-medium")))
    } else { drawing = try NativeFormat.decode(Data(contentsOf: url)) }
    switch action {
    case "new": break
    case "inspect": try writeJSON(drawing.envelope, to: output); return
    case "summary":
      guard args.count == 2 else { throw DrawingError.invalid("Use summary FILE." ) }
      try writeJSON(ScreenshotSceneSummary.make(drawing), to: output); return
    case "extract-image":
      guard args.count == 4, let id = Int64(args[2]), let node = drawing.node(id), node.type == "image",
        let data = VectorImage.data(node, images: drawing.envelope["images"], blobs: drawing.nativeBlobData) else {
        throw DrawingError.invalid("Specify an available native image ID and output path.")
      }
      let destination = URL(fileURLWithPath: args[3])
      try data.write(to: destination, options: .atomic)
      try output.write(contentsOf: Data((destination.path + "\n").utf8)); return
    case "apply":
      guard args.count == 3 else { throw DrawingError.invalid("Specify commands JSON or - for stdin.") }
      let commands = try JSONDecoder().decode([ScreenshotCommand].self, from: commandData(args[2], input: input))
      for command in commands { try drawing.perform(.screenshot(command)) }
    case "edit":
      guard args.count == 3 else { throw DrawingError.invalid("Specify native edits JSON or - for stdin.") }
      let edits = try JSONDecoder().decode([NativeEditCommand].self, from: commandData(args[2], input: input))
      for edit in edits { try edit.apply(to: &drawing) }
    case "import":
      guard args.count == 4, let board = Int64(args[2]) else { throw DrawingError.invalid("Specify native board ID and PNG/JPEG path.") }
      try drawing.perform(.screenshot(ScreenshotCommand(.replaceScreenshot, board: board, data: Data(contentsOf: URL(fileURLWithPath: args[3])))))
    case "frame":
      guard args.count == 5, let board = Int64(args[2]) else { throw DrawingError.invalid("Specify native board ID, original PNG and measured inventory JSON.") }
      let frame = try ScreenshotFrameInventory.reference(png: URL(fileURLWithPath: args[3]), inventory: URL(fileURLWithPath: args[4]))
      try drawing.perform(.screenshot(ScreenshotCommand(.setFrame, board: board, frame: frame)))
    case "export":
      guard args.count == 4, let id = Int64(args[2]), let board = drawing.screenshotBoard(id) else { throw DrawingError.invalid("Specify native board ID and export path.") }
      let artwork = try drawing.screenshotExportDrawing(board)
      let destination = URL(fileURLWithPath: args[3]), data: Data
      switch destination.pathExtension.lowercased() {
      case "png": data = try VectorRenderer.png(artwork)
      case "svg": data = try SVGExport.encode(artwork)
      case "pdf": data = try PDFExport.encode(artwork)
      default: throw DrawingError.invalid("Choose PNG, SVG, or PDF.")
      }
      try data.write(to: destination, options: .atomic)
      try output.write(contentsOf: Data((destination.path + "\n").utf8)); return
    case "export-used":
      guard args.count == 4, let format = ScreenshotExportFormat(rawValue: args[3].lowercased()) else {
        throw DrawingError.invalid("Use export-used FILE DIRECTORY png|svg|pdf.")
      }
      let destination = try await ScreenshotExport.write(drawing, format: format, to: URL(fileURLWithPath: args[2]))
      let files = try FileManager.default.contentsOfDirectory(at: destination, includingPropertiesForKeys: nil)
        .filter { $0.pathExtension == format.rawValue }.map(\.path).sorted()
      try writeJSON(.object(["schemaVersion": .integer(1), "directory": .string(destination.path),
        "format": .string(format.rawValue), "files": .array(files.map(JSONValue.string))]), to: output)
      return
    default: throw DrawingError.invalid("Unknown action. Use help for available commands.")
    }
    if dryRun {
      try writeJSON(.object(["dryRun": .bool(true), "summary": ScreenshotSceneSummary.make(drawing)]), to: output)
      return
    }
    try NativeFormat.encode(drawing).write(to: url, options: .atomic)
    try writeJSON(compact ? ScreenshotSceneSummary.make(drawing) : drawing.envelope, to: output)
  }

  private static func commandData(_ path: String, input: FileHandle) throws -> Data {
    guard path == "-" else { return try Data(contentsOf: URL(fileURLWithPath: path)) }
    let limit = 4 * 1024 * 1024
    var bytes = Data()
    while let chunk = try input.read(upToCount: min(65536, limit + 1 - bytes.count)), !chunk.isEmpty {
      bytes.append(chunk)
      guard bytes.count <= limit else {
        throw DrawingError.invalid("Stdin commands exceed 4 MB. Use a JSON file for larger batches.")
      }
    }
    return bytes
  }
  private static func writeJSON(_ value: JSONValue, to output: FileHandle) throws {
    let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    var data = try encoder.encode(value); data.append(10)
    try output.write(contentsOf: data)
  }
  private static let usage = """
    VectorCraftScreenshots new FILE [PRESET] [--summary]
      summary FILE | inspect FILE
      apply FILE COMMANDS.json|- [--dry-run] [--summary]
      edit FILE NATIVE_EDITS.json|- [--dry-run] [--summary]
      import FILE BOARD_ID PNG/JPEG [--summary]
      frame FILE BOARD_ID PNG INVENTORY.json [--summary]
      extract-image FILE NODE_ID OUTPUT
      export FILE BOARD_ID OUTPUT.png/svg/pdf
      export-used FILE DIRECTORY png|svg|pdf
    """
}

private struct NativeEditCommand: Decodable {
  var action: String
  var board: Int64?
  var layer: Int64?
  var id: Int64?
  var ids: [Int64]?
  var text: String?
  var font: String?
  var size: Double?
  var x: Double?
  var y: Double?
  var matrix: [Double]?
  var color: [Double]?
  var copy: Bool?

  func apply(to drawing: inout Drawing) throws {
    func paint() throws -> JSONValue {
      let components = color ?? [1, 1, 1]
      guard components.count == 3, components.allSatisfy({ $0.isFinite && (0...1).contains($0) }) else {
        throw DrawingError.invalid("Color must contain three RGB components between 0 and 1.")
      }
      return VectorStyle.solid(components[0], components[1], components[2])
    }
    switch action {
    case "addText":
      let container: Int64
      if let board {
        guard let owner = drawing.screenshotBoard(board) else { throw DrawingError.invalid("Unknown screenshot board.") }
        container = owner.content
      } else if let layer {
        container = drawing.screenshotInsertionContainer(for: layer)
      } else { throw DrawingError.invalid("Specify a screenshot board or native insertion layer.") }
      guard let text, let x, let y else { throw DrawingError.invalid("Specify text and document-space x/y.") }
      try drawing.perform(.addText(text, CGPoint(x: x, y: y), font: font ?? "Helvetica",
        size: size ?? 64, fill: paint(), layer: container))
    case "editText":
      guard let id, let text, let node = drawing.node(id), node.type == "text" else {
        throw DrawingError.invalid("Specify an existing native text ID and replacement text.")
      }
      let style = node.raw["kind"]["runs"].array.first?["style"] ?? .null
      try drawing.perform(.editText(id, text, font: font ?? style["font_family"].string,
        size: size ?? style["size"].double ?? 64))
    case "transform":
      guard let ids, !ids.isEmpty, let matrix, matrix.count == 6, matrix.allSatisfy(\.isFinite) else {
        throw DrawingError.invalid("Specify native IDs and a six-number affine matrix.")
      }
      try drawing.perform(.transform(Set(ids), CGAffineTransform(a: matrix[0], b: matrix[1],
        c: matrix[2], d: matrix[3], tx: matrix[4], ty: matrix[5]), copy: copy ?? false))
    case "fill":
      guard let ids, !ids.isEmpty, color != nil else { throw DrawingError.invalid("Specify native IDs and RGB color.") }
      let fill = try paint()
      for id in ids {
        guard let node = drawing.node(id) else { throw DrawingError.invalid("Native object is missing.") }
        var style = VectorStyle(node: node)
        style.fill = fill
        try drawing.perform(.style([id], style))
      }
    default: throw DrawingError.invalid("Native edit action must be addText, editText, transform, or fill.")
    }
  }
}
