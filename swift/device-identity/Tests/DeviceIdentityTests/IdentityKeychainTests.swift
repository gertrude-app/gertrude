import CustomDump
import Foundation
import Security
import Testing

@testable import DeviceIdentity

@MainActor
struct IdentityKeychainTests {
  @Test(arguments: IdentitySlot.allCases)
  func queriesScopeEachSlotAndPreserveLegacyAccount(slot: IdentitySlot) {
    let h = KeychainHarness()
    _ = h.keychain.storage.add(slot, Data("value".utf8))
    let query = h.queries[0]
    expectNoDifference(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
    expectNoDifference(query[kSecAttrSynchronizable as String] as? Bool, false)
    expectNoDifference(query[kSecUseDataProtectionKeychain as String] as? Bool, true)
    expectNoDifference(
      query[kSecAttrService as String] as? String,
      slot == .appMemory ? "" : "com.netrivet.gertrude.identity",
    )
    expectNoDifference(
      query[kSecAttrAccount as String] as? String,
      slot == .appMemory ? "legacy.deviceId.dev.2" : slot.rawValue + ".dev",
    )
    expectNoDifference(
      query[kSecAttrAccessGroup as String] as? String,
      slot == .identity || slot == .canary
        ? "WFN83LM943.com.netrivet.gertrude.identity" : "team.app",
    )
    expectNoDifference(
      query[kSecAttrAccessible as String] as? String,
      slot == .canary || slot == .pendingTransition
        ? kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
        : kSecAttrAccessibleAfterFirstUnlock as String,
    )
  }

  @Test(arguments: [errSecItemNotFound, errSecDecode])
  func missingAndUndecryptableItemsAreAbsent(status: OSStatus) {
    let h = KeychainHarness()
    h.readStatus = status
    expectNoDifference(h.keychain.storage.readId(.canary), .absent)
  }

  @Test(arguments: [
    errSecInteractionNotAllowed,
    errSecMissingEntitlement,
    errSecNotAvailable,
    -999
  ])
  func otherErrorsAreUnknown(status: OSStatus) {
    let h = KeychainHarness()
    h.readStatus = status
    expectNoDifference(h.keychain.storage.readId(.identity), .unknown(status))
  }

  @Test(arguments: [Data(), Data("not-a-uuid".utf8), Data([0xFF])])
  func invalidIdentityDataIsAbsent(data: Data) {
    let h = KeychainHarness()
    h.readData = data
    expectNoDifference(h.keychain.storage.readId(.identity), .absent)
  }

  @Test func validUUIDDataIsRead() {
    let h = KeychainHarness()
    h.readData = Data(oldId.uuidString.utf8)
    expectNoDifference(h.keychain.storage.readId(.identity), .value(oldId))
    expectNoDifference(h.queries[0][kSecReturnData as String] as? Bool, true)
    expectNoDifference(
      h.queries[0][kSecMatchLimit as String] as? String,
      kSecMatchLimitOne as String,
    )
  }

  @Test(arguments: [errSecDecode, errSecSuccess])
  func unreadableReceiptIsDistinguishedFromAbsence(status: OSStatus) {
    let h = KeychainHarness()
    h.readStatus = status
    expectNoDifference(h.keychain.storage.read(.pendingTransition), .unknown(errSecDecode))
  }

  @Test func updateDoesNotDeleteExistingItem() {
    let h = KeychainHarness()
    expectNoDifference(h.keychain.storage.write(.identity, Data()), .success)
    expectNoDifference(h.calls, ["update"])
    #expect(h.queries[0][kSecReturnData as String] == nil)
  }

  @Test func legacyMemoryReadUsesOnlyTheOriginalAccountAndClass() {
    let h = KeychainHarness()
    h.readData = Data(oldId.uuidString.utf8)
    expectNoDifference(h.keychain.storage.readId(.appMemory), .value(oldId))
    expectNoDifference(h.queries[0] as NSDictionary, [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: "legacy.deviceId.dev.2",
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ] as NSDictionary)
  }

  @Test func legacyMemoryUpdateDoesNotInsertACompetingScopedItem() {
    let h = KeychainHarness()
    let data = Data(newId.uuidString.utf8)
    expectNoDifference(h.keychain.storage.write(.appMemory, data), .success)
    expectNoDifference(h.calls, ["update"])
    expectNoDifference(h.queries[0] as NSDictionary, [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: "legacy.deviceId.dev.2",
    ] as NSDictionary)
    expectNoDifference(h.updateAttributes[0] as NSDictionary, [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
    ] as NSDictionary)
  }

  @Test func missingLegacyMemoryIsInsertedIntoTheConfiguredPrivateGroup() {
    let h = KeychainHarness()
    h.updateStatuses = [errSecItemNotFound]
    expectNoDifference(h.keychain.storage.write(.appMemory, Data()), .success)
    expectNoDifference(h.calls, ["update", "add"])
    expectNoDifference(h.queries[0].count, 2)
    expectNoDifference(h.queries[1][kSecAttrAccessGroup as String] as? String, "team.app")
    expectNoDifference(h.queries[1][kSecAttrService as String] as? String, "")
    expectNoDifference(h.queries[1][kSecAttrSynchronizable as String] as? Bool, false)
  }

  @Test func unreadableLegacyMemoryIsNotReplacedByANewScopedItem() {
    let h = KeychainHarness()
    h.updateStatuses = [errSecInteractionNotAllowed]
    expectNoDifference(
      h.keychain.storage.write(.appMemory, Data()), .failure(errSecInteractionNotAllowed),
    )
    expectNoDifference(h.calls, ["update"])
  }

  @Test func undecryptableLegacyMemoryIsDeletedUsingTheSameLegacyQuery() {
    let h = KeychainHarness()
    h.updateStatuses = [errSecDecode]
    expectNoDifference(h.keychain.storage.write(.appMemory, Data()), .success)
    expectNoDifference(h.calls, ["update", "delete", "add"])
    expectNoDifference(h.queries[1] as NSDictionary, h.queries[0] as NSDictionary)
    expectNoDifference(h.queries[1].count, 2)
  }

  @Test(arguments: [IdentitySlot.identity, .canary, .pendingTransition])
  func newSlotLookupsRemainExplicitlyScoped(slot: IdentitySlot) {
    let h = KeychainHarness()
    _ = h.keychain.storage.read(slot)
    _ = h.keychain.storage.write(slot, Data())
    _ = h.keychain.storage.delete(slot)
    for query in h.queries {
      expectNoDifference(
        query[kSecAttrService as String] as? String,
        "com.netrivet.gertrude.identity",
      )
      expectNoDifference(query[kSecAttrSynchronizable as String] as? Bool, false)
      expectNoDifference(query[kSecUseDataProtectionKeychain as String] as? Bool, true)
      expectNoDifference(
        query[kSecAttrAccessGroup as String] as? String,
        slot == .pendingTransition ? "team.app" :
          "WFN83LM943.com.netrivet.gertrude.identity",
      )
    }
  }

  @Test func upsertAddsMissingItemAndRetriesConcurrentInsertion() {
    let h = KeychainHarness()
    h.updateStatuses = [errSecItemNotFound, errSecSuccess]
    h.addStatus = errSecDuplicateItem
    expectNoDifference(h.keychain.storage.write(.identity, Data()), .success)
    expectNoDifference(h.calls, ["update", "add", "update"])
  }

  @Test func undecryptableItemCanBeReplaced() {
    let h = KeychainHarness()
    h.updateStatuses = [errSecDecode]
    expectNoDifference(h.keychain.storage.write(.canary, Data()), .success)
    expectNoDifference(h.calls, ["update", "delete", "add"])
  }

  @Test func failedUndecryptableItemDeletionStopsWrite() {
    let h = KeychainHarness()
    h.updateStatuses = [errSecDecode]
    h.deleteStatus = errSecInteractionNotAllowed
    expectNoDifference(
      h.keychain.storage.write(.canary, Data()),
      .failure(errSecInteractionNotAllowed),
    )
    expectNoDifference(h.calls, ["update", "delete"])
  }

  @Test func unknownUpdateFailureDoesNotDeleteOrAdd() {
    let h = KeychainHarness()
    h.updateStatuses = [errSecNotAvailable]
    expectNoDifference(h.keychain.storage.write(.identity, Data()), .failure(errSecNotAvailable))
    expectNoDifference(h.calls, ["update"])
  }

  @Test func failedRaceRetryIsReturned() {
    let h = KeychainHarness()
    h.updateStatuses = [errSecItemNotFound, errSecNotAvailable]
    h.addStatus = errSecDuplicateItem
    expectNoDifference(h.keychain.storage.write(.identity, Data()), .failure(errSecNotAvailable))
  }

  @Test func addOnlyReturnsDuplicateWithoutOverwritingWinner() {
    let h = KeychainHarness()
    h.addStatus = errSecDuplicateItem
    expectNoDifference(h.keychain.storage.add(.identity, Data()), .duplicate)
    expectNoDifference(h.calls, ["add"])
  }

  @Test func missingReceiptDeletionSucceeds() {
    let h = KeychainHarness()
    h.deleteStatus = errSecItemNotFound
    expectNoDifference(h.keychain.storage.delete(.pendingTransition), .success)
  }
}

@MainActor
private final class KeychainHarness {
  var readStatus = errSecSuccess
  var readData: Data?
  var addStatus = errSecSuccess
  var deleteStatus = errSecSuccess
  var updateStatuses: [OSStatus] = [errSecSuccess]
  var calls: [String] = []
  var queries: [[String: Any]] = []
  var updateAttributes: [[String: Any]] = []

  var keychain: IdentityKeychain {
    .init(configuration: .init(
      privateAccessGroup: "team.app", appMemoryAccount: "legacy.deviceId.dev.2",
      accountSuffix: ".dev",
    ), operations: .init(
      read: { query in
        self.queries.append(query)
        self.calls.append("read")
        return (self.readStatus, self.readData)
      },
      add: { query in
        self.queries.append(query)
        self.calls.append("add")
        return self.addStatus
      },
      update: { query, attributes in
        self.queries.append(query)
        self.updateAttributes.append(attributes)
        self.calls.append("update")
        return self.updateStatuses.removeFirst()
      },
      delete: { query in
        self.queries.append(query)
        self.calls.append("delete")
        return self.deleteStatus
      },
    ))
  }
}
