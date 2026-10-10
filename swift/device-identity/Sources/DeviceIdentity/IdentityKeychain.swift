import Foundation
import Security

public struct IdentityKeychainConfiguration: Sendable {
  public var privateAccessGroup: String
  public var appMemoryAccount: String
  public var appMemoryService: String
  public var sharedAccessGroup: String
  public var service: String
  public var accountSuffix: String

  public init(
    privateAccessGroup: String,
    appMemoryAccount: String,
    appMemoryService: String = "",
    sharedAccessGroup: String = "WFN83LM943.com.netrivet.gertrude.identity",
    service: String = "com.netrivet.gertrude.identity",
    accountSuffix: String = Self.buildSuffix,
  ) {
    self.privateAccessGroup = privateAccessGroup
    self.appMemoryAccount = appMemoryAccount
    self.appMemoryService = appMemoryService
    self.sharedAccessGroup = sharedAccessGroup
    self.service = service
    self.accountSuffix = accountSuffix
  }

  public static var buildSuffix: String {
    #if !DEBUG
      ""
    #elseif targetEnvironment(simulator)
      ".sim"
    #else
      ".dev"
    #endif
  }
}

@MainActor
public struct IdentityKeychain {
  let configuration: IdentityKeychainConfiguration
  let operations: Operations

  public init(configuration: IdentityKeychainConfiguration) {
    self.init(configuration: configuration, operations: .live)
  }

  init(configuration: IdentityKeychainConfiguration, operations: Operations) {
    self.configuration = configuration
    self.operations = operations
  }

  public var storage: IdentityStorage {
    .init(
      read: self.read,
      add: self.add,
      write: self.write,
      delete: self.delete,
    )
  }

  func query(_ slot: IdentitySlot) -> [String: Any] {
    let shared = slot == .identity || slot == .canary
    return [
      kSecClass as String: kSecClassGenericPassword,
      kSecUseDataProtectionKeychain as String: true,
      kSecAttrSynchronizable as String: false,
      kSecAttrService as String: slot == .appMemory
        ? self.configuration.appMemoryService : self.configuration.service,
      kSecAttrAccessGroup as String: shared
        ? self.configuration.sharedAccessGroup : self.configuration.privateAccessGroup,
      kSecAttrAccount as String: slot == .appMemory
        ? self.configuration.appMemoryAccount : slot.rawValue + self.configuration.accountSuffix,
    ]
  }

  func attributes(_ slot: IdentitySlot, _ data: Data) -> [String: Any] {
    [
      kSecValueData as String: data,
      kSecAttrAccessible as String: slot == .canary || slot == .pendingTransition
        ? kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly : kSecAttrAccessibleAfterFirstUnlock,
    ]
  }

  func lookupQuery(_ slot: IdentitySlot) -> [String: Any] {
    guard slot == .appMemory else { return self.query(slot) }
    return [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: self.configuration.appMemoryAccount,
    ]
  }

  func read(_ slot: IdentitySlot) -> IdentityRead<Data> {
    var query = self.lookupQuery(slot)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    let (status, data) = self.operations.read(query)
    switch status {
    case errSecSuccess:
      return data.map(IdentityRead.value)
        ?? (slot == .pendingTransition ? .unknown(errSecDecode) : .absent)
    case errSecDecode:
      return slot == .pendingTransition ? .unknown(errSecDecode) : .absent
    case errSecItemNotFound:
      return .absent
    default:
      return .unknown(status)
    }
  }

  func add(_ slot: IdentitySlot, _ data: Data) -> IdentityWrite {
    self
      .result(self.operations.add(self.query(slot).merging(self.attributes(slot, data)) { _, b in
        b
      }))
  }

  func write(_ slot: IdentitySlot, _ data: Data) -> IdentityWrite {
    let status = self.operations.update(self.lookupQuery(slot), self.attributes(slot, data))
    if status == errSecDecode {
      let deleted = self.delete(slot)
      guard deleted == .success else { return deleted }
    } else if status != errSecItemNotFound {
      return self.result(status)
    }
    let added = self.add(slot, data)
    if added == .duplicate {
      return self.result(self.operations.update(
        self.lookupQuery(slot),
        self.attributes(slot, data),
      ))
    }
    return added
  }

  func delete(_ slot: IdentitySlot) -> IdentityWrite {
    let status = self.operations.delete(self.lookupQuery(slot))
    return status == errSecItemNotFound ? .success : self.result(status)
  }

  func result(_ status: OSStatus) -> IdentityWrite {
    switch status {
    case errSecSuccess: .success
    case errSecDuplicateItem: .duplicate
    default: .failure(status)
    }
  }

  struct Operations {
    var read: ([String: Any]) -> (OSStatus, Data?)
    var add: ([String: Any]) -> OSStatus
    var update: ([String: Any], [String: Any]) -> OSStatus
    var delete: ([String: Any]) -> OSStatus

    static var live: Self {
      .init(
        read: { query in
          var result: CFTypeRef?
          let status = SecItemCopyMatching(query as CFDictionary, &result)
          return (status, result as? Data)
        },
        add: { SecItemAdd($0 as CFDictionary, nil) },
        update: { SecItemUpdate($0 as CFDictionary, $1 as CFDictionary) },
        delete: { SecItemDelete($0 as CFDictionary) },
      )
    }
  }
}

public enum PrivateKeychain {
  public struct StorageError: Error {
    public let status: OSStatus
  }

  public static func read(account: String) throws -> Data? {
    var query = self.query(account)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess, let data = result as? Data else {
      throw StorageError(status: status)
    }
    return data
  }

  public static func write(_ data: Data, account: String) throws {
    let query = self.query(account)
    let attributes: [String: Any] = [kSecValueData as String: data]
    var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      var item = query
      item[kSecValueData as String] = data
      item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
      status = SecItemAdd(item as CFDictionary, nil)
    }
    guard status == errSecSuccess else { throw StorageError(status: status) }
  }

  public static func delete(account: String) throws {
    let status = SecItemDelete(self.query(account) as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw StorageError(status: status)
    }
  }

  private static func query(_ account: String) -> [String: Any] {
    [kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: account]
  }
}
