import DuetSQL
import Foundation
import PairQL
import PodcastRoute
import Vapor
import XCTest
import XExpect

@testable import Api

final class GetAccountStatusResolverTests: ApiTestCase, @unchecked Sendable {
  func claimedDevice(
    for child: ChildEntities,
  ) async throws -> (IOSDevice, PodcastApp.Install) {
    let device = try await self.db.create(IOSDevice(
      id: .init(UUID()),
      childId: child.model.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      claimedAt: .reference,
    ))
    let install = try await self.db.create(
      PodcastApp.Install(deviceId: device.id, appVersion: "1.6.0"),
    )
    return (device, install)
  }

  func resolveStatus(
    for child: ChildEntities,
  ) async throws -> GetAccountStatus.Output {
    let (device, install) = try await self.claimedDevice(for: child)
    let ctx = PodcastApp.InstallContext(
      requestId: "mock-req-id",
      dashboardUrl: "/",
      install: install,
      device: device,
      child: child.model,
      telemetry: TelemetryBag(),
    )
    return try await GetAccountStatus.resolve(in: ctx)
  }

  func testReturnsAuthedInstallChildInfo() async throws {
    let child = try await self.child()

    let output = try await self.resolveStatus(for: child)

    expect(output.childId).toEqual(child.model.id.rawValue)
    expect(output.childName).toEqual(child.model.name)
  }

  // MARK: - subscription state derivation

  func testNoBillingReturnsUnpaid() async throws {
    let child = try await self.child()

    let output = try await self.resolveStatus(for: child)

    expect(output.subscription).toEqual(.unpaid(remediationUrl: nil))
  }

  func testActivePaidSubscriptionReturnsActive() async throws {
    let child = try await self.child()
    try await self.db.create(BillingIdentity(parentId: child.parent.model.id))
    try await self.db.create(StripeSubscription(
      parentId: child.parent.model.id,
      tier: .light,
      stripeId: "sub_active",
      stripeStatus: .active,
      currentPeriodEnd: .reference + .days(30),
    ))

    let output = try await self.resolveStatus(for: child)

    expect(output.subscription).toEqual(.active(expiresAt: .reference + .days(30)))
  }

  func testComplimentaryReturnsActiveNoExpiry() async throws {
    let child = try await self.child()
    try await self.db.create(BillingIdentity(
      parentId: child.parent.model.id,
      isComplimentary: true,
    ))

    let output = try await self.resolveStatus(for: child)

    expect(output.subscription).toEqual(.active(expiresAt: nil))
  }

  func testLegacyIapWithinWindowReturnsGrandfathered() async throws {
    let paidAt = Date.reference - .days(100)
    let child = try await self.child()
    try await self.db.create(BillingIdentity(
      parentId: child.parent.model.id,
      legacyAmIapPaidAt: paidAt,
    ))

    let output = try await self.resolveStatus(for: child)

    expect(output.subscription).toEqual(.legacyGrandfathered(
      paidAt: paidAt,
      expiresAt: paidAt + .days(365),
      remediationUrl: nil,
    ))
  }

  func testLegacyIapPastWindowReturnsExpired() async throws {
    let paidAt = Date.reference - .days(400)
    let child = try await self.child()
    try await self.db.create(BillingIdentity(
      parentId: child.parent.model.id,
      legacyAmIapPaidAt: paidAt,
    ))

    let output = try await self.resolveStatus(for: child)

    expect(output.subscription).toEqual(.legacyExpired(paidAt: paidAt, remediationUrl: nil))
  }

  func testActiveSubscriptionOutranksLegacyFloor() async throws {
    let child = try await self.child()
    try await self.db.create(BillingIdentity(
      parentId: child.parent.model.id,
      legacyAmIapPaidAt: .reference - .days(400),
    ))
    try await self.db.create(StripeSubscription(
      parentId: child.parent.model.id,
      tier: .full,
      stripeId: "sub_converted",
      stripeStatus: .active,
      currentPeriodEnd: .reference + .days(30),
    ))

    let output = try await self.resolveStatus(for: child)

    expect(output.subscription).toEqual(.active(expiresAt: .reference + .days(30)))
  }

  func testFullTrialLegacyFloorExtendsExpiry() async throws {
    let trialStart = Date.reference - .days(5)
    let paidAt = Date.reference - .days(100)
    let child = try await self.child()
    try await self.db.create(BillingIdentity(
      parentId: child.parent.model.id,
      fullTrialStartedAt: trialStart,
      legacyAmIapPaidAt: paidAt,
    ))

    let output = try await self.resolveStatus(for: child)

    expect(output.subscription).toEqual(.active(expiresAt: paidAt + .days(365)))
  }

  func testFullTrialOutlastsLegacyUsesTrialExpiry() async throws {
    let trialStart = Date.reference - .days(5)
    let child = try await self.child()
    try await self.db.create(BillingIdentity(
      parentId: child.parent.model.id,
      fullTrialStartedAt: trialStart,
      legacyAmIapPaidAt: .reference - .days(360),
    ))

    let output = try await self.resolveStatus(for: child)

    expect(output.subscription).toEqual(.active(expiresAt: trialStart + .days(21)))
  }

  // MARK: - authed route plumbing

  func testAuthedRouteResolvesTokenAndReturnsAccountStatus() async throws {
    let child = try await self.child()
    let (_, install) = try await self.claimedDevice(for: child)
    let token = try await self.db.create(PodcastApp.Token(installId: install.id))

    let response = try await PairQLRoute.respond(
      to: .podcast(.authed(token.value.rawValue, .getAccountStatus)),
      in: .mock,
    )

    expect(response.status).toEqual(.ok)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let output = try decoder.decode(
      GetAccountStatus.Output.self,
      from: response.body.data!,
    )
    expect(output.childId).toEqual(child.model.id.rawValue)
    expect(output.childName).toEqual(child.model.name)
  }

  func testUnauthorizedAfterTokenRowDeleted() async throws {
    let child = try await self.child()
    let (_, install) = try await self.claimedDevice(for: child)
    let token = try await self.db.create(PodcastApp.Token(installId: install.id))
    let tokenValue = token.value.rawValue

    // simulates dashboard unclaim deleting the token row
    try await PodcastApp.Token.query()
      .where(.installId == install.id)
      .delete(in: self.db)

    do {
      _ = try await PairQLRoute.respond(
        to: .podcast(.authed(tokenValue, .getAccountStatus)),
        in: .mock,
      )
      XCTFail("expected unauthorized error after token row deleted")
    } catch let error as PqlError {
      expect(error.type).toEqual(.unauthorized)
    }
  }
}
