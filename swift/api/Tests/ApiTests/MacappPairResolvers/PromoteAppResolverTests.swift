import DuetSQL
import Gertie
import XCTest
import XExpect

@testable import Api

final class PromoteAppResolverTests: ApiTestCase, @unchecked Sendable {
  func testPromoteAppTransfersCountToAppBundleId() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: UnidentifiedApp.self)
    try await self.db.create(UnidentifiedApp(bundleId: "com.foo", count: 42))

    let context = Context(
      requestId: "test",
      dashboardUrl: "/",
      ipAddress: nil,
      telemetry: TelemetryBag(),
    )

    let output = try await PromoteApp.resolve(
      with: .init(
        bundleId: "com.foo",
        newApp: .init(name: "Foo", slug: "foo", categoryId: nil, launchable: true),
        existingAppId: nil,
      ),
      in: context,
    )

    expect(output.upgradedKeyCount).toEqual(0)

    let bundleId = try await AppBundleId.query()
      .where(.bundleId == "com.foo")
      .first(in: self.db)
    expect(bundleId.count).toEqual(42)
    expect(bundleId.identifiedAppId).toEqual(output.identifiedAppId)

    let unidentified = try await UnidentifiedApp.query()
      .where(.bundleId == "com.foo")
      .all(in: self.db)
    expect(unidentified).toHaveCount(0)
  }

  func testPromoteAppWithExistingIdentifiedApp() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: UnidentifiedApp.self)
    let app = try await self.db
      .create(IdentifiedApp(name: "Bar", slug: "bar", launchable: true))
    try await self.db.create(UnidentifiedApp(bundleId: "com.bar", count: 100))

    let context = Context(
      requestId: "test",
      dashboardUrl: "/",
      ipAddress: nil,
      telemetry: TelemetryBag(),
    )

    let output = try await PromoteApp.resolve(
      with: .init(bundleId: "com.bar", newApp: nil, existingAppId: app.id),
      in: context,
    )

    expect(output.identifiedAppId).toEqual(app.id)

    let bundleId = try await AppBundleId.query()
      .where(.bundleId == "com.bar")
      .first(in: self.db)
    expect(bundleId.count).toEqual(100)
  }

  func testPromoteAppWithNoUnidentifiedApp() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: UnidentifiedApp.self)

    let context = Context(
      requestId: "test",
      dashboardUrl: "/",
      ipAddress: nil,
      telemetry: TelemetryBag(),
    )

    _ = try await PromoteApp.resolve(
      with: .init(
        bundleId: "com.new",
        newApp: .init(name: "New", slug: "new", categoryId: nil, launchable: true),
        existingAppId: nil,
      ),
      in: context,
    )

    let bundleId = try await AppBundleId.query()
      .where(.bundleId == "com.new")
      .first(in: self.db)
    expect(bundleId.count).toEqual(0)
  }

  // MARK: - key upgrade on promotion

  func testUpgradesSkeletonBundleIdKeyToSlug() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: UnidentifiedApp.self)
    let parent = try await self.parent()
    let keychain = try await self.db.create(Keychain(
      parentId: parent.id,
      name: "Test Keychain",
    ))
    try await self.db.create(Key(
      keychainId: keychain.id,
      key: .skeleton(scope: .bundleId("com.foo.Bar")),
    ))

    let context = Context(
      requestId: "test",
      dashboardUrl: "/",
      ipAddress: nil,
      telemetry: TelemetryBag(),
    )
    let output = try await PromoteApp.resolve(
      with: .init(
        bundleId: "com.foo.Bar",
        newApp: .init(name: "Bar", slug: "bar", categoryId: nil, launchable: true),
        existingAppId: nil,
      ),
      in: context,
    )

    expect(output.upgradedKeyCount).toEqual(1)

    let keys = try await Key.query()
      .where(.keychainId == keychain.id)
      .all(in: self.db)
    expect(keys).toHaveCount(1)
    expect(keys[0].key).toEqual(.skeleton(scope: .identifiedAppSlug("bar")))
  }

  func testUpgradesNonSkeletonBundleIdKeyToSlug() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: UnidentifiedApp.self)
    let parent = try await self.parent()
    let keychain = try await self.db.create(Keychain(
      parentId: parent.id,
      name: "Test Keychain",
    ))
    try await self.db.create(Key(
      keychainId: keychain.id,
      key: .domain(domain: "example.com", scope: .single(.bundleId("com.foo.Bar"))),
    ))

    let context = Context(
      requestId: "test",
      dashboardUrl: "/",
      ipAddress: nil,
      telemetry: TelemetryBag(),
    )
    let output = try await PromoteApp.resolve(
      with: .init(
        bundleId: "com.foo.Bar",
        newApp: .init(name: "Bar", slug: "bar", categoryId: nil, launchable: true),
        existingAppId: nil,
      ),
      in: context,
    )

    expect(output.upgradedKeyCount).toEqual(1)

    let keys = try await Key.query()
      .where(.keychainId == keychain.id)
      .all(in: self.db)
    expect(keys).toHaveCount(1)
    expect(keys[0].key).toEqual(
      .domain(domain: "example.com", scope: .single(.identifiedAppSlug("bar"))),
    )
  }

  func testDoesNotUpgradeKeysForBrowserSlugs() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: UnidentifiedApp.self)
    try await self.db.create(Browser(match: .bundleId("com.browser.Foo")))
    let parent = try await self.parent()
    let keychain = try await self.db.create(Keychain(
      parentId: parent.id,
      name: "Test Keychain",
    ))
    try await self.db.create(Key(
      keychainId: keychain.id,
      key: .skeleton(scope: .bundleId("com.browser.Foo")),
    ))

    let context = Context(
      requestId: "test",
      dashboardUrl: "/",
      ipAddress: nil,
      telemetry: TelemetryBag(),
    )
    let app = try await self.db.create(IdentifiedApp(
      name: "Foo Browser",
      slug: "foo-browser",
      launchable: true,
    ))
    let output = try await PromoteApp.resolve(
      with: .init(bundleId: "com.browser.Foo", newApp: nil, existingAppId: app.id),
      in: context,
    )

    expect(output.upgradedKeyCount).toEqual(0)

    let keys = try await Key.query()
      .where(.keychainId == keychain.id)
      .all(in: self.db)
    expect(keys).toHaveCount(1)
    expect(keys[0].key).toEqual(.skeleton(scope: .bundleId("com.browser.Foo")))
  }

  func testUpgradeSoftDeletesOnCollision() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: UnidentifiedApp.self)
    let parent = try await self.parent()
    let keychain = try await self.db.create(Keychain(
      parentId: parent.id,
      name: "Test Keychain",
    ))
    let existingSlugKey = try await self.db.create(Key(
      keychainId: keychain.id,
      key: .skeleton(scope: .identifiedAppSlug("bar")),
    ))
    try await self.db.create(Key(
      keychainId: keychain.id,
      key: .skeleton(scope: .bundleId("com.foo.Bar")),
    ))

    let context = Context(
      requestId: "test",
      dashboardUrl: "/",
      ipAddress: nil,
      telemetry: TelemetryBag(),
    )
    let output = try await PromoteApp.resolve(
      with: .init(
        bundleId: "com.foo.Bar",
        newApp: .init(name: "Bar", slug: "bar", categoryId: nil, launchable: true),
        existingAppId: nil,
      ),
      in: context,
    )

    expect(output.upgradedKeyCount).toEqual(1)

    let liveKeys = try await Key.query()
      .where(.keychainId == keychain.id)
      .all(in: self.db)
    expect(liveKeys).toHaveCount(1)
    expect(liveKeys[0].key).toEqual(.skeleton(scope: .identifiedAppSlug("bar")))
    expect(liveKeys[0].id).toEqual(existingSlugKey.id)
  }

  func testUpgradesKeysAcrossMultipleKeychains() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: UnidentifiedApp.self)
    let parent1 = try await self.parent()
    let parent2 = try await self.parent()
    let keychain1 = try await self.db.create(Keychain(
      parentId: parent1.id,
      name: "Keychain 1",
    ))
    let keychain2 = try await self.db.create(Keychain(
      parentId: parent2.id,
      name: "Keychain 2",
    ))
    try await self.db.create(Key(
      keychainId: keychain1.id,
      key: .skeleton(scope: .bundleId("com.foo.Bar")),
    ))
    try await self.db.create(Key(
      keychainId: keychain2.id,
      key: .skeleton(scope: .bundleId("com.foo.Bar")),
    ))

    let context = Context(
      requestId: "test",
      dashboardUrl: "/",
      ipAddress: nil,
      telemetry: TelemetryBag(),
    )
    let output = try await PromoteApp.resolve(
      with: .init(
        bundleId: "com.foo.Bar",
        newApp: .init(name: "Bar", slug: "bar", categoryId: nil, launchable: true),
        existingAppId: nil,
      ),
      in: context,
    )

    expect(output.upgradedKeyCount).toEqual(2)

    let keys1 = try await Key.query()
      .where(.keychainId == keychain1.id)
      .all(in: self.db)
    expect(keys1).toHaveCount(1)
    expect(keys1[0].key).toEqual(.skeleton(scope: .identifiedAppSlug("bar")))

    let keys2 = try await Key.query()
      .where(.keychainId == keychain2.id)
      .all(in: self.db)
    expect(keys2).toHaveCount(1)
    expect(keys2[0].key).toEqual(.skeleton(scope: .identifiedAppSlug("bar")))
  }

  func testNoKeysToUpgradeIsNoOp() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: UnidentifiedApp.self)

    let context = Context(
      requestId: "test",
      dashboardUrl: "/",
      ipAddress: nil,
      telemetry: TelemetryBag(),
    )
    let output = try await PromoteApp.resolve(
      with: .init(
        bundleId: "com.foo.Bar",
        newApp: .init(name: "Bar", slug: "bar", categoryId: nil, launchable: true),
        existingAppId: nil,
      ),
      in: context,
    )

    expect(output.upgradedKeyCount).toEqual(0)

    let keys = try await Key.query().all(in: self.db)
    let barKeys = keys.filter {
      switch $0.key {
      case .skeleton(scope: .bundleId("com.foo.Bar")),
           .skeleton(scope: .identifiedAppSlug("bar")):
        true
      default:
        false
      }
    }
    expect(barKeys).toHaveCount(0)
  }
}
