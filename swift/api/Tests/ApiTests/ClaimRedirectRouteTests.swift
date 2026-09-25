import Dependencies
import DuetSQL
import XCTest
import XCTVapor
import XExpect

@testable import Api

final class ClaimRedirectRouteTests: ApiTestCase, @unchecked Sendable {
  func testValidCode_redirectsToAccountSupervision() async throws {
    let code = uniqueClaimCode()
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
        expect(location).toEqual("\(self.env.accountDashboardUrl)/connect/blockerSupervise/\(code)")
        expect(location).not.toContain("error=")
      },
    )
  }

  func testExpiredButClaimedCode_stillRedirectsToAccount() async throws {
    let code = uniqueClaimCode()
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
        expect(location).toEqual("\(self.env.accountDashboardUrl)/connect/blockerSupervise/\(code)")
        expect(location).not.toContain("error=")
      },
    )
  }

  func testMissingCodeParam_redirectsToAccountInvalidCode() async throws {
    try await app.test(
      .GET,
      "claim-pending-supervision/abc",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.temporaryRedirect)
        let location = res.headers.first(name: .location)!
        expect(location).toEqual("\(self.env.accountDashboardUrl)/connect/blockerSupervise/invalid")
      },
    )
  }

  func testCodeNotFound_redirectsToAccountCodePage() async throws {
    try await app.test(
      .GET,
      "claim-pending-supervision/999999",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.temporaryRedirect)
        let location = res.headers.first(name: .location)!
        expect(location).toEqual("\(self.env.accountDashboardUrl)/connect/blockerSupervise/999999")
      },
    )
  }

  func testExpiredUnclaimedCode_redirectsToAccountForRecovery() async throws {
    let code = uniqueClaimCode()
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
        expect(location).toEqual("\(self.env.accountDashboardUrl)/connect/blockerSupervise/\(code)")
      },
    )
  }

  // remaining handler logic is exercised by the supervision tests above
  func testPodcastClaimRoutes_redirectToPodcastFunnel() async throws {
    let code = uniqueClaimCode()
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    try await self.createClaim(.podcasts, device.id, code: code)

    // legacy route: shipped app builds still emit /a/ -> claim-pending-am, so it must keep
    // resolving — and now redirects into the new podcast-named funnel
    try await app.test(
      .GET,
      "claim-pending-am/\(code)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.temporaryRedirect)
        let location = res.headers.first(name: .location)!
        expect(location).toEqual("\(self.env.accountDashboardUrl)/connect/podcasts/\(code)")
        expect(location).not.toContain("error=")
      },
    )

    // new canonical route (/p/ -> claim-pending-podcasts)
    try await app.test(
      .GET,
      "claim-pending-podcasts/\(code)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.temporaryRedirect)
        let location = res.headers.first(name: .location)!
        expect(location).toEqual("\(self.env.accountDashboardUrl)/connect/podcasts/\(code)")
      },
    )
  }

  func testBlockerConnectValidCode_redirectsToBlockerClaimFunnel() async throws {
    let code = uniqueClaimCode()
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
        expect(location).toEqual("\(self.env.accountDashboardUrl)/connect/blockerConnect/\(code)")
        expect(location).not.toContain("error=")
      },
    )
  }

  func testMusicValidCode_redirectsToMusicClaimFunnel() async throws {
    let code = uniqueClaimCode()
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
        expect(location)
          .toEqual("\(self.env.accountDashboardUrl)/connect/music/\(code)") // Account handles login-first
        expect(location).not.toContain("error=")
      },
    )
  }

  func testMusicErrorCodes_landOnAccountRecovery() async throws {
    try await app.test(
      .GET,
      "claim-pending-music/abc",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        let location = res.headers.first(name: .location)!
        expect(location).toEqual("\(self.env.accountDashboardUrl)/connect/music/invalid")
      },
    )

    try await app.test(
      .GET,
      "claim-pending-music/999999",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        let location = res.headers.first(name: .location)!
        expect(location).toEqual("\(self.env.accountDashboardUrl)/connect/music/999999")
      },
    )
  }

  func testNewStyleClaim_selfCorrectsMismatchedRedirectRoute() async throws {
    let code = uniqueClaimCode()
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    try await self.createClaim(.music, device.id, code: code) // <- a music code...

    try await app.test(
      .GET,
      "claim-pending-blocker/\(code)", // ...reached through the blocker redirect route
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.temporaryRedirect)
        let location = res.headers.first(name: .location)!
        expect(location)
          .toEqual("\(self.env.accountDashboardUrl)/connect/music/\(code)") // routed by claim intent; Account handles login-first
        expect(location).not.toContain("error=")
      },
    )
  }

  func testCutoverDisabled_preservesLegacyRedirect() async throws {
    let device = try await self.db.create(IOSDevice.random)
    let claim = try await self.createClaim(.blockerConnect, device.id)

    let originalContext = self.app.context
    var legacyContext = originalContext
    legacyContext.env.accountPairingRedirectsEnabled = false
    self.app.context = legacyContext
    defer { self.app.context = originalContext }

    try await app.test(
      .GET,
      "claim-pending-blocker/\(claim.code)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        let location = res.headers.first(name: .location)!
        expect(location).toContain("\(self.env.dashboardUrl)/signup")
        expect(location).toContain("claimPendingBlocker=\(claim.code)")
        expect(location).toContain("redirect=/claim-blocker-device/\(claim.code)/claim")
      },
    )
  }

  func testNewStyleClaim_matchingRouteUsesClaimIntent() async throws {
    let code = uniqueClaimCode()
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
        expect(location).toEqual("\(self.env.accountDashboardUrl)/connect/blockerConnect/\(code)")
        expect(location).not.toContain("error=")
      },
    )
  }
}
