import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class GetChildResolverTests: ApiTestCase, @unchecked Sendable {
  func testFetchIncludingPendingDevice() async throws {
    let child = try await self.child()

    let pendingDevice = try await self.db.create(IOSApp.Device.random {
      $0.childId = child.id
    })
    let pendingCode = 123_456
    try await self.db.create(IOSApp.Supervision(
      deviceId: pendingDevice.id,
      claimCode: pendingCode,
      claimCodeExpiresAt: .distantFuture,
      claimedAt: .reference,
      supervisedAt: nil, // <-- pending
    ))

    let completedDevice = try await self.db.create(IOSApp.Device.random {
      $0.childId = child.id
    })
    try await self.db.create(IOSApp.Supervision(
      deviceId: completedDevice.id,
      claimCode: 654_321,
      claimCodeExpiresAt: .distantFuture,
      claimedAt: .reference,
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
