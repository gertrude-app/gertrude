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

  func testCreatesUnrestrictedMacApps() async throws {
    let child = try await self.childWithComputer()

    let output = try await CreateOnboardingAppKeys.resolve(
      with: ["com.apple.Music", "com.slack.Slack"],
      in: child.context,
    )

    expect(output).toEqual(.success)

    // no keychain is created — app-unrestrict no longer lives in keychains
    let keychains = try await child.model.keychains(in: self.db)
    expect(keychains).toHaveCount(0)

    let apps = try await child.model.unrestrictedMacApps(in: self.db)
      .sorted { "\($0.scope)" < "\($1.scope)" }
    expect(apps).toHaveCount(2)
    expect(apps[0].scope).toEqual(.bundleId("com.apple.Music"))
    expect(apps[1].scope).toEqual(.bundleId("com.slack.Slack"))
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

    let apps = try await child.model.unrestrictedMacApps(in: self.db)
    expect(apps).toHaveCount(1)
    expect(apps[0].scope).toEqual(.bundleId("com.apple.Music"))
  }

  func testFiltersMalformedBundleIds() async throws {
    let child = try await self.childWithComputer()

    let output = try await CreateOnboardingAppKeys.resolve(
      with: ["", "nope", "com.apple.Music"],
      in: child.context,
    )

    expect(output).toEqual(.success)

    let apps = try await child.model.unrestrictedMacApps(in: self.db)
    expect(apps).toHaveCount(1)
    expect(apps[0].scope).toEqual(.bundleId("com.apple.Music"))
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

    let apps = try await child.model.unrestrictedMacApps(in: self.db)
    expect(apps).toHaveCount(3)
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

    let apps = try await child.model.unrestrictedMacApps(in: self.db)
      .sorted { "\($0.scope)" < "\($1.scope)" }
    expect(apps).toHaveCount(2)
    expect(apps[0].scope).toEqual(.bundleId("com.unknown.App"))
    expect(apps[1].scope).toEqual(.identifiedAppSlug("music"))
  }

  func testSkipsSlugAppWhenLegacyBundleIdAppExists() async throws {
    let child = try await self.childWithComputer()
    try await self.db.create(UnrestrictedMacApp(
      scope: .bundleId("com.apple.Music"),
      childId: child.id,
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

    let apps = try await child.model.unrestrictedMacApps(in: self.db)
    expect(apps).toHaveCount(1)
    expect(apps[0].scope).toEqual(.bundleId("com.apple.Music"))
  }

  func testSkipsSlugAppWhenDotPrefixedLegacyBundleIdAppExists() async throws {
    let child = try await self.childWithComputer()
    try await self.db.create(UnrestrictedMacApp(
      scope: .bundleId(".com.apple.Music"), // <-- legacy dot-prefixed bundleId
      childId: child.id,
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

    // normalization means the dot-prefixed legacy row covers the slug — no dupe
    let apps = try await child.model.unrestrictedMacApps(in: self.db)
    expect(apps).toHaveCount(1)
  }

  func testAllBrowsersFilteredCreatesNothing() async throws {
    let child = try await self.childWithComputer()
    try await self.db.create(Browser(match: .bundleId("com.test.BrowserC")))

    let output = try await CreateOnboardingAppKeys.resolve(
      with: ["com.test.BrowserC"],
      in: child.context,
    )

    expect(output).toEqual(.success)

    let apps = try await child.model.unrestrictedMacApps(in: self.db)
    expect(apps).toHaveCount(0)
    let keychains = try await child.model.keychains(in: self.db)
    expect(keychains).toHaveCount(0)
  }
}
