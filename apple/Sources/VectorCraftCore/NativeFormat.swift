import CZlib
import Foundation

public enum NativeFormat {
  public static let maximumBytes = 64 * 1024 * 1024

  public static func decode(_ data: Data) throws -> Drawing {
    guard data.count <= maximumBytes else {
      throw DrawingError.invalid("The document exceeds the 64 MB Swift editor limit.")
    }
    let bytes = data.starts(with: [0x1f, 0x8b]) ? try inflateGzip(data) : data
    let section = try split(bytes)
    let envelope = try JSONDecoder().decode(JSONValue.self, from: section.json)
    guard ["vectorcraft", "drawcraft"].contains(envelope["format"].string),
      let version = envelope["version"].int, (1...4).contains(version)
    else {
      throw DrawingError.invalid("This is not a supported VectorCraft document (versions 1–4).")
    }
    guard version == 4 || !section.hasBlobs else {
      throw DrawingError.invalid("A native binary section requires document version 4.")
    }
    if version == 4 { try NativeBlob.validate(envelope, blobs: section.blobs) }
    let drawing = Drawing(envelope: envelope, nativeBlobData: section.blobs)
    try drawing.validate()
    return drawing
  }

  /// Scan only the first JSON object; binary image bytes are never interpreted as JSON.
  private static func split(_ bytes: Data) throws -> (json: Data, blobs: Data, hasBlobs: Bool) {
    var depth = 0
    var quoted = false
    var escaped = false
    var end: Data.Index?
    for index in bytes.indices {
      let byte = bytes[index]
      if quoted {
        if escaped {
          escaped = false
        } else if byte == 92 {
          escaped = true
        } else if byte == 34 {
          quoted = false
        }
      } else if byte == 34 {
        quoted = true
      } else if byte == 123 || byte == 91 {
        depth += 1
        guard depth <= 128 else { throw DrawingError.invalid("The document is nested too deeply.") }
      } else if byte == 125 || byte == 93 {
        depth -= 1
        guard depth >= 0 else { throw DrawingError.invalid("The document JSON is damaged.") }
        if depth == 0 {
          end = bytes.index(after: index)
          break
        }
      }
    }
    guard let end else { throw DrawingError.invalid("The document JSON is incomplete.") }
    let rest = bytes.suffix(from: end)
    if rest.starts(with: NativeBlob.marker) {
      return (Data(bytes.prefix(upTo: end)), Data(rest.dropFirst(NativeBlob.marker.count)), true)
    }
    guard rest.allSatisfy({ $0 == 9 || $0 == 10 || $0 == 13 || $0 == 32 }) else {
      throw DrawingError.invalid("Unexpected data after the native document JSON.")
    }
    return (Data(bytes.prefix(upTo: end)), Data(), false)
  }

  public static func encode(_ drawing: Drawing) throws -> Data {
    try drawing.validate()
    var envelope = drawing.envelope
    // Rust uses the source generator to interpret legacy Twist angles.
    if envelope["generator"] == .null {
      envelope["generator"] = .string("VectorCraft Swift 0.1")
    }
    // Carried previews and PDFs would describe the pre-edit document.
    envelope.remove("preview")
    envelope.remove("pdf")
    guard let version = envelope["version"].int, (1...4).contains(version),
      drawing.nativeBlobData.count <= maximumBytes
    else {
      throw DrawingError.invalid("The native document version or binary data is unsupported.")
    }
    var blobs = drawing.nativeBlobData
    if version == 4 {
      try NativeBlob.validate(envelope, blobs: blobs)
      try NativeBlob.outline(&envelope, blobs: &blobs)
    } else if !blobs.isEmpty {
      throw DrawingError.invalid("Keep native version 4 to preserve this document's binary data.")
    }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    var data = try encoder.encode(envelope)
    let suffixSize = blobs.isEmpty ? 0 : NativeBlob.marker.count + blobs.count
    guard suffixSize <= maximumBytes, data.count <= maximumBytes - suffixSize else {
      throw DrawingError.invalid("The document exceeds the 64 MB Swift editor limit.")
    }
    if !blobs.isEmpty {
      data.append(NativeBlob.marker)
      data.append(blobs)
    }
    return data
  }

  private static func inflateGzip(_ data: Data) throws -> Data {
    var stream = z_stream()
    guard inflateInit2_(&stream, 15 + 32, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK
    else {
      throw DrawingError.invalid("Could not read the compressed document.")
    }
    defer { inflateEnd(&stream) }
    return try data.withUnsafeBytes { input in
      stream.next_in = UnsafeMutablePointer(mutating: input.bindMemory(to: UInt8.self).baseAddress)
      stream.avail_in = uInt(data.count)
      var output = Data()
      var buffer = [UInt8](repeating: 0, count: 65536)
      var status: Int32 = Z_OK
      repeat {
        let produced = buffer.withUnsafeMutableBytes { chunk in
          stream.next_out = chunk.bindMemory(to: UInt8.self).baseAddress
          stream.avail_out = uInt(chunk.count)
          status = inflate(&stream, Z_NO_FLUSH)
          return chunk.count - Int(stream.avail_out)
        }
        guard output.count + produced <= maximumBytes else {
          throw DrawingError.invalid(
            "The compressed document exceeds the 64 MB Swift editor limit.")
        }
        output.append(contentsOf: buffer.prefix(produced))
        guard status == Z_OK || status == Z_STREAM_END, produced > 0 || status == Z_STREAM_END
        else {
          throw DrawingError.invalid("The compressed document is damaged.")
        }
      } while status != Z_STREAM_END
      guard stream.avail_in == 0 else {
        throw DrawingError.invalid("Unexpected data after the compressed document.")
      }
      return output
    }
  }
}
