import Dependencies
import DependenciesMacros
import Foundation
import Security

@DependencyClient
struct KeychainClient: Sendable {
  var _load: @Sendable (_ key: Key) -> Data?
  var _save: @Sendable (_ key: Key, _ data: Data) -> Void
  var delete: @Sendable (_ key: Key) -> Void
}

extension KeychainClient {
  enum Key: String {
    case pincode
    case installId
    case installDate

    #if !DEBUG
      var secAttrAccount: String {
        "gertrude.am.\(self.rawValue)"
      }
    #else
      var secAttrAccount: String {
        "gertrude.am.\(self.rawValue).dev"
      }
    #endif
  }
}

extension KeychainClient {
  func isFirstLaunch() -> Bool {
    self.loadInstallDate() == nil || self.loadInstallId() == nil
  }

  func save(installDate: Date) {
    let data = "\(installDate.timeIntervalSince1970)".data(using: .utf8)!
    self._save(.installDate, data)
  }

  func loadInstallDate() -> Date? {
    if let data = self._load(.installDate),
       let string = String(data: data, encoding: .utf8),
       let timeInterval = TimeInterval(string) {
      Date(timeIntervalSince1970: timeInterval)
    } else {
      nil
    }
  }

  func loadInstallId() -> UUID? {
    if let data = self._load(.installId),
       let string = String(data: data, encoding: .utf8),
       let uuid = UUID(uuidString: string) {
      uuid
    } else {
      nil
    }
  }

  func save(installId: UUID) {
    let data = installId.uuidString.data(using: .utf8)!
    self._save(.installId, data)
  }

  func loadPincode() -> Int? {
    if let data = self._load(.pincode),
       let string = String(data: data, encoding: .utf8),
       let pincode = Int(string) {
      pincode
    } else {
      nil
    }
  }

  func save(pincode: Int) {
    let data = "\(pincode)".data(using: .utf8)!
    self._save(.pincode, data)
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
        // important to remove old item if exists, prevent error
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
      },
      delete: { key in
        let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrAccount as String: key.secAttrAccount,
        ]
        SecItemDelete(query as CFDictionary)
      }
    )
  }
}

extension DependencyValues {
  var keychain: KeychainClient {
    get { self[KeychainClient.self] }
    set { self[KeychainClient.self] = newValue }
  }
}
