import Dependencies
import DuetSQL
import Foundation
import MusicRoute
import XCTest
import XExpect

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@testable import Api

/// deprecated: behavior lives in `GetMusicAppStatus_v2ResolverTests`, this only covers
/// the legacy shim's own mapping. delete with `GetMusicAppStatus`.
final class GetMusicAppStatusResolverTests: ApiTestCase, @unchecked Sendable {
  static let dashboardUrl = "https://parents.gertrude.app"

  var legacyCtx: Context {
    .mock(dashboardUrl: Self.dashboardUrl)
  }

  var remediationUrl: URL {
    URL(string: "\(Self.dashboardUrl)/settings")!
  }

  func input(_ deviceId: UUID) -> GetMusicAppStatus.Input {
    .init(
      deviceId: deviceId,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      appVersion: "0.2.0",
    )
  }

  func testRouteMatches() throws {
    let deviceId = UUID()
    let input = self.input(deviceId)
    var request = URLRequest(url: URL(string: "gertrude-music/GetMusicAppStatus")!)
    request.httpMethod = "POST"
    request.httpBody = try JSONEncoder().encode(input)

    let matched = try PairQLRoute.router.match(request: request)

    expect(matched).toEqual(.music(.unauthed(.getMusicAppStatus(input))))
  }

  func testDelegatesUnclaimedToV2() async throws {
    let deviceId = UUID()
    let code = uniqueClaimCode()

    let output = try await withDependencies {
      $0.verificationCode = .init(generate: { code })
      $0.date = .constant(.reference)
    } operation: {
      try await GetMusicAppStatus.resolve(with: self.input(deviceId), in: self.legacyCtx)
    }

    expect(output).toEqual(.unclaimed(code: code, expiresAt: .reference + .days(7)))
  }

  func testMapsActiveEntitlementFromV2() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.id, tier: .medium)
    let deviceId = UUID()
    let device = try await self.claimedMusicDevice(deviceId, child: child.model)

    let output = try await GetMusicAppStatus.resolve(
      with: self.input(deviceId),
      in: self.legacyCtx,
    )

    guard case .claimed(let token, _, _, let entitlement) = output else {
      return XCTFail("expected .claimed, got \(output)")
    }
    expect(entitlement).toEqual(.active)
    let install = try await MusicApp.Install.query()
      .where(.deviceId == device.id)
      .first(in: self.db)
    let tokens = try await MusicApp.Token.query()
      .where(.installId == install.id)
      .all(in: self.db)
    expect(token).toEqual(tokens[0].value.rawValue)
  }

  func testMapsUnavailableToLegacyUnpaidWithSettingsUrl() async throws {
    let child = try await self.child() // no subscription -> v2 reports .unavailable
    let deviceId = UUID()
    _ = try await self.claimedMusicDevice(deviceId, child: child.model)

    let output = try await GetMusicAppStatus.resolve(
      with: self.input(deviceId),
      in: self.legacyCtx,
    )

    guard case .claimed(_, _, _, let entitlement) = output else {
      return XCTFail("expected .claimed, got \(output)")
    }
    // 0.2.0 substitutes the settings url when nil, so the shim keeps sending the real one
    expect(entitlement).toEqual(.unpaid(remediationUrl: self.remediationUrl))
  }
}

extension GetMusicAppStatusResolverTests {
  @discardableResult
  private func claimedMusicDevice(_ deviceId: UUID, child: Child) async throws -> IOSDevice {
    let device = try await self.db.create(IOSDevice(
      id: .init(deviceId),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    try await self.createClaim(
      .music,
      device.id,
      child.id,
      claimedAt: .reference,
    )
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "0.2.0"))
    return device
  }
}
