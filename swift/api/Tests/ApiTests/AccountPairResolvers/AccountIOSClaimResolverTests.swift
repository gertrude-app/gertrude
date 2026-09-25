import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class AccountIOSClaimResolverTests: ApiTestCase, @unchecked Sendable {
  func testBlockerConnect_claimsForExistingPersonAndSeedsGroups() async throws {
    let parent = try await self.parent()
    let person = try await self.db.create(Child(parentId: parent.id, name: "Jude"))
    let device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(.blockerConnect, device.id)

    let output = try await ClaimAccountIOSDevice.resolve(
      with: .init(flow: .blockerConnect, code: claim.code, person: .existing(id: person.id)),
      in: self.accountContext(parent),
    )

    expect(output.assignment?.personId).toEqual(person.id)
    expect(output.assignment?.deviceId).toEqual(device.id)
    expect(output.modelIdentifier).toEqual(device.modelIdentifier)
    await expect(try (self.db.find(device.id) as IOSDevice).childId).toEqual(person.id)
    await expect(try (Claim.find(code: claim.code, in: self.db))?.claimedAt).not.toBeNil()
    let groups = try await BlockerApp.DeviceBlockGroup.query()
      .where(.deviceId == device.id)
      .all(in: self.db)
    expect(groups.isEmpty).toBeFalse()
  }

  func testNewPersonUsesSelectedRelationshipAndDoesNotDuplicateOnResume() async throws {
    let parent = try await self.parent()
    let device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(.blockerConnect, device.id)
    let context = self.accountContext(parent)
    let input = ClaimAccountIOSDevice.Input(
      flow: .blockerConnect,
      code: claim.code,
      person: .new(name: "  Jamie  ", relationship: .peer),
    )

    let first = try await ClaimAccountIOSDevice.resolve(with: input, in: context)
    let second = try await ClaimAccountIOSDevice.resolve(with: input, in: context)

    expect(second.assignment?.personId).toEqual(first.assignment?.personId)
    let people = try await context.people()
    expect(people.count).toEqual(1)
    expect(people.first?.name).toEqual("Jamie")
    expect(people.first?.relationship).toEqual(.peer)
  }

  func testNewPersonRollsBackWhenCodeIsExpired() async throws {
    let parent = try await self.parent()
    let device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(
      .blockerConnect,
      device.id,
      expiresAt: .reference - .days(1),
    )

    try await expectErrorFrom {
      try await ClaimAccountIOSDevice.resolve(
        with: .init(
          flow: .blockerConnect,
          code: claim.code,
          person: .new(name: "Jamie", relationship: .child),
        ),
        in: self.accountContext(parent),
      )
    }.toContain("expired")
    await expect(try self.accountContext(parent).people()).toBeEmpty()
  }

  func testCannotClaimForPersonBelongingToAnotherAccount() async throws {
    let parent = try await self.parent()
    let other = try await self.parent()
    let person = try await self.db.create(Child(parentId: other.id, name: "Other"))
    let device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(.blockerConnect, device.id)

    try await expectErrorFrom {
      try await ClaimAccountIOSDevice.resolve(
        with: .init(flow: .blockerConnect, code: claim.code, person: .existing(id: person.id)),
        in: self.accountContext(parent),
      )
    }.toContain("notFound")
    await expect(try (self.db.find(device.id) as IOSDevice).childId).toBeNil()
  }

  func testSupervisionClaimShowsStatusAndRequiresPayment() async throws {
    let parent = try await self.parent()
    let person = try await self.db.create(Child(parentId: parent.id, name: "Jude"))
    let device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(.blockerSupervise, device.id)
    var supervision = try await self.db.create(BlockerApp.Supervision(deviceId: device.id))
    let context = self.accountContext(parent)

    let output = try await ClaimAccountIOSDevice.resolve(
      with: .init(flow: .blockerSupervise, code: claim.code, person: .existing(id: person.id)),
      in: context,
    )
    expect(output.assignment?.supervisionStatus).toEqual(.claimed)
    expect(output.assignment?.requiresPayment).toEqual(true)

    supervision.supervisedAt = .reference
    try await self.db.update(supervision)
    let resumed = try await GetAccountIOSClaimData.resolve(
      with: .init(flow: .blockerSupervise, code: claim.code), in: context,
    )
    expect(resumed.assignment?.supervisionStatus).toEqual(.supervised)
    supervision.profileInstalledAt = .reference
    try await self.db.update(supervision)
    let completed = try await GetAccountIOSClaimData.resolve(
      with: .init(flow: .blockerSupervise, code: claim.code), in: context,
    )
    expect(completed.assignment?.supervisionStatus).toEqual(.complete)
  }

  func testPodcastsAndMusicRequireInstallAndReturnEntitlement() async throws {
    let parent = try await self.parent()
    let person = try await self.db.create(Child(parentId: parent.id, name: "Jude"))
    let context = self.accountContext(parent)
    let podcastDevice = try await self.db.create(IOSDevice.random)
    let podcastClaim = try await self.createClaim(.podcasts, podcastDevice.id)
    let musicDevice = try await self.db.create(IOSDevice.random)
    let musicClaim = try await self.createClaim(.music, musicDevice.id)

    try await expectErrorFrom {
      try await GetAccountIOSClaimData.resolve(
        with: .init(flow: .music, code: musicClaim.code), in: context,
      )
    }.toContain("not set up")
    try await self.db.create(PodcastApp.Install(deviceId: podcastDevice.id, appVersion: "1.6.0"))
    try await self.db.create(MusicApp.Install(deviceId: musicDevice.id, appVersion: "1.0.0"))

    let podcast = try await ClaimAccountIOSDevice.resolve(
      with: .init(flow: .podcasts, code: podcastClaim.code, person: .existing(id: person.id)),
      in: context,
    )
    let music = try await ClaimAccountIOSDevice.resolve(
      with: .init(flow: .music, code: musicClaim.code, person: .existing(id: person.id)),
      in: context,
    )
    expect(podcast.assignment?.personId).toEqual(person.id)
    expect(podcast.assignment?.amSubscription).not.toBeNil()
    expect(music.assignment?.personId).toEqual(person.id)
    expect(music.modelIdentifier).toEqual(musicDevice.modelIdentifier)
  }

  func testWrongIntentCannotBeClaimedByDifferentFunnel() async throws {
    let parent = try await self.parent()
    let device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(.music, device.id)

    try await expectErrorFrom {
      try await ClaimAccountIOSDevice.resolve(
        with: .init(
          flow: .blockerConnect,
          code: claim.code,
          person: .new(name: "Jude", relationship: .child),
        ),
        in: self.accountContext(parent),
      )
    }.toContain("not Gertrude Blocker")
    await expect(try self.accountContext(parent).people()).toBeEmpty()
  }
}
