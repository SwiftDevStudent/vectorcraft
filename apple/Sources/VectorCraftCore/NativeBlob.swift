import Foundation

/// Native v4 resource descriptors refer to a shared binary arena after the JSON.
enum NativeBlob {
  static let marker = Data([10, 0, 86, 67, 66, 76, 79, 66, 83, 0])
  static let inlineLimit = 8 * 1024

  static func range(_ descriptor: JSONValue, in blobs: Data) throws -> Range<Int> {
    guard case .array(let pair) = descriptor["blob"], pair.count == 2,
      let rawOffset = pair[0].int, let rawLength = pair[1].int,
      let offset = Int(exactly: rawOffset), let length = Int(exactly: rawLength),
      offset >= 0, length >= 0, offset <= blobs.count, length <= blobs.count - offset
    else { throw DrawingError.invalid("A native resource has an invalid or truncated blob range.") }
    return offset..<(offset + length)
  }

  static func data(_ descriptor: JSONValue, in blobs: Data) throws -> Data {
    guard case .object = descriptor, case .string = descriptor["mime"] else {
      throw DrawingError.invalid("A native resource has an invalid descriptor.")
    }
    if descriptor["blob"] != .null {
      let bounds = try range(descriptor, in: blobs)
      let start = blobs.index(blobs.startIndex, offsetBy: bounds.lowerBound)
      let end = blobs.index(start, offsetBy: bounds.count)
      return blobs.subdata(in: start..<end)
    }
    let encoded: String
    switch descriptor["data"] {
    case .string(let value): encoded = value
    case .null: encoded = ""
    default: throw DrawingError.invalid("A native resource has invalid inline data.")
    }
    guard encoded.utf8.count <= ((NativeFormat.maximumBytes + 2) / 3) * 4,
      let bytes = Data(base64Encoded: encoded), bytes.count <= NativeFormat.maximumBytes
    else { throw DrawingError.invalid("A native resource has invalid or oversized inline data.") }
    return bytes
  }

  static func validate(_ envelope: JSONValue, blobs: Data) throws {
    func check(_ descriptor: JSONValue) throws {
      guard case .object = descriptor, case .string = descriptor["mime"] else {
        throw DrawingError.invalid("A native resource has an invalid descriptor.")
      }
      if descriptor["blob"] != .null {
        // Validate aliases without copying the referenced bytes once per descriptor.
        _ = try range(descriptor, in: blobs)
      } else {
        _ = try data(descriptor, in: blobs)
      }
    }
    for key in ["images", "profiles"] where envelope[key] != .null {
      guard case .object(let entries) = envelope[key], entries.count <= 100_000 else {
        throw DrawingError.invalid("The native resource table is invalid or too large.")
      }
      for value in entries.values { try check(value) }
    }
    for key in ["preview", "pdf"] where envelope[key] != .null { try check(envelope[key]) }
  }

  static func outline(_ envelope: inout JSONValue, blobs: inout Data) throws {
    for key in ["images", "profiles"] {
      var entries = envelope[key].object
      for name in entries.keys.sorted() {
        guard var entry = entries[name] else { continue }
        if entry["blob"] != .null {
          // Existing offsets remain stable, including references in foreign JSON.
          entry.remove("data")
        } else {
          let bytes = try data(entry, in: blobs)
          if bytes.count >= inlineLimit {
            guard bytes.count <= NativeFormat.maximumBytes - blobs.count else {
              throw DrawingError.invalid("Native resource data exceeds the 64 MB editor limit.")
            }
            entry["blob"] = .array([.integer(Int64(blobs.count)), .integer(Int64(bytes.count))])
            entry.remove("data")
            blobs.append(bytes)
          }
        }
        entries[name] = entry
      }
      if envelope[key] != .null { envelope[key] = .object(entries) }
    }
  }

  static func materialized(_ descriptor: JSONValue, blobs: Data) throws -> JSONValue {
    guard descriptor["blob"] != .null else { return descriptor }
    var value = descriptor
    value["data"] = .string(try data(descriptor, in: blobs).base64EncodedString())
    value.remove("blob")
    return value
  }

  static func reserve(_ descriptor: JSONValue, blobs: Data, remaining: inout Int) throws {
    let count =
      descriptor["blob"] != .null
      ? try range(descriptor, in: blobs).count : try data(descriptor, in: blobs).count
    guard count <= remaining else {
      throw DrawingError.invalid("Copied resource data exceeds the 64 MB editor limit.")
    }
    remaining -= count
  }

  static func materializedMap(
    _ table: JSONValue, blobs: Data, remaining: inout Int
  ) throws -> JSONValue {
    var entries = table.object
    for name in entries.keys.sorted() {
      guard let entry = entries[name] else { continue }
      try reserve(entry, blobs: blobs, remaining: &remaining)
      entries[name] = try materialized(entry, blobs: blobs)
    }
    return .object(entries)
  }
}
