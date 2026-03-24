import Dependencies
import DuetSQL
import IOSRoute
import PairQL
import XCTest
import XExpect

@testable import Api

final class SelfReportSupervisionResolverTests: ApiTestCase, @unchecked Sendable {
  func testReportsSupervised_setsSupervisedAt() async throws {
    let child = try await self.childWithIOSDevice()
    try await self.db.create(Subscription(
      parentId: child.parent.model.id,
      tier: .light,
      billingStatus: .paid,
      stripeId: .init("sub_test"),
      statusExpiresAt: .distantFuture,
    ))
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

  func testReportsSupervised_blockedWithoutEligiblePlan() async throws {
    let child = try await self.childWithIOSDevice()
    try await self.db.create(Subscription(
      parentId: child.parent.model.id,
      tier: .full,
      billingStatus: .trialing,
      trialStartedAt: .reference,
      statusExpiresAt: .reference + .days(18),
    ))
    let supervisedAt = Date.reference - .days(1)
    try await self.db.create(IOSApp.Supervision(
      deviceId: child.device.id,
      claimCode: .random(in: 100_000 ... 999_999),
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: .reference,
      supervisedAt: supervisedAt,
    ))

    do {
      _ = try await SelfReportSupervision.resolve(
        with: .init(isSupervised: true),
        in: child.context,
      )
      XCTFail("expected error not thrown")
    } catch let error as PqlError {
      expect(error.type).toEqual(.paymentRequired)
    }

    let supervision = try await child.device.supervision(in: self.db)!
    expect(supervision.supervisedAt).toEqual(supervisedAt)

    let events = try await IOSEvent.query()
      .where(.deviceId == child.device.id)
      .all(in: self.db)
    expect(events).toHaveCount(0)
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
