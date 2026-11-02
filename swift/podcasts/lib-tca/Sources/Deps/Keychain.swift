import Dependencies
import DependenciesMacros
import DeviceIdentity
import Foundation

@DependencyClient
struct KeychainClient: Sendable {
  var _load: @Sendable (_ key: Key) throws -> Data?
  var _save: @Sendable (_ key: Key, _ data: Data) throws -> Void
  var delete: @Sendable (_ key: Key) throws -> Void
}

extension KeychainClient {
  enum Key: String {
    case pincode
    case installDate
    case deviceId
    case amToken
    case orphanedAmToken
    case connection
    case migration
    case legacyMigration
    // @deprecated since v1.4.0 - used to hold randomly generated
    // UUID to identify install, but we switched to using deviceId
    // which is derived from identifierForVendor (deviceId) to
    // cross-correlate with installs on the main iOS app
    case installId

    #if !DEBUG
      var secAttrAccount: String {
        "gertrude.am.\(self.rawValue)"
      }

    #elseif targetEnvironment(simulator)
      var secAttrAccount: String {
        "gertrude.am.\(self.rawValue).sim.6"
      }
    #else
      var secAttrAccount: String {
        "gertrude.am.\(self.rawValue).dev.2"
      }
    #endif
  }
}

extension KeychainClient {
  func isFirstLaunch() -> Bool {
    self.loadInstallDate() == nil
  }

  func save(installDate: Date) {
    let data = "\(installDate.timeIntervalSince1970)".data(using: .utf8)!
    try? self._save(.installDate, data)
  }

  func loadInstallDate() -> Date? {
    if let data = try? self._load(.installDate),
       let string = String(data: data, encoding: .utf8),
       let timeInterval = TimeInterval(string) {
      Date(timeIntervalSince1970: timeInterval)
    } else {
      nil
    }
  }

  func loadDeprecatedInstallId() -> UUID? {
    if let data = try? self._load(.installId),
       let string = String(data: data, encoding: .utf8),
       let uuid = UUID(uuidString: string) {
      uuid
    } else {
      nil
    }
  }

  func save(installId: UUID) {
    let data = installId.uuidString.data(using: .utf8)!
    try? self._save(.installId, data)
  }

  func loadDeviceId() -> UUID? {
    if let data = try? self._load(.deviceId),
       let string = String(data: data, encoding: .utf8),
       let uuid = UUID(uuidString: string) {
      uuid
    } else {
      nil
    }
  }

  func save(deviceId: UUID) {
    let data = deviceId.uuidString.data(using: .utf8)!
    try? self._save(.deviceId, data)
  }

  func loadPincode() -> Int? {
    if let data = try? self._load(.pincode),
       let string = String(data: data, encoding: .utf8),
       let pincode = Int(string) {
      pincode
    } else {
      nil
    }
  }

  func hasPincode() -> Bool {
    self.loadPincode() != nil
  }

  func save(pincode: Int) {
    let data = "\(pincode)".data(using: .utf8)!
    try? self._save(.pincode, data)
  }

  func loadAmToken() -> UUID? {
    if let connection = try? self.readConnection() { return connection.token }
    return if let data = try? self._load(.amToken),
              let string = String(data: data, encoding: .utf8),
              let uuid = UUID(uuidString: string) {
      uuid
    } else {
      nil
    }
  }

  func isClaimed() -> Bool {
    self.loadAmToken() != nil
  }

  func save(amToken: UUID) {
    let data = amToken.uuidString.data(using: .utf8)!
    try? self._save(.amToken, data)
  }

  func deleteAmToken() {
    try? self.delete(.amToken)
    try? self.delete(.connection)
  }
}

struct PodcastConnection: Codable, Equatable, Sendable {
  var token: UUID
  var deviceId: UUID
  var childId: UUID?
}

extension KeychainClient {
  var migrationPending: Bool {
    get throws { try self._load(.migration) != nil }
  }

  func readConnection() throws -> PodcastConnection? {
    guard let data = try self._load(.connection) else { return nil }
    return try JSONDecoder().decode(PodcastConnection.self, from: data)
  }

  func writeConnection(_ connection: PodcastConnection) throws {
    try self._save(.connection, JSONEncoder().encode(connection))
    try self.delete(.amToken)
  }

  func removeConnection() throws {
    try self.delete(.amToken)
    try self.delete(.connection)
  }
}

extension KeychainClient: DependencyKey {
  static var liveValue: KeychainClient {
    .init(
      _load: { try PrivateKeychain.read(account: $0.secAttrAccount) },
      _save: { key, data in
        // update old item if exists, prevent duplicate item error
        try PrivateKeychain.write(data, account: key.secAttrAccount)
      },
      delete: { try PrivateKeychain.delete(account: $0.secAttrAccount) },
    )
  }
}

extension DependencyValues {
  var keychain: KeychainClient {
    get { self[KeychainClient.self] }
    set { self[KeychainClient.self] = newValue }
  }
}

#if DEBUG
  extension KeychainClient {
    static let mock = KeychainClient(
      _load: { key in
        switch key {
        case .pincode:
          "111111".data(using: .utf8)!
        case .installDate:
          "1760103425".data(using: .utf8)!
        case .deviceId, .installId:
          "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF".data(using: .utf8)!
        case .amToken, .orphanedAmToken, .connection, .migration, .legacyMigration:
          nil
        }
      },
      _save: { _, _ in },
      delete: { _ in },
    )
  }
#endif
