import DuetSQL
import Foundation
import XCTest
import XExpect

@testable import Api

final class MusicAppInstallTests: ApiTestCase, @unchecked Sendable {
  func testEnsureExistsCreatesDeviceAndInstall() async throws {
    let deviceId = IOSDevice.Id(UUID())

    let install = try await MusicApp.Install.ensureExists(
      deviceId: deviceId,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      appVersion: "1.0.0",
      in: self.db,
    )

    let device = try await self.db.find(deviceId)
    expect(device.modelIdentifier).toEqual("iPhone15,2")
    expect(device.iosVersion).toEqual("18.2")

    let persisted = try await self.db.find(install.id)
    expect(persisted.deviceId).toEqual(deviceId)
    expect(persisted.appVersion).toEqual("1.0.0")
  }

  func testEnsureExistsUpdatesExistingRowsWithoutDuplicatingInstall() async throws {
    let deviceId = IOSDevice.Id(UUID())

    _ = try await MusicApp.Install.ensureExists(
      deviceId: deviceId,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      appVersion: "1.0.0",
      in: self.db,
    )
    let first = try await MusicApp.Install.query()
      .where(.deviceId == deviceId)
      .first(in: self.db)

    _ = try await MusicApp.Install.ensureExists(
      deviceId: deviceId,
      modelIdentifier: "iPhone16,1",
      iosVersion: "18.3",
      appVersion: "1.0.1",
      in: self.db,
    )

    let installs = try await MusicApp.Install.query()
      .where(.deviceId == deviceId)
      .all(in: self.db)
    expect(installs).toHaveCount(1)
    expect(installs[0].id).toEqual(first.id)
    expect(installs[0].createdAt).toEqual(first.createdAt)
    expect(installs[0].appVersion).toEqual("1.0.1")

    let device = try await self.db.find(deviceId)
    expect(device.modelIdentifier).toEqual("iPhone16,1")
    expect(device.iosVersion).toEqual("18.3")
  }

  func testTokensAreUniquePerInstall() async throws {
    let constraintRows = try await self.db.customQuery(MusicAppTokenInstallIdUnique.self)
    expect(constraintRows.first?.constraintCount).toEqual(1)

    let install = try await MusicApp.Install.ensureExists(
      deviceId: .init(UUID()),
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      appVersion: "1.0.0",
      in: self.db,
    )
    let first = try await self.db.findOrCreate(
      MusicApp.Token(installId: install.id),
      conflictOn: [.installId],
    )
    let second = try await self.db.findOrCreate(
      MusicApp.Token(installId: install.id),
      conflictOn: [.installId],
    )

    expect(second.id).toEqual(first.id)
    let tokens = try await MusicApp.Token.query()
      .where(.installId == install.id)
      .all(in: self.db)
    expect(tokens).toHaveCount(1)
  }

  func testConnectedDeviceIdsReturnsOnlyDevicesWithTokens() async throws {
    let connectedDeviceId = IOSDevice.Id(UUID())
    let unconnectedDeviceId = IOSDevice.Id(UUID())
    let missingDeviceId = IOSDevice.Id(UUID())

    let connectedInstall = try await MusicApp.Install.ensureExists(
      deviceId: connectedDeviceId,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      appVersion: "1.0.0",
      in: self.db,
    )
    _ = try await MusicApp.Install.ensureExists(
      deviceId: unconnectedDeviceId,
      modelIdentifier: "iPhone16,1",
      iosVersion: "18.3",
      appVersion: "1.0.0",
      in: self.db,
    )
    try await self.db.create(MusicApp.Token(installId: connectedInstall.id))

    let connected = try await MusicApp.Token.connectedDeviceIds(
      among: [connectedDeviceId, unconnectedDeviceId, missingDeviceId],
      in: self.db,
    )

    expect(connected).toEqual(Set([connectedDeviceId]))
  }
}

final class MusicAppTokenTrialTests: DependencyTestCase {
  func testTrialExpiresTwentyOneDaysAfterTokenCreation() {
    var token = MusicApp.Token(installId: .init())
    token.createdAt = .reference

    expect(MusicApp.Token.trialDuration).toEqual(.days(21))
    expect(token.trialExpiresAt).toEqual(.reference + .days(21))
  }

  func testTrialIsActiveBeforeTwentyOneDayBoundary() {
    var token = MusicApp.Token(installId: .init())
    token.createdAt = .reference

    expect(token.hasActiveTrial(at: .reference + .days(21) - 1)).toBeTrue()
  }

  func testTrialIsExpiredAtTwentyOneDayBoundary() {
    var token = MusicApp.Token(installId: .init())
    token.createdAt = .reference

    expect(token.hasActiveTrial(at: .reference + .days(21))).toBeFalse()
  }

  func testFreeAccountReceivesActiveTokenTrial() {
    let token = self.token(createdAt: .reference)

    expect(
      billing(date: .reference + .days(20)).musicSubscriptionState(for: token),
    ).toEqual(.trial(expiresAt: .reference + .days(21)))
  }

  func testExpiredTokenIsUnavailableForFreeAccount() {
    let token = self.token(createdAt: .reference)

    expect(
      billing(date: .reference + .days(21)).musicSubscriptionState(for: token),
    ).toEqual(.unavailable)
  }

  func testPaidMusicAccountIsActiveDespiteExpiredToken() {
    let token = self.token(createdAt: .reference)

    for tier in [StripeSubscription.Tier.medium, .full] {
      expect(
        billing(tier: tier, date: .reference + .days(30)).musicSubscriptionState(for: token),
      ).toEqual(.active)
    }
  }

  func testComplimentaryAccountIsActiveDespiteExpiredToken() {
    let token = self.token(createdAt: .reference)

    expect(
      billing(comp: true, date: .reference + .days(30)).musicSubscriptionState(for: token),
    ).toEqual(.active)
  }

  func testLightAccountFallsBackToTokenTrial() {
    let token = self.token(createdAt: .reference)

    expect(
      billing(tier: .light, date: .reference + .days(20)).musicSubscriptionState(for: token),
    ).toEqual(.trial(expiresAt: .reference + .days(21)))
  }

  func testPastDueMusicAccountFallsBackToTokenTrial() {
    let token = self.token(createdAt: .reference)

    expect(
      billing(
        tier: .medium,
        status: .pastDue,
        date: .reference + .days(20),
      ).musicSubscriptionState(for: token),
    ).toEqual(.trial(expiresAt: .reference + .days(21)))
  }

  func testCanceledMusicAccountFallsBackToTokenTrial() {
    let token = self.token(createdAt: .reference)

    expect(
      billing(
        tier: .full,
        status: .canceled,
        date: .reference + .days(20),
      ).musicSubscriptionState(for: token),
    ).toEqual(.trial(expiresAt: .reference + .days(21)))
  }

  func testMacFullTrialDoesNotReplaceActiveTokenTrial() {
    let token = self.token(createdAt: .reference)

    expect(
      billing(
        trialStartedAt: .reference + .days(20),
        date: .reference + .days(20),
      ).musicSubscriptionState(for: token),
    ).toEqual(.trial(expiresAt: .reference + .days(21)))
  }

  func testMacFullTrialDoesNotGrantMusicAfterTokenTrialExpires() {
    let token = self.token(createdAt: .reference)

    expect(
      billing(
        trialStartedAt: .reference + .days(20),
        date: .reference + .days(21),
      ).musicSubscriptionState(for: token),
    ).toEqual(.unavailable)
  }

  private func token(createdAt: Date) -> MusicApp.Token {
    var token = MusicApp.Token(installId: .init())
    token.createdAt = createdAt
    return token
  }
}

private struct MusicAppTokenInstallIdUnique: CustomQueryable {
  var constraintCount: Int

  static func query(bindings _: [Postgres.Data]) -> SQL.Statement {
    .init("""
    SELECT COUNT(*)::int AS constraint_count
    FROM pg_constraint c
    JOIN pg_namespace n ON n.oid = c.connamespace
    JOIN pg_class t ON t.oid = c.conrelid
    WHERE n.nspname = 'music_app'
      AND t.relname = 'tokens'
      AND c.conname = 'uq_tokens_install_id';
    """)
  }
}
