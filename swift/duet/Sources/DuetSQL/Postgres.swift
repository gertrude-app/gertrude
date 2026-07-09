import Duet
import Foundation
import XCore

public protocol PostgresBindable {
  var postgresData: Postgres.Data { get }
  static var nilPostgresData: Postgres.Data { get }
}

public protocol PostgresRawBindable: PostgresBindable, RawRepresentable
  where RawValue: PostgresBindable {}

public extension PostgresRawBindable {
  var postgresData: Postgres.Data { self.rawValue.postgresData }
  static var nilPostgresData: Postgres.Data { RawValue.nilPostgresData }
}

public protocol PostgresArrayBindable {
  static func postgresData(_ array: [Self]?) -> Postgres.Data
}

public protocol PostgresJsonable: Codable, PostgresBindable {}

public extension PostgresArrayBindable where Self: PostgresJsonable {
  static func postgresData(_ array: [Self]?) -> Postgres.Data {
    .json(array.map { try! JSON.encode($0) })
  }
}

public extension PostgresJsonable {
  var toPostgresJson: String { try! JSON.encode(self) }
  init(fromPostgresJson json: String) throws {
    self = try JSONDecoder().decode(Self.self, from: json.data(using: .utf8)!)
  }

  var postgresData: Postgres.Data { .json(self.toPostgresJson) }
  static var nilPostgresData: Postgres.Data { .json(nil) }
}

public enum Postgres {
  public static let MAX_BIND_PARAMS = Int(INT16_MAX)

  public enum Columns {
    case all
    case columns([String])
  }

  public enum Data: Sendable {
    case id(UUIDIdentifiable)
    case string(String?)
    case textArray([String]?)
    case int(Int?)
    case int64(Int64?)
    case float(Float?)
    case double(Double?)
    case uuid(UUIDStringable?)
    case bool(Bool?)
    case date(Date?)
    case json(String?)
    case bytea(Foundation.Data?)
    case null
    case currentTimestamp
  }
}

public extension Postgres.Data {
  var binding: any Sendable & Encodable {
    switch self {
    case .bool(let bool):
      bool
    case .currentTimestamp:
      "CURRENT_TIMESTAMP"
    case .date(let date):
      date
    case .double(let double):
      double
    case .float(let float):
      float
    case .id(let model):
      model.uuidId.uuidString
    case .int(let int):
      int
    case .int64(let int64):
      int64
    case .textArray(let strings):
      strings
    case .json(let string):
      string
    case .bytea(let data):
      data?.base64EncodedString()
    case .null:
      "NULL"
    case .string(let string):
      string
    case .uuid(let uuid):
      uuid?.uuidString
    }
  }
}

extension Postgres.Data: Equatable {
  public static func == (lhs: Postgres.Data, rhs: Postgres.Data) -> Bool {
    switch (lhs, rhs) {
    case (.id(let lhsId), .id(let rhsId)):
      lhsId.uuidId == rhsId.uuidId
    case (.string(let lhsVal), .string(let rhsVal)),
         (.json(let lhsVal), .json(let rhsVal)):
      lhsVal == rhsVal
    case (.textArray(let lhsVal), .textArray(let rhsVal)):
      lhsVal == rhsVal
    case (.int(let lhsVal), .int(let rhsVal)):
      lhsVal == rhsVal
    case (.int64(let lhsVal), .int64(let rhsVal)):
      lhsVal == rhsVal
    case (.float(let lhsVal), .float(let rhsVal)):
      lhsVal == rhsVal
    case (.double(let lhsVal), .double(let rhsVal)):
      lhsVal == rhsVal
    case (.uuid(let lhsVal), .uuid(let rhsVal)):
      lhsVal?.uuidString == rhsVal?.uuidString
    case (.bool(let lhsVal), .bool(let rhsVal)):
      lhsVal == rhsVal
    case (.date(let lhsVal), .date(let rhsVal)):
      lhsVal == rhsVal
    case (.bytea(let lhsVal), .bytea(let rhsVal)):
      lhsVal == rhsVal
    case (.null, .null):
      true
    case (.currentTimestamp, .currentTimestamp):
      true
    default:
      false
    }
  }
}

extension Postgres.Data: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .string(value)
  }
}

extension Postgres.Data: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self = .int(value)
  }
}

extension Postgres.Data: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: Bool) {
    self = .bool(value)
  }
}

public extension Postgres.Data {
  static var currentTime: Self { .currentTimestamp }
}

extension String: PostgresBindable {
  public var postgresData: Postgres.Data { .string(self) }
  public static var nilPostgresData: Postgres.Data { .string(nil) }
}

extension Int: PostgresBindable {
  public var postgresData: Postgres.Data { .int(self) }
  public static var nilPostgresData: Postgres.Data { .int(nil) }
}

extension Int64: PostgresBindable {
  public var postgresData: Postgres.Data { .int64(self) }
  public static var nilPostgresData: Postgres.Data { .int64(nil) }
}

extension Float: PostgresBindable {
  public var postgresData: Postgres.Data { .float(self) }
  public static var nilPostgresData: Postgres.Data { .float(nil) }
}

extension Double: PostgresBindable {
  public var postgresData: Postgres.Data { .double(self) }
  public static var nilPostgresData: Postgres.Data { .double(nil) }
}

extension Bool: PostgresBindable {
  public var postgresData: Postgres.Data { .bool(self) }
  public static var nilPostgresData: Postgres.Data { .bool(nil) }
}

extension Date: PostgresBindable {
  public var postgresData: Postgres.Data { .date(self) }
  public static var nilPostgresData: Postgres.Data { .date(nil) }
}

extension UUID: PostgresBindable {
  public var postgresData: Postgres.Data { .uuid(self) }
  public static var nilPostgresData: Postgres.Data { .uuid(nil) }
}

extension Foundation.Data: PostgresBindable {
  public var postgresData: Postgres.Data { .bytea(self) }
  public static var nilPostgresData: Postgres.Data { .bytea(nil) }
}

extension String: PostgresArrayBindable {
  public static func postgresData(_ array: [String]?) -> Postgres.Data {
    .textArray(array)
  }
}

extension Array: PostgresBindable where Element: PostgresArrayBindable {
  public var postgresData: Postgres.Data { Element.postgresData(self) }
  public static var nilPostgresData: Postgres.Data { Element.postgresData(nil) }
}

extension Tagged: PostgresBindable where RawValue: PostgresBindable {
  public var postgresData: Postgres.Data { self.rawValue.postgresData }
  public static var nilPostgresData: Postgres.Data { RawValue.nilPostgresData }
}

extension Optional: PostgresBindable where Wrapped: PostgresBindable {
  public var postgresData: Postgres.Data {
    switch self {
    case .some(let wrapped): wrapped.postgresData
    case .none: Wrapped.nilPostgresData
    }
  }

  public static var nilPostgresData: Postgres.Data { Wrapped.nilPostgresData }
}
