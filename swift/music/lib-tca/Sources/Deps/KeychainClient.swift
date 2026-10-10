import Dependencies
import DependenciesMacros
import Foundation
import Security

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
  struct StorageError: Error { let status: OSStatus }

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
      _load: { key in
        var query = key.query
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
          throw StorageError(status: status)
        }
        return data
      },
      _save: { key, data in
        let attributes: [String: Any] = [kSecValueData as String: data]
        var status = SecItemUpdate(key.query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
          var item = key.query
          item[kSecValueData as String] = data
          item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
          status = SecItemAdd(item as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw StorageError(status: status) }
      },
      delete: { key in
        let status = SecItemDelete(key.query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
          throw StorageError(status: status)
        }
      },
    )
  }
}

private extension KeychainClient.Key {
  var query: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: self.secAttrAccount,
    ]
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
