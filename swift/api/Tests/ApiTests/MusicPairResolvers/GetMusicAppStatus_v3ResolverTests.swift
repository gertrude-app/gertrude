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

final class GetMusicAppStatus_v3ResolverTests: ApiTestCase, @unchecked Sendable {
  func input(_ deviceId: UUID) -> GetMusicAppStatus_v3.Input {
    .init(
      deviceId: deviceId,
      modelIdentifier: "iPhone15,2",
      iosVersion: "26.0",
      appVersion: "1.1.0",
    )
  }

  func testRouteMatches() throws {
    let deviceId = UUID()
    let input = self.input(deviceId)
    var request = URLRequest(url: URL(string: "gertrude-music/GetMusicAppStatus_v3")!)
    request.httpMethod = "POST"
    request.httpBody = try JSONEncoder().encode(input)

    let matched = try PairQLRoute.router.match(request: request)

    expect(matched).toEqual(.music(.unauthed(.getMusicAppStatus_v3(input))))
  }

  func testFreshClaimedFreeAccountStartsTokenTrial() async throws {
    let child = try await self.child()
    let (device, install) = try await self.claimedMusicInstall(for: child)

    let output = try await GetMusicAppStatus_v3.resolve(
      with: self.input(device.id.rawValue),
      in: .mock,
    )

    let persistedToken = try await self.token(for: install)
    expect(output).toEqual(.claimed(
      token: persistedToken.value.rawValue,
      childId: child.id.rawValue,
      childName: child.model.name,
      entitlement: .trial(expiresAt: persistedToken.trialExpiresAt),
    ))
  }

  func testExistingTokenExpiresAtOriginalTwentyOneDayBoundary() async throws {
    let child = try await self.child()
    let (device, install) = try await self.claimedMusicInstall(for: child)

    _ = try await GetMusicAppStatus_v3.resolve(
      with: self.input(device.id.rawValue),
      in: .mock,
    )
    let persistedToken = try await self.token(for: install)

    let output = try await withDependencies {
      $0.date = .constant(persistedToken.trialExpiresAt)
    } operation: {
      try await GetMusicAppStatus_v3.resolve(with: self.input(device.id.rawValue), in: .mock)
    }

    guard case .claimed(let token, _, _, let entitlement) = output else {
      return XCTFail("expected .claimed, got \(output)")
    }
    expect(token).toEqual(persistedToken.value.rawValue)
    expect(entitlement).toEqual(.unavailable)

    let tokens = try await MusicApp.Token.query()
      .where(.installId == persistedToken.installId)
      .all(in: self.db)
    expect(tokens).toHaveCount(1)
    expect(tokens[0].createdAt).toEqual(persistedToken.createdAt)
  }

  func testPaidAccountIsActive() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.id, tier: .medium)
    let (device, _) = try await self.claimedMusicInstall(for: child)

    let output = try await GetMusicAppStatus_v3.resolve(
      with: self.input(device.id.rawValue),
      in: .mock,
    )

    guard case .claimed(_, _, _, let entitlement) = output else {
      return XCTFail("expected .claimed, got \(output)")
    }
    expect(entitlement).toEqual(.active)
  }

  func testV2MapsTrialToActive() async throws {
    let child = try await self.child()
    let (device, _) = try await self.claimedMusicInstall(for: child)
    let input = GetMusicAppStatus_v2.Input(
      deviceId: device.id.rawValue,
      modelIdentifier: "iPhone15,2",
      iosVersion: "26.0",
      appVersion: "1.0.0",
    )

    let output = try await GetMusicAppStatus_v2.resolve(with: input, in: .mock)

    guard case .claimed(_, _, _, let entitlement) = output else {
      return XCTFail("expected .claimed, got \(output)")
    }
    expect(entitlement).toEqual(.active)
  }

  func testV2MapsExpiredTrialToUnavailable() async throws {
    let child = try await self.child()
    let (_, install) = try await self.claimedMusicInstall(for: child)
    let input = GetMusicAppStatus_v2.Input(
      deviceId: install.deviceId.rawValue,
      modelIdentifier: "iPhone15,2",
      iosVersion: "26.0",
      appVersion: "1.0.0",
    )

    _ = try await GetMusicAppStatus_v2.resolve(with: input, in: .mock)
    let persistedToken = try await self.token(for: install)
    let output = try await withDependencies {
      $0.date = .constant(persistedToken.trialExpiresAt)
    } operation: {
      try await GetMusicAppStatus_v2.resolve(with: input, in: .mock)
    }

    guard case .claimed(_, _, _, let entitlement) = output else {
      return XCTFail("expected .claimed, got \(output)")
    }
    expect(entitlement).toEqual(.unavailable)
  }

  private func token(for install: MusicApp.Install) async throws -> MusicApp.Token {
    try await MusicApp.Token.query()
      .where(.installId == install.id)
      .first(in: self.db)
  }
}
