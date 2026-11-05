import Foundation

/// Retains the native envelope, including fields this editor does not understand.
public enum JSONValue: Codable, Equatable, Sendable {
  case object([String: JSONValue])
  case array([JSONValue])
  case string(String)
  case integer(Int64)
  case number(Double)
  case bool(Bool)
  case null

  public static func == (lhs: JSONValue, rhs: JSONValue) -> Bool {
    switch (lhs, rhs) {
    case (.object(let a), .object(let b)): a == b
    case (.array(let a), .array(let b)): a == b
    case (.string(let a), .string(let b)): a == b
    case (.integer(let a), .integer(let b)): a == b
    case (.number(let a), .number(let b)): a == b
    case (.number(let a), .integer(let b)), (.integer(let b), .number(let a)):
      Int64(exactly: a) == b
    case (.bool(let a), .bool(let b)): a == b
    case (.null, .null): true
    default: false
    }
  }

  public init(from decoder: any Decoder) throws {
    let value = try decoder.singleValueContainer()
    if value.decodeNil() {
      self = .null
    } else if let v = try? value.decode(Bool.self) {
      self = .bool(v)
    } else if let v = try? value.decode(Int64.self) {
      self = .integer(v)
    } else if let v = try? value.decode(Double.self) {
      self = .number(v)
    } else if let v = try? value.decode(String.self) {
      self = .string(v)
    } else if let v = try? value.decode([JSONValue].self) {
      self = .array(v)
    } else {
      self = .object(try value.decode([String: JSONValue].self))
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var value = encoder.singleValueContainer()
    switch self {
    case .object(let v): try value.encode(v)
    case .array(let v): try value.encode(v)
    case .string(let v): try value.encode(v)
    case .integer(let v): try value.encode(v)
    case .number(let v): try value.encode(v)
    case .bool(let v): try value.encode(v)
    case .null: try value.encodeNil()
    }
  }

  public subscript(key: String) -> JSONValue {
    get { object[key] ?? .null }
    set {
      var v = object
      v[key] = newValue
      self = .object(v)
    }
  }
  public var object: [String: JSONValue] { if case .object(let v) = self { v } else { [:] } }
  public var array: [JSONValue] { if case .array(let v) = self { v } else { [] } }
  public var string: String { if case .string(let v) = self { v } else { "" } }
  public var double: Double? {
    switch self {
    case .number(let v): v
    case .integer(let v): Double(v)
    default: nil
    }
  }
  public var int: Int64? { if case .integer(let v) = self { v } else { nil } }
  public var boolean: Bool? { if case .bool(let v) = self { v } else { nil } }
  public mutating func remove(_ key: String) {
    var v = object
    v[key] = nil
    self = .object(v)
  }
}

public enum DrawingError: LocalizedError, Equatable {
  case invalid(String)
  public var errorDescription: String? {
    switch self {
    case .invalid(let message): message
    }
  }
}
