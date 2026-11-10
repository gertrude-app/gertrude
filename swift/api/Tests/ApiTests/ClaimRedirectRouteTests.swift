import Dependencies
import DuetSQL
import XCTest
import XCTVapor
import XExpect

@testable import Api

final class ClaimRedirectRouteTests: ApiTestCase, @unchecked Sendable {
  func testValidCode_redirectsToAccountSupervisionFlow() async throws {
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
        expect(location).toEqual(
          "\(self.env.accountDashboardUrl.withoutTrailingSlashes)/signup?redirect=/connect/blockerSupervise/\(code)",
        )
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
        expect(location).toContain("redirect=/connect/blockerSupervise/\(code)")
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
        expect(location).toContain("\(self.env.accountDashboardUrl.withoutTrailingSlashes)/signup")
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
        expect(location).toContain("\(self.env.accountDashboardUrl.withoutTrailingSlashes)/signup")
        expect(location).toContain("error=missing_code")
      },
    )
  }

  func testExpiredUnclaimedCode_redirectsWithExpiredCodeError() async throws {
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
        expect(location).toContain("\(self.env.accountDashboardUrl.withoutTrailingSlashes)/signup")
        expect(location).toContain("error=expired_code")
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
        expect(location).toContain("\(self.env.accountDashboardUrl.withoutTrailingSlashes)/signup")
        expect(location).toContain("redirect=/connect/podcasts/\(code)")
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
        expect(location).toContain("redirect=/connect/podcasts/\(code)")
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
        expect(location).toContain("\(self.env.accountDashboardUrl.withoutTrailingSlashes)/signup")
        expect(location).toContain("redirect=/connect/blockerConnect/\(code)")
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
          .toContain("\(self.env.accountDashboardUrl.withoutTrailingSlashes)/login") // music lands login-first
        expect(location).not.toContain("/signup")
        expect(location).toContain("redirect=/connect/music/\(code)")
        expect(location).not.toContain("error=")
      },
    )
  }

  func testMusicErrorCodes_alsoLandOnLogin() async throws {
    try await app.test(
      .GET,
      "claim-pending-music/abc",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        let location = res.headers.first(name: .location)!
        expect(location)
          .toContain(
            "\(self.env.accountDashboardUrl.withoutTrailingSlashes)/login?error=invalid_code",
          )
      },
    )

    try await app.test(
      .GET,
      "claim-pending-music/999999",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        let location = res.headers.first(name: .location)!
        expect(location)
          .toContain(
            "\(self.env.accountDashboardUrl.withoutTrailingSlashes)/login?error=missing_code",
          )
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
        expect(location).toContain("redirect=/connect/music/\(code)") // routed by claim intent
        expect(location)
          .toContain("\(self.env.accountDashboardUrl.withoutTrailingSlashes)/login") // ...so login-first too
        expect(location).not.toContain("claimPendingBlocker")
        expect(location).not.toContain("error=")
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
        expect(location).toContain("redirect=/connect/blockerConnect/\(code)")
        expect(location).not.toContain("error=")
      },
    )
  }
}
