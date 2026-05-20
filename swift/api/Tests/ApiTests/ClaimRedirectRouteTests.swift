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
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
    ))
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
      claimCode: code,
      claimCodeExpiresAt: .reference - .days(30),
      claimedAt: .reference - .days(30),
    ))
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
      claimCode: code,
      claimCodeExpiresAt: .reference - .days(1),
    ))
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
    _ = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
    ))

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
}
