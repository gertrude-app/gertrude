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

  func testConcurrentRequestsCreateSingleInstall() async throws {
    let deviceId = UUID()

    let outputs = try await withThrowingTaskGroup(of: GetTrialStatus.Output.self) { group in
      for _ in 0 ..< 10 {
        group.addTask {
          try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)
        }
      }
      return try await group.reduce(into: []) { $0.append($1) }
    }

    expect(outputs.count).toEqual(10)
    let devices = try await IOSDevice.query()
      .where(.id == IOSDevice.Id(deviceId))
      .all(in: self.db)
    expect(devices.count).toEqual(1)
    let installs = try await PodcastApp.Install.query()
      .where(.deviceId == IOSDevice.Id(deviceId))
      .all(in: self.db)
    expect(installs.count).toEqual(1)
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
      accessEndsAt: event.createdAt + .days(455),
      showMigrationNag: false, // fresh purchase, far from window end
      migrationUrl: nil,
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
      accessEndsAt: event.createdAt + .days(455),
      showMigrationNag: false, // fresh purchase, far from window end
      migrationUrl: nil,
    ))
  }

  func testLegacyNagFiresAtExactNagWindowBoundary() async throws {
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

    // accessEndsAt = paidAt + 455d; nag boundary = accessEndsAt - 60d = paidAt + 395d
    let output = try await withDependencies {
      $0.date = .constant(event.createdAt + .days(395))
    } operation: {
      try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)
    }

    expect(output).toEqual(.legacyGrandfathered(
      accessEndsAt: event.createdAt + .days(455),
      showMigrationNag: true,
      migrationUrl: nil,
    ))
  }

  func testLegacyNagSilentJustOutsideNagWindow() async throws {
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
      $0.date = .constant(event.createdAt + .days(394)) // one day shy of the nag boundary
    } operation: {
      try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)
    }

    expect(output).toEqual(.legacyGrandfathered(
      accessEndsAt: event.createdAt + .days(455),
      showMigrationNag: false,
      migrationUrl: nil,
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

  // MARK: - cross-app auto-detect (device bound to a child)

  func testDashboardClaimedDeviceMintsTokenAndReturnsConnected() async throws {
    let child = try await self.child()
    let deviceId = UUID()
    // dashboard/supervision claim on the same vendor id: childId AND claimedAt set
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

    guard case .connected(let token, let childId, let childName, let subscription) = output else {
      return XCTFail("expected .connected, got \(output)")
    }
    expect(childId).toEqual(child.model.id.rawValue)
    expect(childName).toEqual(child.model.name)
    // 30-day AM trial survives detection: install ~2 days old at the test clock
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
    guard case .connected(let token2, _, _, _) = again else {
      return XCTFail("expected .connected on second poll, got \(again)")
    }
    expect(token2).toEqual(token)
    let tokensAfter = try await PodcastApp.Token.query()
      .where(.installId == install.id)
      .all(in: self.db)
    expect(tokensAfter.count).toEqual(1)
  }

  func testConnectedViaNonSupervisionPathAutoDetects() async throws {
    let child = try await self.child()
    let deviceId = UUID()
    // normal in-app Blocker connect: childId set, claimedAt NIL (the reproducer state)
    let device = try await self.db.create(IOSDevice(
      id: .init(deviceId),
      childId: child.model.id,
      modelIdentifier: "iPhone13,1",
      iosVersion: "18.2",
      claimedAt: nil, // NOT a supervision/dashboard claim
    ))
    var preInstall = try await self.db.create(
      PodcastApp.Install(deviceId: device.id, appVersion: "1.6.0"),
    )
    try await preInstall.modifyCreatedAt(.exact(.reference - .days(2)))

    let output = try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)

    guard case .connected(let token, let childId, _, let subscription) = output else {
      return XCTFail("expected .connected for connected-but-unclaimed device, got \(output)")
    }
    expect(childId).toEqual(child.model.id.rawValue)
    // free account on a live install trial -> trial floor, not a re-connect prompt or .unpaid
    expect(subscription).toEqual(.amTrial(expiresAt: preInstall.createdAt + .days(30)))

    let install = try await PodcastApp.Install.query()
      .where(.deviceId == device.id)
      .first(in: self.db)
    let tokens = try await PodcastApp.Token.query()
      .where(.installId == install.id)
      .all(in: self.db)
    expect(tokens.count).toEqual(1)
    expect(token).toEqual(tokens[0].value.rawValue)
  }

  func testConnectedDeviceHonorsLegacyStampFromBillingIdentity() async throws {
    let child = try await self.child()
    let deviceId = UUID()
    let device = try await self.db.create(IOSDevice(
      id: .init(deviceId),
      childId: child.model.id,
      modelIdentifier: "iPhone13,1",
      iosVersion: "18.2",
      claimedAt: nil,
    ))
    // install old enough that the 30-day install trial has lapsed, so legacy access governs
    var preInstall = try await self.db.create(
      PodcastApp.Install(deviceId: device.id, appVersion: "1.6.0"),
    )
    try await preInstall.modifyCreatedAt(.exact(.reference - .days(40)))
    // the bridge: parent billing identity carries the legacy floor (stamped at bind time)
    var identity = try await self.db.create(BillingIdentity(parentId: child.parent.model.id))
    identity.legacyAmIapPaidAt = .reference - .days(10)
    try await self.db.update(identity)

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)
    }

    guard case .connected(_, _, _, let subscription) = output else {
      return XCTFail("expected .connected, got \(output)")
    }
    let legacyEnd = (Date.reference - .days(10)) + PodcastApp.LegacyIap.grantWindow
    expect(subscription).toEqual(.legacyGrandfathered(
      accessEndsAt: legacyEnd,
      showMigrationNag: PodcastApp.LegacyIap.showMigrationNag(
        accessEndsAt: legacyEnd,
        now: .reference,
      ),
      migrationUrl: nil,
    ))
  }

  func testClaimedAtWithoutChildIdFallsThroughToTrial() async throws {
    // childId — not claimedAt — drives detection; a claimedAt-only row is ignored
    let deviceId = UUID()
    try await self.db.create(IOSDevice(
      id: .init(deviceId),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      claimedAt: .reference,
    ))

    let output = try await GetTrialStatus.resolve(with: self.input(deviceId), in: .mock)

    guard case .trial = output else {
      return XCTFail("expected .trial (no child bound), got \(output)")
    }
  }
}
