import Dependencies
import DependenciesMacros
import DeviceIdentity
import Foundation

struct MusicAppConnection: Codable, Equatable, Sendable {
  var token: UUID
  var childId: UUID
  var childName: String
  var deviceId: UUID? = nil
}

@DependencyClient
struct KeychainClient: Sendable {
  var _load: @Sendable (_ key: Key) throws -> Data?
  var _save: @Sendable (_ key: Key, _ data: Data) throws -> Void
  var delete: @Sendable (_ key: Key) throws -> Void
}

extension KeychainClient {
  enum Key: String {
    case deviceId
    case connection
    case migration

    #if !DEBUG
      var secAttrAccount: String {
        "gertrude.music.\(self.rawValue)"
      }

    #elseif targetEnvironment(simulator)
      var secAttrAccount: String {
        "gertrude.music.\(self.rawValue).sim.1"
      }
    #else
      var secAttrAccount: String {
        "gertrude.music.\(self.rawValue).dev.1"
      }
    #endif
  }
}

extension KeychainClient {
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

  func loadConnection() -> MusicAppConnection? {
    guard let data = try? self._load(.connection) else { return nil }
    return try? JSONDecoder().decode(MusicAppConnection.self, from: data)
  }

  func save(connection: MusicAppConnection) {
    guard let data = try? JSONEncoder().encode(connection) else { return }
    try? self._save(.connection, data)
  }

  func deleteConnection() {
    try? self.delete(.connection)
  }
}

extension KeychainClient {
  var migrationPending: Bool {
    get throws { try self._load(.migration) != nil }
  }

  func readConnection() throws -> MusicAppConnection? {
    guard let data = try self._load(.connection) else { return nil }
    return try JSONDecoder().decode(MusicAppConnection.self, from: data)
  }

  func writeConnection(_ connection: MusicAppConnection) throws {
    try self._save(.connection, JSONEncoder().encode(connection))
  }
}

extension KeychainClient: DependencyKey {
  static var liveValue: KeychainClient {
    .init(
      _load: { try PrivateKeychain.read(account: $0.secAttrAccount) },
      _save: { key, data in
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
        case .deviceId:
          "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF".data(using: .utf8)!
        case .connection, .migration:
          nil
        }
      },
      _save: { _, _ in },
      delete: { _ in },
    )
  }
#endif
