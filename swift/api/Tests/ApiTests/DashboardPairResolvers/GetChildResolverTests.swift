import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class GetChildResolverTests: ApiTestCase, @unchecked Sendable {
  func testFetchIncludingPendingDevice() async throws {
    let child = try await self.child()

    let pendingCode = Int.random(in: 100_000 ... 999_999)
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
      $0.claimCode = Int.random(in: 100_000 ... 999_999)
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
    expect(output.iosDevices[0].musicConnected).toEqual(false)
    expect(output.iosDevices[1].id).toEqual(completedDevice.id)
    expect(output.iosDevices[1].pendingClaimCode).toBeNil()
    expect(output.iosDevices[1].musicConnected).toEqual(false)
  }

  func testAbandonedSupervisionCodeAfterScreenTimeConnectDoesNotNag() async throws {
    let child = try await self.child()

    let familyConnectedDevice = try await self.db.create(IOSDevice.random {
      $0.childId = child.id // <-- connected, must have been thru post screen-time offer
      $0.claimCode = Int
        .random(in: 100_000 ... 999_999) // <-- has a claim code from abaondoned supervision attempt
      $0.claimCodeExpiresAt = .reference - .days(7)
      $0.claimedAt = nil
    })
    try await self.db.create(BlockerApp.Supervision(
      deviceId: familyConnectedDevice.id,
      supervisedAt: nil,
    ))

    let output = try await withDependencies {
      $0.websockets.status = { _ in .filterOn }
    } operation: {
      try await GetChild.resolve(with: child.id, in: context(child.parent))
    }

    expect(output.iosDevices.count).toEqual(1)
    expect(output.iosDevices[0].id).toEqual(familyConnectedDevice.id)
    expect(output.iosDevices[0].pendingClaimCode).toBeNil() // <-- so they don't get nagged
    expect(output.iosDevices[0].musicConnected).toEqual(false)
  }

  func testFetchMarksMusicConnectedDevices() async throws {
    let child = try await self.child()
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = child.id
      $0.claimedAt = .reference
    })
    let install = try await self.db.create(
      MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"),
    )
    try await self.db.create(MusicApp.Token(installId: install.id))

    let output = try await withDependencies {
      $0.websockets.status = { _ in .filterOn }
    } operation: {
      try await GetChild.resolve(with: child.id, in: context(child.parent))
    }

    expect(output.iosDevices.count).toEqual(1)
    expect(output.iosDevices[0].id).toEqual(device.id)
    expect(output.iosDevices[0].musicConnected).toEqual(true)
  }
}
