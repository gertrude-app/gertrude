import DuetSQL
import XCTest
import XExpect

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@testable import Api

final class GetMusicClaimDataResolverTests: ApiTestCase, @unchecked Sendable {
  func testRouteMatches() throws {
    let token = UUID()
    let input = GetMusicClaimData.Input(code: 123_456)
    var request = URLRequest(url: URL(string: "dashboard/GetMusicClaimData")!)
    request.httpMethod = "POST"
    request.addValue(token.uuidString, forHTTPHeaderField: "X-AdminToken")
    request.httpBody = try JSONEncoder().encode(input)

    let matched = try PairQLRoute.router.match(request: request)

    expect(matched).toEqual(.dashboard(.adminAuthed(token, .getMusicClaimData(input))))
  }

  func testResumeClaimedBySameParentReturnsDone() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = child.id
      $0.claimCode = code
      $0.claimedAt = .reference
    })
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))

    let output = try await GetMusicClaimData.resolve(with: .init(code: code), in: parent.context)

    expect(output.children).toEqual([])
    expect(output.modelName).toEqual(device.modelName)
    expect(output.iosVersion).toEqual(device.iosVersion)
    expect(output.resumeStep).toEqual(.done(childName: child.name))
  }

  func testUnclaimedValidCodeReturnsChildrenAndNoResumeStep() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice.random {
      $0.claimCode = code
      $0.claimCodeExpiresAt = .reference + .days(7)
    })
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))

    let output = try await GetMusicClaimData.resolve(with: .init(code: code), in: parent.context)

    expect(output.resumeStep).toBeNil()
    expect(output.children.map(\.id)).toEqual([child.id])
    expect(output.modelName).toEqual(device.modelName)
  }

  func testUnclaimedWithoutMusicInstallThrowsNotFound() async throws {
    let parent = try await self.parent()
    let code = Int.random(in: 100_000 ... 999_999)
    try await self.db.create(IOSDevice.random {
      $0.claimCode = code
      $0.claimCodeExpiresAt = .reference + .days(7)
    })

    try await expectErrorFrom {
      try await GetMusicClaimData.resolve(with: .init(code: code), in: parent.context)
    }.toContain("not found")
  }

  func testClaimedByDifferentParentThrowsCodeNotFound() async throws {
    let otherParent = try await self.parent()
    let otherChild = try await self.db.create(Child.random { $0.parentId = otherParent.id })
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = otherChild.id
      $0.claimCode = code
      $0.claimedAt = .reference
    })
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))
    let parent = try await self.parent()

    try await expectErrorFrom {
      try await GetMusicClaimData.resolve(with: .init(code: code), in: parent.context)
    }.toContain("not found")
  }
}
