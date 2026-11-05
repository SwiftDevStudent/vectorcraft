import Foundation
import Testing
import VectorCraftCore

@testable import VectorCraftMac

struct SVGFileImportTests {
  @Test func coordinatedImportLeavesSourceUnchangedAndProducesNativeSavableArtwork() async throws {
    let folder = FileManager.default.temporaryDirectory.appending(path: "vectorcraft-svg-\(UUID())")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let source = folder.appending(path: "original.svg")
    let xml = Data(
      "<svg width='100pt' height='60pt' viewBox='0 0 100 60'><rect id='Original' x='10' y='15' width='40' height='20' fill='red'/></svg>"
        .utf8)
    try xml.write(to: source)
    let drawing = try await SVGFileReader.read(source)
    #expect(try Data(contentsOf: source) == xml)
    #expect(drawing.title == "original")
    let destination = folder.appending(path: "converted.vectorcraft")
    try NativeFormat.encode(drawing).write(to: destination)
    let reopened = try NativeFormat.decode(Data(contentsOf: destination))
    #expect(reopened.layers == drawing.layers && reopened.artboard == drawing.artboard)
    #expect(reopened.layers[0].children[0].name == "Original")
    #expect(try Data(contentsOf: source) == xml)
  }

  @Test func failedImportDoesNotWriteToItsSource() async throws {
    let source = FileManager.default.temporaryDirectory.appending(
      path: "vectorcraft-svg-rejected-\(UUID()).svg")
    let xml = Data(
      "<svg><rect width='100' height='100'/><image href='file:///not-loaded'/></svg>".utf8)
    try xml.write(to: source)
    await #expect(throws: DrawingError.self) { try await SVGFileReader.read(source) }
    #expect(try Data(contentsOf: source) == xml)
  }
}
