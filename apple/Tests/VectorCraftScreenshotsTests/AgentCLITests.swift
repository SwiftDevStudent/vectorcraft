import CoreGraphics
import Foundation
import Testing
import VectorCraftCore
@testable import VectorCraftScreenshots

struct AgentCLITests {
  private let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=") ?? Data()
  private func fixture() throws -> (URL, Drawing) {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("VectorCraft-agent-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
    var drawing = Drawing()
    try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: "iphone-medium")))
    let board = try #require(drawing.screenshotRows.first?.boards.first)
    try drawing.perform(.screenshot(ScreenshotCommand(.replaceScreenshot, board: board.id, data: png)))
    drawing.envelope["document"]["unknown"]["agentProof"] = .string("retained")
    let file = folder.appendingPathComponent("Agent Document.vectorcraft")
    try NativeFormat.encode(drawing).write(to: file)
    return (file, drawing)
  }
  private func run(_ args: [String], stdin: Data = Data()) async throws -> JSONValue {
    let output = FileManager.default.temporaryDirectory.appendingPathComponent("VectorCraft-agent-output-" + UUID().uuidString + ".json")
    try Data().write(to: output, options: .withoutOverwriting)
    let handle = try FileHandle(forWritingTo: output), pipe = Pipe()
    defer { try? handle.close(); try? pipe.fileHandleForReading.close() }
    try pipe.fileHandleForWriting.write(contentsOf: stdin)
    try pipe.fileHandleForWriting.close()
    try await ScreenshotCLI.run(args, input: pipe.fileHandleForReading, output: handle)
    return try JSONDecoder().decode(JSONValue.self, from: Data(contentsOf: output))
  }

  @Test func summaryReportsEditableSceneAndSlotsWithoutOpaquePayloads() async throws {
    let (file, drawing) = try fixture(), before = try Data(contentsOf: file)
    let summary = try await run(["summary", file.path])
    #expect(summary["schemaVersion"].int == 1)
    #expect(summary["artboards"].array.count == 1)
    #expect(summary["screenshotRows"].array.first?["slots"].array.count == 10)
    #expect(summary["includedScreenshots"].int == 1)
    let text = try #require(summary["nodes"].array.first { $0["type"].string == "text" })
    #expect(text["inlineEditable"].boolean == true)
    #expect(!text["runs"].array.first!["resolvedPostScriptName"].string.isEmpty)
    #expect(summary["renderingWarnings"].array.isEmpty)
    let serialized = String(decoding: try JSONEncoder().encode(summary), as: UTF8.self)
    #expect(!serialized.contains(png.base64EncodedString()))
    #expect(!serialized.contains("\"bookmark\""))
    #expect(try Data(contentsOf: file) == before)
    #expect(drawing.envelope["document"]["unknown"]["agentProof"].string == "retained")
  }

  @Test func stdinDryRunPreviewsNativeTextEditsWithoutWriting() async throws {
    let (file, drawing) = try fixture(), before = try Data(contentsOf: file)
    let board = try #require(drawing.screenshotRows.first?.boards.first)
    let text = try #require(drawing.node(board.content)?.children.first { $0.type == "text" })
    let commands = Data("[{\"action\":\"editText\",\"id\":\(text.id),\"text\":\"Agent headline\"}]".utf8)
    let result = try await run(["edit", file.path, "-", "--dry-run", "--summary"], stdin: commands)
    #expect(result["dryRun"].boolean == true)
    #expect(result["summary"]["nodes"].array.contains { $0["id"].int == text.id && $0["text"].string == "Agent headline" })
    #expect(try Data(contentsOf: file) == before)
    let saved = try await run(["edit", file.path, "-", "--summary"], stdin: commands)
    #expect(saved["nodes"].array.contains { $0["id"].int == text.id && $0["text"].string == "Agent headline" })
    let reopened = try NativeFormat.decode(Data(contentsOf: file))
    #expect(reopened.envelope["document"]["unknown"]["agentProof"].string == "retained")
    #expect(reopened.envelope["images"] == drawing.envelope["images"])
  }

  @Test func failedBatchDoesNotPersistAnEarlierSuccessfulCommand() async throws {
    let (file, drawing) = try fixture(), before = try Data(contentsOf: file)
    let board = try #require(drawing.screenshotRows.first?.boards.first)
    let text = try #require(drawing.node(board.content)?.children.first { $0.type == "text" })
    let commands = Data("[{\"action\":\"editText\",\"id\":\(text.id),\"text\":\"Must not persist\"},{\"action\":\"unsupported\"}]".utf8)
    await #expect(throws: DrawingError.self) {
      _ = try await run(["edit", file.path, "-", "--summary"], stdin: commands)
    }
    #expect(try Data(contentsOf: file) == before)
  }

  @Test func bulkExportUsesPopulatedSlotsAndLeavesNativeInputUntouched() async throws {
    let (file, _) = try fixture(), before = try Data(contentsOf: file)
    let result = try await run(["export-used", file.path, file.deletingLastPathComponent().path, "png"])
    #expect(result["files"].array.count == 1)
    let exported = try #require(result["files"].array.first?.string)
    #expect(URL(fileURLWithPath: exported).lastPathComponent == "Row-01-Screenshot-01.png")
    #expect(try Data(contentsOf: URL(fileURLWithPath: exported)).starts(with: [137, 80, 78, 71]))
    #expect(try Data(contentsOf: file) == before)
  }
}
