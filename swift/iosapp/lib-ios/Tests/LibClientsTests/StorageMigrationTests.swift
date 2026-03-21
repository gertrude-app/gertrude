import Dependencies
import Foundation
import GertieIOS
import LibCore
import Testing

@testable import LibClients

@MainActor
@Test func allMigrations() async throws {
  // NB: run from one test to prevent thread contention of group suite
  try await withDependencies {
    $0.api.logEvent = { _, _ in }
    $0.api.fetchDefaultBlockRules = { _ in [.targetContains(value: "def.com")] }
    $0.device.deviceId = { UUID() }
  } operation: {
    try await `block group enum strings migrate to UUIDs`()
    try await `block group migration writes empty array on fresh install`()
    try await `block group migration is idempotent`()
    try await test_v1_3_to_v15_migration()
    try await test_v1_0_to_v15_migration()
  }
}

func `block group enum strings migrate to UUIDs`() async throws {
  let userDefaults = getUserDefaults()

  let legacyGroups: [BlockGroup] = [.gifs, .spotifyImages, .ads]
  try userDefaults.set(JSONEncoder().encode(legacyGroups), forKey: "disabledBlockGroups.v1.3.0")

  #expect(userDefaults.data(forKey: "v1.8.0--disabled-block-group-ids") == nil)
  _ = await migrateLegacyStorage()

  let v2Data = try #require(userDefaults.data(forKey: "v1.8.0--disabled-block-group-ids"))
  let uuids = try JSONDecoder().decode([UUID].self, from: v2Data)
  #expect(uuids == [
    UUID(uuidString: "087628b2-742c-4164-a3cc-717c4ac72c1a")!, // gifs
    UUID(uuidString: "ee242fc6-07c7-4694-a3ce-0323b0ddc1fe")!, // spotifyImages
    UUID(uuidString: "1ea5f1b8-1b14-4894-9913-56cfee98bd48")!, // ads
    UUID(uuidString: "236c92c9-a06c-4f68-9f1a-74e76163ae07")!,
    // appleMusicImages (opted out for upgraders)
  ])
}

func `block group migration writes empty array on fresh install`() async throws {
  let userDefaults = getUserDefaults()

  _ = await migrateLegacyStorage()

  let v2Data = try #require(userDefaults.data(forKey: "v1.8.0--disabled-block-group-ids"))
  let uuids = try JSONDecoder().decode([UUID].self, from: v2Data)
  #expect(uuids == [UUID(uuidString: "236c92c9-a06c-4f68-9f1a-74e76163ae07")!])
}

func `block group migration is idempotent`() async throws {
  let userDefaults = getUserDefaults()

  let legacyGroups: [BlockGroup] = [.gifs]
  try userDefaults.set(JSONEncoder().encode(legacyGroups), forKey: "disabledBlockGroups.v1.3.0")

  _ = await migrateLegacyStorage()
  let firstRunData = try #require(userDefaults.data(forKey: "v1.8.0--disabled-block-group-ids"))

  // change old key — second run must not re-read it
  let newGroups: [BlockGroup] = [.ads, .spotifyImages]
  try userDefaults.set(JSONEncoder().encode(newGroups), forKey: "disabledBlockGroups.v1.3.0")

  _ = await migrateLegacyStorage()
  let secondRunData = try #require(userDefaults.data(forKey: "v1.8.0--disabled-block-group-ids"))
  #expect(firstRunData == secondRunData)
}

func test_v1_3_to_v15_migration() async throws {
  let userDefaults = getUserDefaults()

  let rules = ProtectionMode.Legacy.normal([.targetContains("example.com")])
  let jsonData = try JSONEncoder().encode(rules)
  let jsonString = String(data: jsonData, encoding: .utf8)!

  // legacy json, not typescript friendly
  #expect(jsonString.contains("\"_0\":\"example.com\""))

  userDefaults.set(jsonData, forKey: "ProtectionMode.v1.3.0")

  let disabledData = try JSONEncoder().encode([BlockGroup.whatsAppFeatures])
  userDefaults.set(disabledData, forKey: "disabledBlockGroups.v1.3.0")

  #expect(userDefaults.data(forKey: "v1.5.0--protection-mode") == nil)

  let migrated = await migrateLegacyStorage()
  #expect(migrated == true)

  let migratedData = userDefaults.data(forKey: "v1.5.0--protection-mode")!
  let migratedJson = String(data: migratedData, encoding: .utf8)!

  // typescript friendly
  #expect(migratedJson.contains("\"case\":\"targetContains\""))
  #expect(migratedJson.contains("\"value\":\"example.com\""))
  #expect(!migratedJson.contains("\"_0\":\"example.com\""))

  let decoded = try JSONDecoder().decode(ProtectionMode.self, from: migratedData)
  #expect(decoded == .normal([.targetContains(value: "example.com")]))

  let blockGroupsData = userDefaults.data(forKey: "disabledBlockGroups.v1.3.0")!
  let blockGroups = try JSONDecoder().decode([BlockGroup].self, from: blockGroupsData)
  #expect(blockGroups == [.whatsAppFeatures, .spotifyImages]) // <- spotify added
}

func test_v1_0_to_v15_migration() async throws {
  let userDefaults = getUserDefaults()

  // v1.0/1 had some data at "blockRules.v1" key
  let oldV1Data = Data([0x01, 0x02, 0x03])
  userDefaults.set(oldV1Data, forKey: "blockRules.v1")

  let migrated = await migrateLegacyStorage()
  #expect(migrated == true)

  let blockGroupsData = userDefaults.data(forKey: "disabledBlockGroups.v1.3.0")!
  let blockGroups = try JSONDecoder().decode([BlockGroup].self, from: blockGroupsData)
  #expect(blockGroups == [.spotifyImages])

  let protectionModeData = userDefaults.data(forKey: "v1.5.0--protection-mode")!
  let protectionMode = try JSONDecoder().decode(ProtectionMode.self, from: protectionModeData)

  switch protectionMode {
  case .normal(let rules):
    #expect(rules == [.targetContains(value: "def.com")])
  default:
    Issue.record("Unexpected protection mode: \(protectionMode)")
  }
}

// helpers

func getUserDefaults() -> UserDefaults {
  let userDefaults = UserDefaults.gertrude
  userDefaults.removePersistentDomain(forName: .gertrudeGroupId)
  return userDefaults
}
