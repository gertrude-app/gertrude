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
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = child.id
      $0.claimCode = code
      $0.claimedAt = .reference
    })
    let install = try await self.db.create(
      PodcastApp.Install(deviceId: device.id, appVersion: "1.6.0"),
    )

    let output = try await GetAmClaimData.resolve(with: .init(code: code), in: parent.context)

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
    let code = Int.random(in: 100_000 ... 999_999)
    try await self.db.create(IOSDevice.random {
      $0.claimCode = code
      $0.claimCodeExpiresAt = .reference + .days(7)
    })

    let output = try await GetAmClaimData.resolve(with: .init(code: code), in: parent.context)

    expect(output.resumeStep).toBeNil()
    expect(output.children.map(\.id)).toEqual([child.id])
  }

  func testUnclaimedExpiredCode_throwsExpiredError() async throws {
    let parent = try await self.parent()
    let code = Int.random(in: 100_000 ... 999_999)
    try await self.db.create(IOSDevice.random {
      $0.claimCode = code
      $0.claimCodeExpiresAt = .reference - .days(1)
    })

    try await expectErrorFrom {
      try await GetAmClaimData.resolve(with: .init(code: code), in: parent.context)
    }.toContain("expired")
  }

  func testClaimedByDifferentParent_throwsCodeNotFound() async throws {
    let otherParent = try await self.parent()
    let otherChild = try await self.db.create(Child.random { $0.parentId = otherParent.id })
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = otherChild.id
      $0.claimCode = code
      $0.claimedAt = .reference
    })
    try await self.db.create(PodcastApp.Install(deviceId: device.id, appVersion: "1.6.0"))
    let parent = try await self.parent()

    try await expectErrorFrom {
      try await GetAmClaimData.resolve(with: .init(code: code), in: parent.context)
    }.toContain("not found")
  }
}
