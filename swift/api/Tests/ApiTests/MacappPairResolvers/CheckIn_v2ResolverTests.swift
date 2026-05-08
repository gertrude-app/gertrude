import DuetSQL
import Gertie
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class CheckIn_v2ResolverTests: ApiTestCase, @unchecked Sendable {
  func testCheckIn_UserProps() async throws {
    let child = try await self.child(with: {
      $0.keyloggingEnabled = false
      $0.screenshotsEnabled = true
      $0.screenshotsFrequency = 376
      $0.screenshotsResolution = 1081
      $0.downtime = "22:00-08:00"
    }).withDevice()

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: "3.3.3"),
      in: child.context,
    )
    expect(output.userData.name).toBe(child.name)
    expect(output.userData.keyloggingEnabled).toBeFalse()
    expect(output.userData.screenshotsEnabled).toBeTrue()
    expect(output.userData.screenshotFrequency).toEqual(376)
    expect(output.userData.screenshotSize).toEqual(1081)
    expect(output.userData.downtime).toEqual("22:00-08:00")
    expect(output.userData.filteringDisabled).toEqual(false)

    let computer = try await self.db.find(child.computer.id)
    expect(computer.filterVersion).toEqual("3.3.3")
  }

  func testCheckIn_OtherProps() async throws {
    try await replaceAllReleases(with: [
      Release("2.0.3", channel: .stable),
      Release("2.0.4", channel: .stable),
      Release("3.0.0", channel: .beta),
    ])

    let child = try await self.child().withDevice(computer: {
      $0.appReleaseChannel = .beta
    })
    _ = try? await self.db.create(BillingIdentity(parentId: child.parentId))
    try await self.db.create(StripeSubscription(
      parentId: child.parentId,
      tier: .full,
      stripeId: .init("sub_123"),
      stripeStatus: .pastDue, // <-- needs attention
      currentPeriodEnd: .reference + .days(28),
    ))

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context,
    )

    expect(output.adminAccountStatus).toEqual(.needsAttention)
    expect(output.updateReleaseChannel).toEqual(.beta)
    expect(output.latestRelease.semver).toEqual("3.0.0")
  }

  func testCheckInUpdatesDeviceData() async throws {
    let child = try await self.child().withDevice {
      $0.isAdmin = nil
    } computer: {
      $0.osVersion = nil
    }

    _ = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "1.0.0",
        filterVersion: "3.3.3",
        userIsAdmin: true,
        osVersion: "14.5.0",
      ),
      in: child.context,
    )

    let computer = try await self.db.find(child.computer.id)
    expect(computer.osVersion).toEqual(Semver("14.5.0"))
    let computerUser = try await self.db.find(child.computerUser.id)
    expect(computerUser.isAdmin).toEqual(true)
  }

  func testCheckInDoesntOverwriteDeviceDataWithNil() async throws {
    let child = try await self.child().withDevice {
      $0.isAdmin = false
    } computer: {
      $0.osVersion = Semver("14.5.0")
    }

    _ = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "1.0.0",
        filterVersion: "3.3.3",
        userIsAdmin: nil, // <-- don't overwrite val in database
        osVersion: nil, // <-- don't overwrite val in database
      ),
      in: child.context,
    )

    let computer = try await self.db.find(child.computer.id)
    expect(computer.osVersion).toEqual(Semver("14.5.0"))
    let computerUser = try await self.db.find(child.computerUser.id)
    expect(computerUser.isAdmin).toEqual(false)
  }

  func testCheckIn_AppManifest() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: AppBundleId.self)
    try await self.db.delete(all: AppCategory.self)
    await clearCachedAppIdManifest()

    let app = try await self.db.create(IdentifiedApp.random)
    var id = AppBundleId.random
    id.identifiedAppId = app.id
    try await self.db.create(id)

    let child = try await self.childWithComputer()
    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context,
    )
    expect(output.appManifest.apps).toEqual([app.slug: [id.bundleId]])
  }

  func testUserWithNoKeychainsDoesNotGetAutoIncluded() async throws {
    let child = try await self.childWithComputer()
    try await self.createAutoIncludeKeychain()

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context,
    )
    expect(output.keychains).toHaveCount(0)
  }

  func testUserWithAtLeastOneKeyGetsAutoIncluded() async throws {
    let child = try await self.childWithComputer()
    let parent = try await self.parent().withKeychain()
    try await self.db.create(ChildKeychain(childId: child.id, keychainId: parent.keychain.id))
    let (_, autoKey) = try await createAutoIncludeKeychain()

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context,
    )
    expect(output.keys.contains(.init(id: autoKey.id.rawValue, key: autoKey.key))).toBeTrue()
  }

  func testIncludesResolvedFilterSuspension() async throws {
    let child = try await self.childWithComputer()
    let susp = try await self.db.create(MacApp.SuspendFilterRequest.mock {
      $0.computerUserId = child.computerUser.id
      $0.status = .accepted
      $0.duration = 777
      $0.extraMonitoring = "@55+k"
      $0.responseComment = "susp2 response comment"
    })

    let output = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "1.0.0",
        filterVersion: nil,
        pendingFilterSuspension: susp.id.rawValue,
      ),
      in: child.context,
    )

    expect(output.resolvedFilterSuspension).toEqual(.init(
      id: susp.id.rawValue,
      decision: .accepted(
        duration: 777,
        extraMonitoring: .addKeyloggingAndSetScreenshotFreq(55),
      ),
      comment: "susp2 response comment",
    ))

    let notRequested = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context,
    )
    expect(notRequested.resolvedFilterSuspension).toBeNil()
  }

  func testDoesNotIncludeUnresolvedSuspension() async throws {
    let child = try await self.childWithComputer()
    let susp = try await self.db.create(MacApp.SuspendFilterRequest.mock {
      $0.computerUserId = child.computerUser.id
      $0.status = .pending // <-- still pending!
    })

    let output = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "1.0.0",
        filterVersion: nil,
        pendingFilterSuspension: susp.id.rawValue,
      ),
      in: child.context,
    )

    expect(output.resolvedFilterSuspension).toBeNil()
  }

  func testIncludesResolvedUnlockRequests() async throws {
    let child = try await self.childWithComputer()
    let unlock1 = UnlockRequest.mock {
      $0.computerUserId = child.computerUser.id
      $0.status = .pending // <-- pending, will not be returned
    }

    let unlock2 = UnlockRequest.mock {
      $0.computerUserId = child.computerUser.id
      $0.status = .accepted // <-- resolved, will be returned
      $0.responseComment = "unlock2 response comment"
    }

    let unlock3 = UnlockRequest.mock {
      $0.computerUserId = child.computerUser.id
      $0.status = .rejected // <-- resolved, but not requested, not returned
    }

    try await self.db.create([unlock1, unlock2, unlock3])

    let output = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "1.0.0",
        filterVersion: nil,
        pendingUnlockRequests: [unlock1.id.rawValue, unlock2.id.rawValue],
      ),
      in: child.context,
    )

    expect(output.resolvedUnlockRequests).toEqual(
      [.init(
        id: unlock2.id.rawValue,
        status: .accepted,
        target: "",
        comment: "unlock2 response comment",
      )],
    )

    let notRequested = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context,
    )
    expect(notRequested.resolvedUnlockRequests).toBeNil()
  }

  func testScreentimeConflictDetectedTrue_SendsEmailAndCreatesAnnouncement() async throws {
    let child = try await self.childWithComputer()

    _ = try await CheckIn_v2.resolve(
      with: .init(appVersion: "2.8.0", filterVersion: nil, screentimeConflictDetected: true),
      in: child.context,
    )

    expect(self.sent.emails.count).toEqual(1)
    expect(self.sent.emails[0].template).toEqual("screen-time-warning")
    expect(self.sent.emails[0].to).toEqual(child.parent.model.email.rawValue)

    let announcements = try await DashAnnouncement.query()
      .where(.parentId == child.parent.model.id)
      .all(in: self.db)
    expect(announcements.count).toEqual(1)
    expect(announcements[0].kind).toEqual(DashAnnouncement.Kind.warning)

    let proactiveEvents = try await InterestingEvent.query()
      .where(.eventId == "3c86deaa")
      .where(.computerUserId == child.computerUser.id)
      .all(in: self.db)
    expect(proactiveEvents.count).toEqual(1)

    _ = try await CheckIn_v2.resolve(
      with: .init(appVersion: "2.8.0", filterVersion: nil, screentimeConflictDetected: true),
      in: child.context,
    )

    expect(self.sent.emails.count).toEqual(1)
  }

  func testScreentimeConflictDetectedFalse_ClearsAnnouncement() async throws {
    let child = try await self.childWithComputer()
    try await self.db.create(DashAnnouncement(
      parentId: child.parent.model.id,
      kind: .warning,
      html: "Screen Time warning",
    ))

    let before = try await DashAnnouncement.query()
      .where(.parentId == child.parent.model.id)
      .all(in: self.db)
    expect(before.count).toEqual(1)

    _ = try await CheckIn_v2.resolve(
      with: .init(appVersion: "2.8.0", filterVersion: nil, screentimeConflictDetected: false),
      in: child.context,
    )

    let after = try await DashAnnouncement.query()
      .where(.parentId == child.parent.model.id)
      .all(in: self.db)
    expect(after.count).toEqual(0)
  }

  func testAdminAccountStatus_FullPaid_IsActive() async throws {
    let child = try await self.child().withDevice()
    _ = try? await self.db.create(BillingIdentity(parentId: child.parentId))
    try await self.db.create(StripeSubscription(
      parentId: child.parentId,
      tier: .full,
      stripeId: .init("sub_123"),
      stripeStatus: .active,
      currentPeriodEnd: .reference + .days(30),
    ))

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context,
    )
    expect(output.adminAccountStatus).toEqual(.active)
  }

  func testAdminAccountStatus_StandaloneTrial_IsActive() async throws {
    let child = try await self.child().withDevice()
    try await self.db.create(BillingIdentity(
      parentId: child.parentId,
      fullTrialStartedAt: .reference,
    ))

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context,
    )
    expect(output.adminAccountStatus).toEqual(.active)
  }

  func testAdminAccountStatus_FullComplimentary_IsActive() async throws {
    let child = try await self.child().withDevice()
    try await self.db.create(BillingIdentity(
      parentId: child.parentId,
      isComplimentary: true,
    ))

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context,
    )
    expect(output.adminAccountStatus).toEqual(.active)
  }

  func testAlwaysBlocked_IncludesCloudflareEchRuleWhenChildHasNoAbRules() async throws {
    let child = try await self.child().withDevice()

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context,
    )

    expect(output.alwaysBlocked).toEqual([
      .hostnameOrSubdomain(value: "cloudflare-ech.com"),
    ])
  }

  func testAlwaysBlocked_AppendsCloudflareEchRuleWhenNonEmpty() async throws {
    let child = try await self.child().withDevice()

    try await self.db.create(ChildAlwaysBlockedRule(
      childId: child.model.id,
      rule: .hostnameEquals(value: "example.com"),
    ))

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context,
    )

    expect(output.alwaysBlocked).toEqual([
      .hostnameEquals(value: "example.com"),
      .hostnameOrSubdomain(value: "cloudflare-ech.com"),
    ])
  }

  func testAlwaysBlocked_OmitsCloudflareEchRuleForFilteringDisabledChild() async throws {
    let child = try await self.child(with: {
      $0.filteringDisabled = true
    }).withDevice()

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context,
    )

    expect(output.alwaysBlocked).toBeNil()
  }

  func testAlwaysBlocked_FilteringDisabledChildGetsAbRulesButNoCloudflareEch() async throws {
    let child = try await self.child(with: {
      $0.filteringDisabled = true
    }).withDevice()

    try await self.db.create(ChildAlwaysBlockedRule(
      childId: child.model.id,
      rule: .hostnameEquals(value: "example.com"),
    ))

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context,
    )

    expect(output.alwaysBlocked).toEqual([
      .hostnameEquals(value: "example.com"),
    ])
  }

  func testCheckIn_OldAppVersion_FiltersLegacyIncompatibleRegexKeys() async throws {
    let child = try await self.childWithComputer()
    let parent = try await self.parent().withKeychain { _, key in
      key.key = .domainRegex(pattern: .init("*.edu"), scope: .unrestricted)
    }
    try await self.db.create(ChildKeychain(childId: child.id, keychainId: parent.keychain.id))
    let incompatible = try await self.db.create(Key(
      keychainId: parent.keychain.id,
      key: .domainRegex(pattern: .init("^(harvard|mit)\\.edu$"), scope: .unrestricted),
    ))
    let domainKey = try await self.db.create(Key(
      keychainId: parent.keychain.id,
      key: .domain(domain: .init("example.com")!, scope: .unrestricted),
    ))

    let oldOutput = try await CheckIn_v2.resolve(
      with: .init(appVersion: "2.9.2", filterVersion: nil),
      in: child.context,
    )
    let oldKeyIds = Set(oldOutput.keys.map(\.id))
    expect(oldKeyIds.contains(parent.key.id.rawValue)).toBeTrue()
    expect(oldKeyIds.contains(domainKey.id.rawValue)).toBeTrue()
    expect(oldKeyIds.contains(incompatible.id.rawValue)).toBeFalse()
  }

  func testCheckIn_NewAppVersion_PreservesAllRegexKeys() async throws {
    let child = try await self.childWithComputer()
    let parent = try await self.parent().withKeychain { _, key in
      key.key = .domainRegex(pattern: .init("*.edu"), scope: .unrestricted)
    }
    try await self.db.create(ChildKeychain(childId: child.id, keychainId: parent.keychain.id))
    let realRegex = try await self.db.create(Key(
      keychainId: parent.keychain.id,
      key: .domainRegex(pattern: .init("^(harvard|mit)\\.edu$"), scope: .unrestricted),
    ))

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "2.9.3", filterVersion: nil),
      in: child.context,
    )

    let keyIds = Set(output.keys.map(\.id))
    expect(keyIds.contains(parent.key.id.rawValue)).toBeTrue()
    expect(keyIds.contains(realRegex.id.rawValue)).toBeTrue()
  }

  func testCheckIn_OldAppVersion_NeverFiltersNonRegexKeys() async throws {
    let child = try await self.childWithComputer()
    let parent = try await self.parent().withKeychain { _, key in
      key.key = .domain(domain: .init("example.com")!, scope: .unrestricted)
    }
    try await self.db.create(ChildKeychain(childId: child.id, keychainId: parent.keychain.id))
    let anySub = try await self.db.create(Key(
      keychainId: parent.keychain.id,
      key: .anySubdomain(domain: .init("example.org")!, scope: .unrestricted),
    ))
    let path = try await self.db.create(Key(
      keychainId: parent.keychain.id,
      key: .path(path: .init("foo.com/bar")!, scope: .unrestricted),
    ))
    let ip = try await self.db.create(Key(
      keychainId: parent.keychain.id,
      key: .ipAddress(ipAddress: .init("1.2.3.4")!, scope: .unrestricted),
    ))
    let skel = try await self.db.create(Key(
      keychainId: parent.keychain.id,
      key: .skeleton(scope: .bundleId("com.example")),
    ))

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context,
    )

    let keyIds = Set(output.keys.map(\.id))
    let expectedIds: Set<UUID> = [
      parent.key.id.rawValue,
      anySub.id.rawValue,
      path.id.rawValue,
      ip.id.rawValue,
      skel.id.rawValue,
    ]
    expect(keyIds.isSuperset(of: expectedIds)).toBeTrue()
  }

  func testAdminAccountStatus_FullTrialGrace_IsNeedsAttention() async throws {
    let child = try await self.child().withDevice()
    try await self.db.create(BillingIdentity(
      parentId: child.parentId,
      fullTrialStartedAt: .reference - .days(25),
    ))

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context,
    )
    expect(output.adminAccountStatus).toEqual(.needsAttention)
  }
}

extension CheckIn_v2.Output {
  var keys: [RuleKey] {
    self.keychains.flatMap(\.keys)
  }
}
