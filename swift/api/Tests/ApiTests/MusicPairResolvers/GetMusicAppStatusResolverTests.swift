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

final class GetMusicAppStatusResolverTests: ApiTestCase, @unchecked Sendable {
  func input(
    _ deviceId: UUID,
    appVersion: String = "1.0.0",
  ) -> GetMusicAppStatus.Input {
    .init(
      deviceId: deviceId,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      appVersion: appVersion,
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

  func testFreshDeviceCreatesInstallAndReturnsClaimCode() async throws {
    let deviceId = UUID()
    let code = Int.random(in: 100_000 ... 999_999)

    let output = try await withDependencies {
      $0.verificationCode = .init(generate: { code })
      $0.date = .constant(.reference)
    } operation: {
      try await GetMusicAppStatus.resolve(with: self.input(deviceId), in: .mock)
    }

    expect(output).toEqual(.unclaimed(code: code, expiresAt: .reference + .days(7)))

    let device = try await self.db.find(IOSDevice.Id(deviceId))
    expect(device.modelIdentifier).toEqual("iPhone15,2")
    expect(device.iosVersion).toEqual("18.2")
    let claim = try await Claim.find(code: code, in: self.db)
    expect(claim?.intent).toEqual(.music)
    expect(claim?.deviceId).toEqual(device.id)
    expect(claim?.expiresAt).toEqual(.reference + .days(7))

    let install = try await MusicApp.Install.query()
      .where(.deviceId == device.id)
      .first(in: self.db)
    expect(install.appVersion).toEqual("1.0.0")
  }

  func testUnclaimedDeviceReusesExistingClaimCode() async throws {
    let deviceId = UUID()

    let first = try await withDependencies {
      $0.verificationCode = .init(generate: { 123_456 })
      $0.date = .constant(.reference)
    } operation: {
      try await GetMusicAppStatus.resolve(with: self.input(deviceId), in: .mock)
    }

    let second = try await withDependencies {
      $0.verificationCode = .init(generate: { 654_321 })
      $0.date = .constant(.reference + .days(1))
    } operation: {
      try await GetMusicAppStatus.resolve(
        with: self.input(deviceId, appVersion: "1.0.1"),
        in: .mock,
      )
    }

    expect(second).toEqual(first)

    let installs = try await MusicApp.Install.query()
      .where(.deviceId == IOSDevice.Id(deviceId))
      .all(in: self.db)
    expect(installs).toHaveCount(1)
    expect(installs[0].appVersion).toEqual("1.0.1")
  }

  func testClaimedDeviceCreatesTokenAndReturnsChildContext() async throws {
    let child = try await self.child()
    let deviceId = UUID()
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
      code: Int.random(in: 100_000 ... 999_999),
      claimedAt: .reference,
    )
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))

    let output = try await GetMusicAppStatus.resolve(with: self.input(deviceId), in: .mock)

    guard case .claimed(let token, let childId, let childName) = output else {
      return XCTFail("expected .claimed, got \(output)")
    }
    expect(childId).toEqual(child.id.rawValue)
    expect(childName).toEqual(child.model.name)

    let install = try await MusicApp.Install.query()
      .where(.deviceId == device.id)
      .first(in: self.db)
    let tokens = try await MusicApp.Token.query()
      .where(.installId == install.id)
      .all(in: self.db)
    expect(tokens).toHaveCount(1)
    expect(token).toEqual(tokens[0].value.rawValue)
  }

  func testClaimedDeviceReusesExistingToken() async throws {
    let child = try await self.child()
    let deviceId = UUID()
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
      code: Int.random(in: 100_000 ... 999_999),
      claimedAt: .reference,
    )
    let install = try await self.db.create(
      MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"),
    )
    let existing = try await self.db.create(MusicApp.Token(installId: install.id))

    let output = try await GetMusicAppStatus.resolve(with: self.input(deviceId), in: .mock)

    guard case .claimed(let token, _, _) = output else {
      return XCTFail("expected .claimed, got \(output)")
    }
    expect(token).toEqual(existing.value.rawValue)

    let tokens = try await MusicApp.Token.query()
      .where(.installId == install.id)
      .all(in: self.db)
    expect(tokens).toHaveCount(1)
  }
}
