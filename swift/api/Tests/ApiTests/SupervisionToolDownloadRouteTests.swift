import DuetSQL
import XCTest
import XCTVapor
import XExpect

@testable import Api

final class SupervisionToolDownloadRouteTests: ApiTestCase, @unchecked Sendable {
  func testValidDownload_redirectsAndLogsEvent() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSApp.Device(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.0.0",
      iosVersion: "18.2",
    ))
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
    ))

    try await app.test(
      .GET,
      "download-supervision-app/\(code)/platform/mac",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.temporaryRedirect)
        let location = res.headers.first(name: .location)!
        expect(location).toContain("/releases/supervision/GertrudeSupervisor.zip")
      },
    )

    try await app.test(
      .GET,
      "download-supervision-app/\(code)/platform/windows",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.temporaryRedirect)
        let location = res.headers.first(name: .location)!
        expect(location).toContain("/releases/supervision/GertrudeSupervisor.exe")
      },
    )

    let events = try await IOSEvent.query()
      .where(.deviceId == device.id)
      .all(in: self.db)
    expect(events.count).toEqual(2)
    expect(events[0].kind).toEqual(.supervision)
    expect(events[0].detail).toEqual("supervision_tool_download: platform=mac")
    expect(events[1].kind).toEqual(.supervision)
    expect(events[1].detail).toEqual("supervision_tool_download: platform=windows")
  }
}
