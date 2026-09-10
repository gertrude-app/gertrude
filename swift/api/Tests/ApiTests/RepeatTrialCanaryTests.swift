import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class RepeatTrialCanaryTests: ApiTestCase, @unchecked Sendable {
  func testRecentlyDeletedTrialDeviceReclaimSendsAlert() async throws {
    let originalChild = try await self.child()
    let originalMusic = try await self.musicContext(for: originalChild)
    let device = originalMusic.device
    _ = try await DeleteEntity_v2.resolve(
      with: .init(id: originalChild.id.rawValue, type: .child),
      in: originalChild.parent.context,
    )
    var snapshot = try await DeletedEntity.query()
      .where(.type == RepeatTrialCanary.snapshotType)
      .first(in: self.db)
    try await snapshot.modifyCreatedAt(.exact(.reference - .days(2)))

    let code = uniqueClaimCode()
    try await self.db.create(IOSDevice(
      id: device.id,
      modelIdentifier: device.modelIdentifier,
      iosVersion: device.iosVersion,
    ))
    try await self.createClaim(.music, device.id, code: code)
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.1.0"))
    let newParent = try await self.parent()
    let sentAlertCount = LockIsolated(0)

    try await withDependencies {
      $0.env = .prodMode
      $0.postmark._sendEmail = { _ in
        sentAlertCount.withValue { $0 += 1 }
        return .success(())
      }
    } operation: {
      _ = try await ClaimMusicDevice.resolve(
        with: .init(code: code, child: .newChild(name: "New child")),
        in: newParent.context,
      )
      await Task.megaYield()
    }

    expect(sentAlertCount.value).toEqual(1)
  }
}
