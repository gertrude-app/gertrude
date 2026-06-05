import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class RequestAmPinResetResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_returnsConsumableCode() async throws {
    let parent = try await self.parent()
    let (device, install) = try await self.claimedAmDevice(for: parent)

    let output = try await withDependencies {
      $0.verificationCode = .liveValue
    } operation: {
      try await RequestAmPinReset.resolve(with: .init(deviceId: device.id), in: parent.context)
    }

    expect(output.expiresAt).toEqual(.reference + .minutes(60))
    let consumed = await get(dependency: \.ephemeral).consumePinResetCode(output.code)
    expect(consumed).toEqual(install.id)
  }

  func testCrossParent_throwsUnauthorized() async throws {
    let owner = try await self.parent()
    let (device, _) = try await self.claimedAmDevice(for: owner)
    let intruder = try await self.parent()

    try await expectErrorFrom {
      try await RequestAmPinReset.resolve(with: .init(deviceId: device.id), in: intruder.context)
    }.toContain("access")
  }

  func testMultipleCalls_produceDistinctConsumableCodes() async throws {
    let parent = try await self.parent()
    let (device, install) = try await self.claimedAmDevice(for: parent)

    let (first, second) = try await withDependencies {
      $0.verificationCode = .liveValue
    } operation: {
      let first = try await RequestAmPinReset.resolve(
        with: .init(deviceId: device.id),
        in: parent.context,
      )
      let second = try await RequestAmPinReset.resolve(
        with: .init(deviceId: device.id),
        in: parent.context,
      )
      return (first, second)
    }

    expect(first.code).not.toEqual(second.code)
    let firstConsumed = await get(dependency: \.ephemeral).consumePinResetCode(first.code)
    let secondConsumed = await get(dependency: \.ephemeral).consumePinResetCode(second.code)
    expect(firstConsumed).toEqual(install.id)
    expect(secondConsumed).toEqual(install.id)
  }
}

extension RequestAmPinResetResolverTests {
  private func claimedAmDevice(
    for parent: ParentEntities,
  ) async throws -> (device: IOSDevice, install: PodcastApp.Install) {
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = child.id
      $0.claimedAt = .reference
    })
    let install = try await self.db.create(
      PodcastApp.Install(deviceId: device.id, appVersion: "1.6.0"),
    )
    return (device, install)
  }
}
