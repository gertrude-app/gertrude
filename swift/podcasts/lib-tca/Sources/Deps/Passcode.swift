import Dependencies
import DependenciesMacros
import Foundation
import Security

@DependencyClient
struct PasscodeClient: Sendable {
  public var load: @Sendable () -> Int?
  public var save: @Sendable (Int) -> Void
}

extension PasscodeClient {
  public func verify(_ input: Int) -> Bool {
    self.load() == input
  }
}

extension PasscodeClient: DependencyKey {
  static var liveValue: PasscodeClient {
    .init(
      load: {
        let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrAccount as String: "passcode",
          kSecReturnData as String: true,
          kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data,
           let string = String(data: data, encoding: .utf8),
           let passcode = Int(string) {
          return passcode
        } else {
          return nil
        }
      },
      save: { passcode in
        let data = "\(passcode)".data(using: .utf8)!
        let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrAccount as String: "passcode",
          kSecValueData as String: data,
          kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]
        // important to remove old item if exists, prevent error
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
      }
    )
  }
}

extension DependencyValues {
  var passcode: PasscodeClient {
    get { self[PasscodeClient.self] }
    set { self[PasscodeClient.self] = newValue }
  }
}
