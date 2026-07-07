import Dependencies
import DuetSQL
import PodcastRoute
import XCTest
import XExpect

@testable import Api

final class GetAmClaimDataResolverTests: ApiTestCase, @unchecked Sendable {
  func testResume_claimedBySameParent_returnsDoneWithSubscription() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let claim = try await self.createClaim(.podcasts, device.id, child.id, claimedAt: .reference)
    let install = try await self.db.create(
      PodcastApp.Install(deviceId: device.id, appVersion: "1.6.0"),
    )

    let output = try await GetAmClaimData.resolve(with: .init(code: claim.code), in: parent.context)

    expect(output.children).toEqual([])
    let persisted = try await self.db.find(install.id)
    expect(output.resumeStep).toEqual(.done(
      amSubscription: .amTrial(expiresAt: persisted.createdAt + .days(30)),
      childName: child.name,
    ))
  }

  func testUnclaimedValidCode_returnsChildrenAndNoResumeStep() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(.podcasts, device.id)

    let output = try await GetAmClaimData.resolve(with: .init(code: claim.code), in: parent.context)

    expect(output.resumeStep).toBeNil()
    expect(output.children.map(\.id)).toEqual([child.id])
  }

  func testUnclaimedAlreadyBoundCode_completesClaimAndReturnsDoneWithSubscription() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let claim = try await self.createClaim(.podcasts, device.id)
    let install = try await self.db.create(
      PodcastApp.Install(deviceId: device.id, appVersion: "1.6.0"),
    )

    let output = try await GetAmClaimData.resolve(with: .init(code: claim.code), in: parent.context)

    expect(output.children).toEqual([])
    let persisted = try await self.db.find(install.id)
    expect(output.resumeStep).toEqual(.done(
      amSubscription: .amTrial(expiresAt: persisted.createdAt + .days(30)),
      childName: child.name,
    ))
    let completed = try await Claim.find(code: claim.code, in: self.db)
    expect(completed?.childId).toEqual(child.id)
    expect(completed?.claimedAt).not.toBeNil()
  }

  func testUnclaimedExpiredCode_throwsExpiredError() async throws {
    let parent = try await self.parent()
    let device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(.podcasts, device.id, expiresAt: .reference - .days(1))

    try await expectErrorFrom {
      try await GetAmClaimData.resolve(with: .init(code: claim.code), in: parent.context)
    }.toContain("expired")
  }

  func testClaimedByDifferentParent_throwsCodeNotFound() async throws {
    let otherParent = try await self.parent()
    let otherChild = try await self.db.create(Child.random { $0.parentId = otherParent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = otherChild.id })
    let claim = try await self.createClaim(
      .podcasts,
      device.id,
      otherChild.id,
      claimedAt: .reference,
    )
    try await self.db.create(PodcastApp.Install(deviceId: device.id, appVersion: "1.6.0"))
    let parent = try await self.parent()

    try await expectErrorFrom {
      try await GetAmClaimData.resolve(with: .init(code: claim.code), in: parent.context)
    }.toContain("not found")
  }
}
