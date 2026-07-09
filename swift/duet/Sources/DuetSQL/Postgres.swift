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

public protocol PostgresEnum: Sendable, PostgresBindable {
  var typeName: String { get }
  var rawValue: String { get }
}

public extension PostgresEnum {
  var postgresData: Postgres.Data { .enum(self) }
  static var nilPostgresData: Postgres.Data { .enum(nil) }
}

public extension PostgresEnum where Self: CaseIterable {
  static var typeName: String {
    guard let first = allCases.first else {
      fatalError("PostgresEnum \(Self.self) has no cases")
    }
    return first.typeName
  }
}

public protocol PostgresJsonable: Codable, PostgresBindable {}

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
    case intArray([Int]?)
    case int(Int?)
    case int64(Int64?)
    case float(Float?)
    case double(Double?)
    case uuid(UUIDStringable?)
    case bool(Bool?)
    case date(Date?)
    case `enum`(PostgresEnum?)
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
      return bool
    case .currentTimestamp:
      return "CURRENT_TIMESTAMP"
    case .date(let date):
      return date
    case .double(let double):
      return double
    case .enum(let enumVal):
      return enumVal?.rawValue
    case .float(let float):
      return float
    case .id(let model):
      return model.uuidId.uuidString
    case .int(let int):
      return int
    case .int64(let int64):
      return int64
    case .intArray(let ints):
      guard let ints else { return "NULL" }
      return "'{\(ints.map(String.init).joined(separator: ","))}'"
    case .json(let string):
      return string
    case .bytea(let data):
      return data?.base64EncodedString()
    case .null:
      return "NULL"
    case .string(let string):
      return string
    case .uuid(let uuid):
      return uuid?.uuidString
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
    case (.intArray(let lhsVal), .intArray(let rhsVal)):
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
    case (.enum(let lhsVal), .enum(let rhsVal)):
      lhsVal?.rawValue == rhsVal?.rawValue
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

extension [Int]: PostgresBindable {
  public var postgresData: Postgres.Data { .intArray(self) }
  public static var nilPostgresData: Postgres.Data { .intArray(nil) }
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
