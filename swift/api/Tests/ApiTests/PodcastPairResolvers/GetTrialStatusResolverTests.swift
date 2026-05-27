import Dependencies
import DuetSQL
import Foundation
import PodcastRoute
import XCTest
import XExpect

@testable import Api

final class GetTrialStatusResolverTests: ApiTestCase, @unchecked Sendable {
  func input(
    _ deviceId: UUID,
    appVersion: String = "1.6.0",
  ) -> GetTrialStatus.Input {
    .init(
      deviceId: deviceId,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      appVersion: appVersion,
    )
  }

  // MARK: - install creation / idempotency

  func testFreshDeviceCreatesDeviceAndInstallAndReturnsTrial() async throws {
    let deviceId = UUID()

    let output = try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)

    guard case .trial = output else {
      return XCTFail("expected .trial, got \(output)")
    }
    let device = try await self.db.find(IOSDevice.Id(deviceId))
    expect(device.claimedAt).toBeNil()
    let install = try await PodcastApp.Install.query()
      .where(.deviceId == device.id)
      .first(in: self.db)
    expect(install.appVersion).toEqual("1.6.0")
  }

  func testIdempotentPreservesInstallCreatedAt() async throws {
    let deviceId = UUID()

    _ = try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)
    let first = try await PodcastApp.Install.query()
      .where(.deviceId == IOSDevice.Id(deviceId))
      .first(in: self.db)

    _ = try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)
    let installs = try await PodcastApp.Install.query()
      .where(.deviceId == IOSDevice.Id(deviceId))
      .all(in: self.db)

    expect(installs.count).toEqual(1)
    expect(installs[0].createdAt).toEqual(first.createdAt)
  }

  // MARK: - trial window (createdAt + 30d vs now)

  func testActiveTrialReturnsExpiresAt() async throws {
    let deviceId = UUID()
    try await self.db.create(IOSDevice(
      id: .init(deviceId),
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    try await self.db.create(PodcastApp.Install(deviceId: .init(deviceId), appVersion: "1.6.0"))
    let install = try await PodcastApp.Install.query()
      .where(.deviceId == IOSDevice.Id(deviceId))
      .first(in: self.db)

    let output = try await withDependencies {
      $0.date = .constant(install.createdAt + .days(25))
    } operation: {
      try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)
    }

    expect(output).toEqual(.trial(expiresAt: install.createdAt + .days(30)))
  }

  func testTrialExpiredPastWindow() async throws {
    let deviceId = UUID()
    try await self.db.create(IOSDevice(
      id: .init(deviceId),
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    try await self.db.create(PodcastApp.Install(deviceId: .init(deviceId), appVersion: "1.6.0"))
    let install = try await PodcastApp.Install.query()
      .where(.deviceId == IOSDevice.Id(deviceId))
      .first(in: self.db)

    let output = try await withDependencies {
      $0.date = .constant(install.createdAt + .days(31))
    } operation: {
      try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)
    }

    expect(output).toEqual(.trialExpired(since: install.createdAt + .days(30)))
  }

  func testTrialBoundaryAtExactly30DaysIsExpired() async throws {
    let deviceId = UUID()
    try await self.db.create(IOSDevice(
      id: .init(deviceId),
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    try await self.db.create(PodcastApp.Install(deviceId: .init(deviceId), appVersion: "1.6.0"))
    let install = try await PodcastApp.Install.query()
      .where(.deviceId == IOSDevice.Id(deviceId))
      .first(in: self.db)

    let output = try await withDependencies {
      $0.date = .constant(install.createdAt + .days(30))
    } operation: {
      try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)
    }

    expect(output).toEqual(.trialExpired(since: install.createdAt + .days(30)))
  }

  // MARK: - legacy grandfathering (pre-claim, from podcast_app.events)

  func testHostPurchaseGrandfatheredAndBeatsTrial() async throws {
    let deviceId = UUID()
    try await self.db.create(PodcastEvent(
      eventId: "af0a338f",
      kind: .subscription,
      label: "subscribe success",
      detail: "originalID: 123456789012345", // len 15 -> host purchase
      deviceId: deviceId,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.4.0",
      iosVersion: "18.2",
    ))

    let output = try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)

    let event = try await PodcastEvent.query()
      .where(.deviceId == deviceId)
      .first(in: self.db)
    expect(output).toEqual(.legacyGrandfathered(
      paidAt: event.createdAt,
      expiresAt: event.createdAt + .days(455),
    ))
  }

  func testFamilySharedIsGrandfathered() async throws {
    let deviceId = UUID()
    try await self.db.create(PodcastEvent(
      eventId: "a72104d7",
      kind: .subscription,
      label: "subscribe success",
      detail: "originalID: 505123456789012345", // len 18 -> family-shared
      deviceId: deviceId,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.4.0",
      iosVersion: "18.2",
    ))

    let output = try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)

    let event = try await PodcastEvent.query()
      .where(.deviceId == deviceId)
      .first(in: self.db)
    expect(output).toEqual(.legacyGrandfathered(
      paidAt: event.createdAt,
      expiresAt: event.createdAt + .days(455),
    ))
  }

  func testSandboxTransactionIsNotGrandfathered() async throws {
    let deviceId = UUID()
    try await self.db.create(PodcastEvent(
      eventId: "af0a338f",
      kind: .subscription,
      label: "subscribe success",
      detail: "originalID: 2000000000000000", // len 16 -> sandbox/Xcode, excluded
      deviceId: deviceId,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.4.0",
      iosVersion: "18.2",
    ))

    let output = try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)

    guard case .trial = output else {
      return XCTFail("expected sandbox device to fall through to .trial, got \(output)")
    }
  }

  func testExpiredLegacyFallsThroughToTrial() async throws {
    let deviceId = UUID()
    try await self.db.create(PodcastEvent(
      eventId: "af0a338f",
      kind: .subscription,
      label: "subscribe success",
      detail: "originalID: 123456789012345",
      deviceId: deviceId,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.4.0",
      iosVersion: "18.2",
    ))
    let event = try await PodcastEvent.query()
      .where(.deviceId == deviceId)
      .first(in: self.db)

    let output = try await withDependencies {
      $0.date = .constant(event.createdAt + .days(456))
    } operation: {
      try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)
    }

    switch output {
    case .trial, .trialExpired:
      break
    default:
      XCTFail("expected expired legacy to fall through to trial/.trialExpired, got \(output)")
    }
  }

  // MARK: - claim detection / cross-app auto-detect

  func testCrossAppAutoDetectMintsTokenAndReturnsClaimed() async throws {
    let child = try await self.child()
    let deviceId = UUID()
    // simulates a Blocker claim on the same vendor id: claimedAt + childId set
    let device = try await self.db.create(IOSDevice(
      id: .init(deviceId),
      childId: child.model.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      claimedAt: .reference,
    ))
    var preInstall = try await self.db.create(
      PodcastApp.Install(deviceId: device.id, appVersion: "1.6.0"),
    )
    try await preInstall.modifyCreatedAt(.exact(.reference - .days(2)))

    let output = try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)

    guard case .claimed(let token, let childId, let childName, let subscription) = output else {
      return XCTFail("expected .claimed, got \(output)")
    }
    expect(childId).toEqual(child.model.id.rawValue)
    expect(childName).toEqual(child.model.name)
    // 30-day AM trial survives claim: install ~2 days old at the test clock
    // honors the "30 days free" promise rather than dropping to .unpaid
    expect(subscription).toEqual(.amTrial(expiresAt: preInstall.createdAt + .days(30)))

    let install = try await PodcastApp.Install.query()
      .where(.deviceId == device.id)
      .first(in: self.db)

    let tokens = try await PodcastApp.Token.query()
      .where(.installId == install.id)
      .all(in: self.db)
    expect(tokens.count).toEqual(1)
    expect(token).toEqual(tokens[0].value.rawValue)

    // idempotent: a second poll reuses the same token, does not mint a duplicate
    let again = try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)
    guard case .claimed(let token2, _, _, _) = again else {
      return XCTFail("expected .claimed on second poll, got \(again)")
    }
    expect(token2).toEqual(token)
    let tokensAfter = try await PodcastApp.Token.query()
      .where(.installId == install.id)
      .all(in: self.db)
    expect(tokensAfter.count).toEqual(1)
  }

  func testClaimedDeviceMissingChildThrows() async throws {
    let deviceId = UUID()
    try await self.db.create(IOSDevice(
      id: .init(deviceId),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      claimedAt: .reference,
    ))

    do {
      _ = try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)
      XCTFail("expected resolve to throw for claimed device with no child")
    } catch {
      // expected: Abort(.internalServerError)
    }
  }
}
