import Dependencies
import DependenciesMacros
import Foundation
import Security

struct MusicAppConnection: Codable, Equatable, Sendable {
  var token: UUID
  var childId: UUID
  var childName: String
}

@DependencyClient
struct KeychainClient: Sendable {
  var _load: @Sendable (_ key: Key) -> Data?
  var _save: @Sendable (_ key: Key, _ data: Data) -> Void
  var delete: @Sendable (_ key: Key) -> Void
}

extension KeychainClient {
  enum Key: String {
    case deviceId
    case connection

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
    if let data = self._load(.deviceId),
       let string = String(data: data, encoding: .utf8),
       let uuid = UUID(uuidString: string) {
      uuid
    } else {
      nil
    }
  }

  func save(deviceId: UUID) {
    let data = deviceId.uuidString.data(using: .utf8)!
    self._save(.deviceId, data)
  }

  func loadConnection() -> MusicAppConnection? {
    guard let data = self._load(.connection) else { return nil }
    return try? JSONDecoder().decode(MusicAppConnection.self, from: data)
  }

  func save(connection: MusicAppConnection) {
    guard let data = try? JSONEncoder().encode(connection) else { return }
    self._save(.connection, data)
  }

  func deleteConnection() {
    self.delete(.connection)
  }
}

extension KeychainClient: DependencyKey {
  static var liveValue: KeychainClient {
    .init(
      _load: { key in
        let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrAccount as String: key.secAttrAccount,
          kSecReturnData as String: true,
          kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data {
          return data
        } else {
          return nil
        }
      },
      _save: { key, data in
        let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrAccount as String: key.secAttrAccount,
          kSecValueData as String: data,
          kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
      },
      delete: { key in
        let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrAccount as String: key.secAttrAccount,
        ]
        SecItemDelete(query as CFDictionary)
      },
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
        case .connection:
          nil
        }
      },
      _save: { _, _ in },
      delete: { _ in },
    )
  }
#endif
