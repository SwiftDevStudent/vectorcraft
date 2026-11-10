import CZlib
import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import VectorCraftCore

struct NativeV4Tests {
  private let marker = Data([10, 0, 86, 67, 66, 76, 79, 66, 83, 0])

  @Test func savedV4RetainsTheGeneratorUsedForRustMigrations() throws {
    var envelope = Drawing().envelope
    envelope["version"] = .integer(4)
    envelope["document"]["version"] = .integer(1)
    envelope["generator"] = .string("VectorCraft 0.21.0")

    let source = try NativeFormat.decode(JSONEncoder().encode(envelope))
    let reopened = try NativeFormat.decode(NativeFormat.encode(source))
    #expect(reopened.envelope["generator"] == envelope["generator"])
    #expect(reopened.envelope["document"]["version"] == .integer(1))
  }

  @Test func binaryResourcesAndUnknownFieldsSurviveNativeSaving() throws {
    let payload = Data((0..<12_000).map { UInt8(truncatingIfNeeded: $0) })
    var envelope = Drawing().envelope
    envelope["version"] = .integer(4)
    envelope["images"]["binary"] = .object([
      "mime": .string("application/octet-stream"),
      "blob": .array([.integer(0), .integer(Int64(payload.count))]),
      "proxy": .bool(true), "foreignResource": .string("retained"),
    ])
    envelope["document"]["unknown"]["sentinel"] = .string("quotes \" and braces } [ remain data")
    var wire = try JSONEncoder().encode(envelope)
    wire.append(marker)
    wire.append(payload)

    let drawing = try NativeFormat.decode(wire)
    #expect(drawing.version == 4)
    #expect(drawing.envelope["images"]["binary"] == envelope["images"]["binary"])
    let saved = try NativeFormat.encode(drawing)
    #expect(saved.suffix(payload.count) == payload)
    let reopened = try NativeFormat.decode(saved)
    #expect(reopened.envelope["document"] == envelope["document"])
    #expect(reopened.envelope["images"] == envelope["images"])
  }

  @Test func largeInlineResourcesAreWrittenIntoTheV4BinarySection() throws {
    let payload = Data((0..<12_000).map { UInt8(truncatingIfNeeded: $0 * 7) })
    var drawing = Drawing()
    drawing.envelope["version"] = .integer(4)
    drawing.envelope["images"]["inline"] = .object([
      "mime": .string("application/octet-stream"),
      "data": .string(payload.base64EncodedString()), "foreignResource": .integer(9),
    ])
    let saved = try NativeFormat.encode(drawing)
    let separator = try #require(saved.range(of: marker))
    let header = try JSONDecoder().decode(JSONValue.self, from: saved.prefix(separator.lowerBound))
    #expect(header["images"]["inline"]["data"] == .null)
    #expect(
      header["images"]["inline"]["blob"] == .array([.integer(0), .integer(Int64(payload.count))]))
    #expect(header["images"]["inline"]["foreignResource"].int == 9)
    #expect(saved.suffix(from: separator.upperBound) == payload)
    #expect(try NativeFormat.decode(saved).version == 4)
  }

  @Test func binaryImagesRenderExportAndPasteWithoutReusingSourceOffsets() throws {
    let png = try imageData()
    #expect(png.count >= 8192)
    var source = Drawing(width: 64, height: 64)
    source.envelope["images"]["raster"] = resource(png, mime: "image/png")
    var layer = source.layers[0].raw
    layer["kind"]["children"] = .array([imageNode(id: 2)])
    source.envelope["document"]["layers"] = .array([layer])
    source.envelope["document"]["next_id"] = .integer(3)
    source = try NativeFormat.decode(NativeFormat.encode(source))
    let node = try #require(source.node(2))
    #expect(source.renderingWarnings.isEmpty)
    #expect(
      VectorImage.data(node, images: source.envelope["images"], blobs: source.nativeBlobData) == png
    )
    let exported = try VectorRenderer.png(source)
    let renderedSource = try #require(CGImageSourceCreateWithData(exported as CFData, nil))
    let rendered = try #require(CGImageSourceCreateImageAtIndex(renderedSource, 0, nil))
    #expect(rendered.width == 64 && rendered.height == 64)
    #expect(
      String(decoding: try SVGExport.encode(source), as: UTF8.self).contains(
        png.base64EncodedString()))
    #expect(try PDFExport.encode(source).starts(with: Data("%PDF".utf8)))

    let fragment = try VectorFragment(data: VectorFragment(copying: [2], from: source).encoded())
    var destination = Drawing()
    destination.envelope["images"]["raster"] = resource(Data(repeating: 42, count: 10_000))
    destination = try NativeFormat.decode(NativeFormat.encode(destination))
    let before = destination.nativeBlobData
    let ids = try destination.perform(
      .paste(fragment, .inPlace(artboard: 0), container: 1, relativeTo: []))
    let pasted = try #require(ids.first.flatMap(destination.node))
    #expect(pasted.raw["kind"]["key"].string != "raster")
    let reopened = try NativeFormat.decode(NativeFormat.encode(destination))
    #expect(reopened.nativeBlobData.starts(with: before))
    #expect(
      VectorImage.data(pasted, images: reopened.envelope["images"], blobs: reopened.nativeBlobData)
        == png)
    #expect(reopened.renderingWarnings.isEmpty)
  }

  @Test func profilesOpaqueBytesAndAliasedRangesRemainStableAcrossRepeatedSaves() throws {
    let arena = Data((0..<20_000).map { UInt8(truncatingIfNeeded: $0 * 11) })
    var envelope = Drawing().envelope
    let descriptor: JSONValue = .object([
      "mime": .string("application/vnd.iccprofile"),
      "blob": .array([.integer(500), .integer(9000)]), "foreign": .bool(true),
    ])
    envelope["profiles"] = .object(["RGB": descriptor, "alias": descriptor])
    envelope["foreign"] = .object(["blob": .array([.integer(15_000), .integer(100)])])
    var drawing = try NativeFormat.decode(wire(envelope, arena: arena))
    for _ in 0..<3 { drawing = try NativeFormat.decode(NativeFormat.encode(drawing)) }
    #expect(drawing.nativeBlobData == arena)
    #expect(drawing.envelope["profiles"] == envelope["profiles"])
    #expect(drawing.envelope["foreign"] == envelope["foreign"])
    let id = try #require(
      try drawing.perform(
        .addPath(
          [ShapePaths.rectangle(CGRect(x: 0, y: 0, width: 10, height: 10))], VectorStyle(), layer: 1
        )
      ).first)
    let copied = try VectorFragment(copying: [id], from: drawing)
    #expect(copied.drawing.nativeBlobData.isEmpty)
    #expect(copied.drawing.envelope["profiles"]["RGB"]["blob"] == .null)
    #expect(
      Data(base64Encoded: copied.drawing.envelope["profiles"]["RGB"]["data"].string)
        == arena.subdata(in: 500..<9500))
    #expect(copied.drawing.envelope["foreign"] == .null)
  }

  @Test func corruptBinaryRangesAndTrailingDataAreRejected() throws {
    let invalid: [JSONValue] = [
      .array([.integer(-1), .integer(1)]), .array([.integer(0), .integer(-1)]),
      .array([.integer(0), .integer(5)]), .array([.integer(5), .integer(0)]),
      .array([.integer(Int64.max), .integer(Int64.max)]),
      .array([.number(0.5), .integer(1)]), .array([.integer(0)]), .string("0,1"),
    ]
    for range in invalid {
      var envelope = Drawing().envelope
      envelope["images"]["bad"] = .object(["mime": .string("image/png"), "blob": range])
      #expect(throws: DrawingError.self) {
        try NativeFormat.decode(wire(envelope, arena: Data([1, 2, 3, 4])))
      }
    }
    var envelope = Drawing().envelope
    envelope["images"]["missing"] = .object([
      "mime": .string("image/png"), "blob": .array([.integer(0), .integer(1)]),
    ])
    #expect(throws: DrawingError.self) { try NativeFormat.decode(JSONEncoder().encode(envelope)) }
    #expect(throws: DrawingError.self) {
      try NativeFormat.decode(wire(Drawing().envelope, arena: Data(), marker: Data([10, 0, 86])))
    }
    #expect(throws: DrawingError.self) {
      try NativeFormat.decode(JSONEncoder().encode(Drawing().envelope) + Data("{}".utf8))
    }
  }

  @Test func gzipReadsTheWholeBinaryArenaAndRejectsTruncation() throws {
    let payload = Data((0..<12_000).map { UInt8(truncatingIfNeeded: $0) })
    var drawing = Drawing()
    drawing.envelope["images"]["compressed"] = resource(payload)
    let saved = try NativeFormat.encode(drawing)
    let compressed = try gzip(saved)
    let reopened = try NativeFormat.decode(compressed)
    #expect(reopened.nativeBlobData == payload)
    #expect(throws: DrawingError.self) { try NativeFormat.decode(Data(compressed.dropLast(4))) }
  }

  @Test(arguments: [1, 2, 3]) func legacyVersionsKeepInlineResources(version: Int) throws {
    var drawing = Drawing()
    drawing.envelope["version"] = .integer(Int64(version))
    drawing.envelope["format"] = .string(version < 3 ? "drawcraft" : "vectorcraft")
    drawing.envelope["images"]["legacy"] = resource(Data(repeating: 8, count: 9000))
    let saved = try NativeFormat.encode(drawing)
    #expect(saved.range(of: marker) == nil)
    let reopened = try NativeFormat.decode(saved)
    #expect(reopened.version == version)
    #expect(reopened.envelope["images"] == drawing.envelope["images"])
    #expect(throws: DrawingError.self) {
      try NativeFormat.decode(wire(drawing.envelope, arena: Data([1])))
    }
  }

  private func resource(_ bytes: Data, mime: String = "application/octet-stream") -> JSONValue {
    .object(["mime": .string(mime), "data": .string(bytes.base64EncodedString())])
  }
  private func wire(_ envelope: JSONValue, arena: Data, marker: Data? = nil) throws -> Data {
    try JSONEncoder().encode(envelope) + (marker ?? self.marker) + arena
  }
  private func imageNode(id: Int64) -> JSONValue {
    .object([
      "id": .integer(id),
      "kind": .object([
        "type": .string("image"), "key": .string("raster"), "width": .integer(64),
        "height": .integer(64),
        "xf": .array([.integer(1), .integer(0), .integer(0), .integer(1), .integer(0), .integer(0)]
        ),
      ]),
    ])
  }
  private func imageData() throws -> Data {
    var state: UInt32 = 17
    let pixels = Data(
      (0..<(64 * 64 * 4)).map { index -> UInt8 in
        state ^= state << 13
        state ^= state >> 17
        state ^= state << 5
        return index % 4 == 3 ? 255 : UInt8(truncatingIfNeeded: state)
      })
    let provider = try #require(CGDataProvider(data: pixels as CFData))
    let image = try #require(
      CGImage(
        width: 64, height: 64, bitsPerComponent: 8, bitsPerPixel: 32,
        bytesPerRow: 256, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: provider,
        decode: nil, shouldInterpolate: false, intent: .defaultIntent))
    let result = NSMutableData()
    let destination = try #require(
      CGImageDestinationCreateWithData(result, UTType.png.identifier as CFString, 1, nil))
    CGImageDestinationAddImage(destination, image, nil)
    #expect(CGImageDestinationFinalize(destination))
    return result as Data
  }
  private func gzip(_ bytes: Data) throws -> Data {
    var stream = z_stream()
    #expect(
      deflateInit2_(
        &stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 31, 8, Z_DEFAULT_STRATEGY,
        ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK)
    defer { deflateEnd(&stream) }
    var output = [UInt8](repeating: 0, count: Int(compressBound(uLong(bytes.count))) + 32)
    let status = bytes.withUnsafeBytes { input in
      stream.next_in = UnsafeMutablePointer(mutating: input.bindMemory(to: UInt8.self).baseAddress)
      stream.avail_in = uInt(bytes.count)
      return output.withUnsafeMutableBytes { buffer in
        stream.next_out = buffer.bindMemory(to: UInt8.self).baseAddress
        stream.avail_out = uInt(buffer.count)
        return deflate(&stream, Z_FINISH)
      }
    }
    #expect(status == Z_STREAM_END)
    return Data(output.prefix(Int(stream.total_out)))
  }
}
