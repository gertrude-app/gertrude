import Dependencies
import DuetSQL
import Gertie
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class CreateOnboardingAppKeysResolverTests: ApiTestCase, @unchecked Sendable {
  override func setUp() async throws {
    try await super.setUp()
    try await self.db.delete(all: AppBundleId.self)
    try await self.db.delete(all: IdentifiedApp.self)
  }

  func testCreatesSkeletonKeysInDefaultKeychain() async throws {
    let child = try await self.childWithComputer()

    let output = try await CreateOnboardingAppKeys.resolve(
      with: ["com.apple.Music", "com.slack.Slack"],
      in: child.context,
    )

    expect(output).toEqual(.success)

    let keychains = try await child.model.keychains(in: self.db)
    expect(keychains).toHaveCount(1)
    expect(keychains[0].name).toEqual("\(child.name)'s Keychain")

    let keys = try await Api.Key.query()
      .where(.keychainId == keychains[0].id)
      .all(in: self.db)
    expect(keys).toHaveCount(2)
    expect(keys[0].key).toEqual(.skeleton(scope: .bundleId("com.apple.Music")))
    expect(keys[1].key).toEqual(.skeleton(scope: .bundleId("com.slack.Slack")))
  }

  func testPrefersNamedDefaultKeychain() async throws {
    let child = try await self.childWithComputer()
    let older = try await self.db.create(Keychain(
      parentId: child.parentId,
      name: "Custom Keychain",
      isPublic: false,
    ))
    try await self.db.create(ChildKeychain(
      childId: child.id,
      keychainId: older.id,
    ))
    let named = try await self.db.create(Keychain(
      parentId: child.parentId,
      name: "\(child.name)'s Keychain",
      isPublic: false,
    ))
    try await self.db.create(ChildKeychain(
      childId: child.id,
      keychainId: named.id,
    ))

    let output = try await CreateOnboardingAppKeys.resolve(
      with: ["com.apple.Music"],
      in: child.context,
    )

    expect(output).toEqual(.success)

    let keys = try await Api.Key.query()
      .where(.keychainId == named.id)
      .all(in: self.db)
    expect(keys).toHaveCount(1)

    let olderKeys = try await Api.Key.query()
      .where(.keychainId == older.id)
      .all(in: self.db)
    expect(olderKeys).toHaveCount(0)
  }

  func testFallsBackToOldestKeychainWhenNoNameMatch() async throws {
    let child = try await self.childWithComputer()
    let oldest = try await self.db.create(Keychain(
      parentId: child.parentId,
      name: "First Keychain",
      isPublic: false,
    ))
    try await self.db.create(ChildKeychain(
      childId: child.id,
      keychainId: oldest.id,
    ))
    let newer = try await self.db.create(Keychain(
      parentId: child.parentId,
      name: "Second Keychain",
      isPublic: false,
    ))
    try await self.db.create(ChildKeychain(
      childId: child.id,
      keychainId: newer.id,
    ))

    let output = try await CreateOnboardingAppKeys.resolve(
      with: ["com.apple.Music"],
      in: child.context,
    )

    expect(output).toEqual(.success)

    let keys = try await Api.Key.query()
      .where(.keychainId == oldest.id)
      .all(in: self.db)
    expect(keys).toHaveCount(1)

    let newerKeys = try await Api.Key.query()
      .where(.keychainId == newer.id)
      .all(in: self.db)
    expect(newerKeys).toHaveCount(0)
  }

  func testFiltersBrowserBundleIds() async throws {
    let child = try await self.childWithComputer()
    try await self.db.create(Browser(match: .bundleId("com.test.BrowserA")))
    try await self.db.create(Browser(match: .bundleId("com.test.BrowserB")))

    let output = try await CreateOnboardingAppKeys.resolve(
      with: ["com.test.BrowserA", "com.apple.Music", "com.test.BrowserB"],
      in: child.context,
    )

    expect(output).toEqual(.success)

    let keychains = try await child.model.keychains(in: self.db)
    let keys = try await Api.Key.query()
      .where(.keychainId == keychains[0].id)
      .all(in: self.db)
    expect(keys).toHaveCount(1)
    expect(keys[0].key).toEqual(.skeleton(scope: .bundleId("com.apple.Music")))
  }

  func testFiltersMalformedBundleIds() async throws {
    let child = try await self.childWithComputer()

    let output = try await CreateOnboardingAppKeys.resolve(
      with: ["", "nope", "com.apple.Music"],
      in: child.context,
    )

    expect(output).toEqual(.success)

    let keychains = try await child.model.keychains(in: self.db)
    let keys = try await Api.Key.query()
      .where(.keychainId == keychains[0].id)
      .all(in: self.db)
    expect(keys).toHaveCount(1)
    expect(keys[0].key).toEqual(.skeleton(scope: .bundleId("com.apple.Music")))
  }

  func testRejectsRequestWhenTokenTooOld() async throws {
    var child = try await self.childWithComputer()
    child.token.createdAt = Date.reference.addingTimeInterval(-60 * 60 * 25)

    try await expectErrorFrom {
      try await CreateOnboardingAppKeys.resolve(
        with: ["com.apple.Music"],
        in: child.context,
      )
    }.toContain("token too old")
  }

  func testRetryIsIdempotent() async throws {
    let child = try await self.childWithComputer()

    let output1 = try await CreateOnboardingAppKeys.resolve(
      with: ["com.apple.Music", "com.slack.Slack"],
      in: child.context,
    )
    expect(output1).toEqual(.success)

    let output2 = try await CreateOnboardingAppKeys.resolve(
      with: ["com.apple.Music", "com.slack.Slack", "com.spotify.client"],
      in: child.context,
    )
    expect(output2).toEqual(.success)

    let keychains = try await child.model.keychains(in: self.db)
    let keys = try await Api.Key.query()
      .where(.keychainId == keychains[0].id)
      .all(in: self.db)
    expect(keys).toHaveCount(3)
  }

  func testUsesIdentifiedAppSlugWhenAvailable() async throws {
    let child = try await self.childWithComputer()
    let app = try await self.db.create(IdentifiedApp(
      name: "Music",
      slug: "music",
      launchable: true,
    ))
    try await self.db.create(AppBundleId(
      identifiedAppId: app.id,
      bundleId: "com.apple.Music",
    ))

    let output = try await CreateOnboardingAppKeys.resolve(
      with: ["com.apple.Music", "com.unknown.App"],
      in: child.context,
    )

    expect(output).toEqual(.success)

    let keychains = try await child.model.keychains(in: self.db)
    let keys = try await Api.Key.query()
      .where(.keychainId == keychains[0].id)
      .all(in: self.db)
    let sortedKeys = keys.sorted { "\($0.key)" < "\($1.key)" }
    expect(sortedKeys).toHaveCount(2)
    expect(sortedKeys[0].key).toEqual(.skeleton(scope: .bundleId("com.unknown.App")))
    expect(sortedKeys[1].key).toEqual(.skeleton(scope: .identifiedAppSlug("music")))
  }

  func testSkipsSlugKeyWhenLegacyBundleIdKeyExists() async throws {
    let child = try await self.childWithComputer()
    let keychain = try await self.db.create(Keychain(
      parentId: child.parentId,
      name: "\(child.name)'s Keychain",
      isPublic: false,
    ))
    try await self.db.create(ChildKeychain(
      childId: child.id,
      keychainId: keychain.id,
    ))
    try await self.db.create(Key(
      keychainId: keychain.id,
      key: .skeleton(scope: .bundleId("com.apple.Music")),
    ))

    let app = try await self.db.create(IdentifiedApp(
      name: "Music",
      slug: "music",
      launchable: true,
    ))
    try await self.db.create(AppBundleId(
      identifiedAppId: app.id,
      bundleId: "com.apple.Music",
    ))

    let output = try await CreateOnboardingAppKeys.resolve(
      with: ["com.apple.Music"],
      in: child.context,
    )

    expect(output).toEqual(.success)

    let keys = try await Api.Key.query()
      .where(.keychainId == keychain.id)
      .all(in: self.db)
    expect(keys).toHaveCount(1)
    expect(keys[0].key).toEqual(.skeleton(scope: .bundleId("com.apple.Music")))
  }

  func testAllBrowsersFilteredCreatesNoKeychainOrKeys() async throws {
    let child = try await self.childWithComputer()
    try await self.db.create(Browser(match: .bundleId("com.test.BrowserC")))

    let output = try await CreateOnboardingAppKeys.resolve(
      with: ["com.test.BrowserC"],
      in: child.context,
    )

    expect(output).toEqual(.success)

    let keychains = try await child.model.keychains(in: self.db)
    expect(keychains).toHaveCount(0)
  }
}
