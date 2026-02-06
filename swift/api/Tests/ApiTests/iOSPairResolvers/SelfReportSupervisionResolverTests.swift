import Dependencies
import DuetSQL
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class SelfReportSupervisionResolverTests: ApiTestCase, @unchecked Sendable {
  func testReportsSupervised_setsSupervisedAt() async throws {
    let child = try await self.childWithIOSDevice()
    try await self.db.create(IOSApp.Supervision(
      deviceId: child.device.id,
      claimCode: .random(in: 100_000 ... 999_999),
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: .reference,
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await SelfReportSupervision.resolve(
        with: .init(isSupervised: true),
        in: child.context,
      )
    }

    expect(output).toEqual(.success)

    let supervision = try await child.device.supervision(in: self.db)!
    expect(supervision.supervisedAt).toEqual(.reference)

    let events = try await IOSEvent.query()
      .where(.deviceId == child.device.id)
      .all(in: self.db)
    expect(events).toHaveCount(1)
    expect(events.first?.detail).toEqual("self_reported_supervision: was=false now=true")
  }

  func testReportsNotSupervised_clearsSupervisedAt() async throws {
    let child = try await self.childWithIOSDevice()
    try await self.db.create(IOSApp.Supervision(
      deviceId: child.device.id,
      claimCode: .random(in: 100_000 ... 999_999),
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: .reference,
      supervisedAt: .reference,
    ))

    let output = try await SelfReportSupervision.resolve(
      with: .init(isSupervised: false),
      in: child.context,
    )

    expect(output).toEqual(.success)

    let supervision = try await child.device.supervision(in: self.db)!
    expect(supervision.supervisedAt).toBeNil()

    let events = try await IOSEvent.query()
      .where(.deviceId == child.device.id)
      .all(in: self.db)
    expect(events).toHaveCount(1)
    expect(events.first?.detail).toEqual("self_reported_supervision: was=true now=false")
  }
}
