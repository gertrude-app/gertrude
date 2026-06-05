import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class CrossAppClaimTests: ApiTestCase, @unchecked Sendable {
  func testCodeReuse_amClaimFirst_blockerFunnelResumesAndHealsBlockGroups() async throws {
    let parent = try await self.parent()
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice.random {
      $0.claimCode = code
      $0.claimCodeExpiresAt = .reference + .days(7)
    })
    try await self.db.create(PodcastApp.Install(deviceId: device.id, appVersion: "1.6.0"))
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    _ = try await ClaimAmDevice.resolve(
      with: .init(code: code, child: .newChild(name: "Luke")),
      in: parent.context,
    )

    let claimed = try await self.db.find(device.id)
    expect(claimed.childId).not.toBeNil()
    expect(claimed.claimedAt).not.toBeNil()

    let before = try await BlockerApp.DeviceBlockGroup.query()
      .where(.deviceId == device.id)
      .all(in: self.db)
    expect(before.isEmpty).toBeTrue()

    let blockerData = try await GetIOSDeviceClaimData.resolve(
      with: .init(code: code),
      in: parent.context,
    )
    expect(blockerData.resumeStep).not.toBeNil()

    let after = try await BlockerApp.DeviceBlockGroup.query()
      .where(.deviceId == device.id)
      .all(in: self.db)
    expect(after.isEmpty).toBeFalse()

    let amData = try await GetAmClaimData.resolve(with: .init(code: code), in: parent.context)
    guard case .done = amData.resumeStep else {
      return XCTFail("expected AM resumeStep .done, got \(String(describing: amData.resumeStep))")
    }
  }
}
