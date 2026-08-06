import Dependencies
import DuetSQL
import PairQL
import XCTest
import XExpect

@testable import Api

final class CrossAppClaimTests: ApiTestCase, @unchecked Sendable {
  func testMusicClaimAfterBlockerConnectSetsClaimedAt() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    try await self.addPaidSubscription(for: parent.id, tier: .medium)
    var device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(.music, device.id)
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))
    try await device.bindChild(child, in: self.db)

    let bound = try await Claim.find(code: claim.code, in: self.db)
    expect(bound?.claimedAt).toBeNil()

    _ = try await ClaimMusicDevice.resolve(
      with: .init(code: claim.code, child: .newChild(name: "Ignored")),
      in: parent.context,
    )

    let claimed = try await self.db.find(device.id)
    expect(claimed.childId).toEqual(child.id)
    let claimedClaim = try await Claim.find(code: claim.code, in: self.db)
    expect(claimedClaim?.claimedAt).not.toBeNil()

    let children = try await Child.query()
      .where(.parentId == parent.id)
      .all(in: self.db)
    expect(children).toHaveCount(1)
  }

  func testMusicClaimAfterBlockerConnectCompletesClaimRow() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    try await self.addPaidSubscription(for: parent.id, tier: .medium)
    let code = Int.random(in: 100_000 ... 999_999)
    var device = try await self.db.create(IOSDevice.random)
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))
    try await self.db.create(Claim(
      code: code,
      intent: .music,
      deviceId: device.id,
      expiresAt: .reference + .days(7),
    ))
    try await device.bindChild(child, in: self.db) // childId set, claimedAt nil → resume path

    let pending = try await Claim.find(code: code, in: self.db)
    expect(pending?.claimedAt).toBeNil()

    let output = try await ClaimMusicDevice.resolve(
      with: .init(code: code, child: .newChild(name: "Ignored")),
      in: parent.context,
    )

    expect(output.childName).toEqual(child.name)
    let completed = try await Claim
      .find(code: code, in: self.db) // resume path must complete the claim
    expect(completed?.claimedAt).not.toBeNil()
    expect(completed?.childId).toEqual(child.id)
    let children = try await Child.query()
      .where(.parentId == parent.id)
      .all(in: self.db)
    expect(children).toHaveCount(1)
  }

  func testMusicClaimAfterBlockerConnectWithoutAccessSetsClaimedAt() async throws {
    let parent = try await self.parent() // no subscription, no music entitlement
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    var device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(.music, device.id)
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))
    try await device.bindChild(child, in: self.db)

    let output = try await ClaimMusicDevice.resolve(
      with: .init(code: claim.code, child: .newChild(name: "Ignored")),
      in: parent.context,
    )

    expect(output.childName).toEqual(child.name) // bound child wins over the input name
    let updatedClaim = try await Claim.find(code: claim.code, in: self.db)
    expect(updatedClaim?.claimedAt).not.toBeNil()
  }

  func testCodeReuse_amClaimedCode_rejectedInBlockerFunnel() async throws {
    // an AM code is intent-specific: once claimed via AM, the blocker funnel rejects it
    // rather than resuming cross-app (the legacy shared-code fallback is gone, #737)
    let parent = try await self.parent()
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice.random)
    try await self.createClaim(.podcasts, device.id, code: code)
    try await self.db.create(PodcastApp.Install(deviceId: device.id, appVersion: "1.6.0"))

    _ = try await ClaimAmDevice.resolve(
      with: .init(code: code, child: .newChild(name: "Luke")),
      in: parent.context,
    )

    let claimedClaim = try await Claim.find(code: code, in: self.db) // AM claim completed
    expect(claimedClaim?.claimedAt).not.toBeNil()

    // the blocker supervision funnel rejects the AM code (#737)
    try await expectErrorFrom {
      try await GetIOSDeviceClaimData.resolve(with: .init(code: code), in: parent.context)
    }.toContain("Gertrude Podcasts")
  }

  func testClaimCode_rejectedInWrongAppFunnel() async throws {
    let parent = try await self.parent()
    let amCode = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice.random)
    try await self.db.create(PodcastApp.Install(deviceId: device.id, appVersion: "1.6.0"))
    try await self.db.create(Claim(
      code: amCode,
      intent: .podcasts,
      deviceId: device.id,
      expiresAt: .reference + .days(7),
    ))

    // the AM funnel accepts its own code
    let amData = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await GetAmClaimData.resolve(with: .init(code: amCode), in: parent.context)
    }
    expect(amData.resumeStep).toBeNil() // unclaimed → child picker

    // the blocker supervision funnel rejects the AM code (#737)
    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await GetIOSDeviceClaimData.resolve(with: .init(code: amCode), in: parent.context)
      }
    }.toContain("Gertrude Podcasts")
  }

  func testMusicCode_rejectedInBlockerConnectFunnel() async throws {
    let parent = try await self.parent()
    let musicCode = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice.random)
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))
    try await self.db.create(Claim(
      code: musicCode,
      intent: .music,
      deviceId: device.id,
      expiresAt: .reference + .days(7),
    ))

    // the blocker connect funnel rejects the music code (#737)
    try await expectErrorFrom {
      try await GetBlockerClaimData.resolve(with: .init(code: musicCode), in: parent.context)
    }.toContain("Gertrude Music")
  }
}
