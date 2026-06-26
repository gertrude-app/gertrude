import Dependencies
import DuetSQL
import XCTest
import XCTVapor
import XExpect

@testable import Api

final class ClaimRedirectRouteTests: ApiTestCase, @unchecked Sendable {
  func testValidCode_redirectsWithDeviceInfo() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPad14,1",
      iosVersion: "17.5",
    ))
    try await self.createClaim(.blockerSupervise, device.id, code: code)
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    try await app.test(
      .GET,
      "claim-pending-supervision/\(code)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.temporaryRedirect)
        let location = res.headers.first(name: .location)!
        expect(location).toContain("\(self.env.dashboardUrl)/signup")
        expect(location).toContain("claimPendingSupervision=\(code)")
        expect(location).toContain("modelName=iPad%20mini%20(6th%20gen)")
        expect(location).toContain("iosVersion=17.5")
        expect(location).toContain("redirect=/supervise-device/\(code)/claim")
        expect(location).not.toContain("error=")
      },
    )
  }

  func testExpiredButClaimedCode_stillRedirectsWithDeviceInfo() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let child = try await self.child()
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone17,1",
      iosVersion: "18.0",
    ))
    try await self.createClaim(
      .blockerSupervise,
      device.id,
      child.id,
      code: code,
      expiresAt: .reference - .days(30),
      claimedAt: .reference - .days(30),
    )
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    try await app.test(
      .GET,
      "claim-pending-supervision/\(code)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.temporaryRedirect)
        let location = res.headers.first(name: .location)!
        expect(location).toContain("claimPendingSupervision=\(code)")
        expect(location).toContain("modelName=iPhone%2016%20Pro")
        expect(location).toContain("redirect=/supervise-device/\(code)/claim")
        expect(location).not.toContain("error=")
      },
    )
  }

  func testMissingCodeParam_redirectsWithMissingCodeError() async throws {
    try await app.test(
      .GET,
      "claim-pending-supervision/abc",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.temporaryRedirect)
        let location = res.headers.first(name: .location)!
        expect(location).toContain("\(self.env.dashboardUrl)/signup")
        expect(location).toContain("error=invalid_code")
      },
    )
  }

  func testCodeNotFound_redirectsWithInvalidCodeError() async throws {
    try await app.test(
      .GET,
      "claim-pending-supervision/999999",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.temporaryRedirect)
        let location = res.headers.first(name: .location)!
        expect(location).toContain("\(self.env.dashboardUrl)/signup")
        expect(location).toContain("error=missing_code")
      },
    )
  }

  func testExpiredUnclaimedCode_redirectsWithExpiredCodeError() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    try await self.createClaim(
      .blockerSupervise,
      device.id,
      code: code,
      expiresAt: .reference - .days(1),
    )
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    try await app.test(
      .GET,
      "claim-pending-supervision/\(code)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.temporaryRedirect)
        let location = res.headers.first(name: .location)!
        expect(location).toContain("\(self.env.dashboardUrl)/signup")
        expect(location).toContain("error=expired_code")
      },
    )
  }

  // remaining handler logic is exercised by the supervision tests above
  func testAmValidCode_redirectsToAmClaimFunnel() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    try await self.createClaim(.podcasts, device.id, code: code)

    try await app.test(
      .GET,
      "claim-pending-am/\(code)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.temporaryRedirect)
        let location = res.headers.first(name: .location)!
        expect(location).toContain("\(self.env.dashboardUrl)/signup")
        expect(location).toContain("claimPendingAmDevice=\(code)")
        expect(location).toContain("iosVersion=18.2")
        expect(location).toContain("redirect=/claim-am-device/\(code)/claim")
        expect(location).not.toContain("error=")
      },
    )
  }

  func testBlockerConnectValidCode_redirectsToBlockerClaimFunnel() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    try await self.createClaim(.blockerConnect, device.id, code: code)

    try await app.test(
      .GET,
      "claim-pending-blocker/\(code)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.temporaryRedirect)
        let location = res.headers.first(name: .location)!
        expect(location).toContain("\(self.env.dashboardUrl)/signup")
        expect(location).toContain("claimPendingBlocker=\(code)")
        expect(location).toContain("iosVersion=18.2")
        expect(location).toContain("redirect=/claim-blocker-device/\(code)/claim")
        expect(location).not.toContain("error=")
      },
    )
  }

  func testMusicValidCode_redirectsToMusicClaimFunnel() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    try await self.createClaim(.music, device.id, code: code)

    try await app.test(
      .GET,
      "claim-pending-music/\(code)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.temporaryRedirect)
        let location = res.headers.first(name: .location)!
        expect(location).toContain("\(self.env.dashboardUrl)/signup")
        expect(location).toContain("claimPendingMusicDevice=\(code)")
        expect(location).toContain("iosVersion=18.2")
        expect(location).toContain("redirect=/claim-music-device/\(code)/claim")
        expect(location).not.toContain("error=")
      },
    )
  }

  func testNewStyleClaim_selfCorrectsMismatchedRedirectRoute() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    try await self.db.create(Claim(
      code: code,
      intent: .music, // <- a music code...
      deviceId: device.id,
      expiresAt: .reference + .days(7),
    ))

    try await app.test(
      .GET,
      "claim-pending-blocker/\(code)", // ...reached through the blocker redirect route
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.temporaryRedirect)
        let location = res.headers.first(name: .location)!
        expect(location).toContain("claimPendingMusicDevice=\(code)") // routed by claim intent
        expect(location).toContain("redirect=/claim-music-device/\(code)/claim")
        expect(location).not.toContain("claimPendingBlocker")
        expect(location).not.toContain("error=")
      },
    )
  }

  func testNewStyleClaim_matchingRouteUsesClaimIntent() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    try await self.db.create(Claim(
      code: code,
      intent: .blockerConnect,
      deviceId: device.id,
      expiresAt: .reference + .days(7),
    ))

    try await app.test(
      .GET,
      "claim-pending-blocker/\(code)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.temporaryRedirect)
        let location = res.headers.first(name: .location)!
        expect(location).toContain("claimPendingBlocker=\(code)")
        expect(location).toContain("redirect=/claim-blocker-device/\(code)/claim")
        expect(location).not.toContain("error=")
      },
    )
  }
}
