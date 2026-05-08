import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class GetChildResolverTests: ApiTestCase, @unchecked Sendable {
  func testFetchIncludingPendingDevice() async throws {
    let child = try await self.child()

    let pendingCode = 123_456
    let pendingDevice = try await self.db.create(IOSDevice.random {
      $0.childId = child.id
      $0.claimCode = pendingCode
      $0.claimCodeExpiresAt = .distantFuture
      $0.claimedAt = .reference
    })
    try await self.db.create(BlockerApp.Supervision(
      deviceId: pendingDevice.id,
      supervisedAt: nil, // <-- pending
    ))

    let completedDevice = try await self.db.create(IOSDevice.random {
      $0.childId = child.id
      $0.claimCode = 654_321
      $0.claimCodeExpiresAt = .distantFuture
      $0.claimedAt = .reference
    })
    try await self.db.create(BlockerApp.Supervision(
      deviceId: completedDevice.id,
      supervisedAt: .reference, // <-- not pending
    ))

    let output = try await withDependencies {
      $0.websockets.status = { _ in .filterOn }
    } operation: {
      try await GetChild.resolve(with: child.id, in: context(child.parent))
    }

    expect(output.name).toEqual(child.name)
    expect(output.iosDevices.count).toEqual(2)
    expect(output.iosDevices[0].id).toEqual(pendingDevice.id)
    expect(output.iosDevices[0].pendingClaimCode).toEqual(pendingCode)
    expect(output.iosDevices[1].id).toEqual(completedDevice.id)
    expect(output.iosDevices[1].pendingClaimCode).toBeNil()
  }
}
