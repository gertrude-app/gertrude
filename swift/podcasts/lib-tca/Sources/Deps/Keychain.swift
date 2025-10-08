import Dependencies
import DependenciesMacros
import Foundation
import Security

@DependencyClient
struct KeychainClient: Sendable {
  var load: @Sendable (_ key: Key) -> Data?
  var save: @Sendable (_ key: Key, _ data: Data) -> Void
  var delete: @Sendable (_ key: Key) -> Void
}

extension KeychainClient {
  enum Key: String {
    case pincode
    case installId
    case installDate
  }
}

extension KeychainClient {
  func isFirstLaunch() -> Bool {
    self.loadInstallDate() == nil || self.loadDeviceId() == nil
  }

  func save(installDate: Date) {
    let data = "\(installDate.timeIntervalSince1970)".data(using: .utf8)!
    self.save(.installDate, data)
  }

  func loadInstallDate() -> Date? {
    if let data = self.load(.installDate),
       let string = String(data: data, encoding: .utf8),
       let timeInterval = TimeInterval(string) {
      Date(timeIntervalSince1970: timeInterval)
    } else {
      nil
    }
  }

  func loadDeviceId() -> UUID? {
    if let data = self.load(.installId),
       let string = String(data: data, encoding: .utf8),
       let uuid = UUID(uuidString: string) {
      uuid
    } else {
      nil
    }
  }

  func save(installId: UUID) {
    let data = installId.uuidString.data(using: .utf8)!
    self.save(.installId, data)
  }

  func loadPincode() -> Int? {
    if let data = self.load(.pincode),
       let string = String(data: data, encoding: .utf8),
       let pincode = Int(string) {
      pincode
    } else {
      nil
    }
  }

  func save(pincode: Int) {
    let data = "\(pincode)".data(using: .utf8)!
    self.save(.pincode, data)
  }
}

extension KeychainClient: DependencyKey {
  static var liveValue: KeychainClient {
    .init(
      load: { key in
        let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrAccount as String: "gertrude.am.\(key.rawValue)",
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
      save: { key, data in
        let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrAccount as String: "gertrude.am.\(key.rawValue)",
          kSecValueData as String: data,
          kSecAttrAccessible as String: accessibleAttr(),
        ]
        // important to remove old item if exists, prevent error
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
      },
      delete: { key in
        let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrAccount as String: "gertrude.am.\(key.rawValue)",
        ]
        SecItemDelete(query as CFDictionary)
      }
    )
  }
}

private func accessibleAttr() -> CFString {
  #if DEBUG
    return kSecAttrAccessibleWhenUnlocked
  #else
    return kSecAttrAccessibleAlways
  #endif
}

extension DependencyValues {
  var keychain: KeychainClient {
    get { self[KeychainClient.self] }
    set { self[KeychainClient.self] = newValue }
  }
}
