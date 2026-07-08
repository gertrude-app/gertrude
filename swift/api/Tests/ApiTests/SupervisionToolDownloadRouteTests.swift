import DuetSQL
import XCTest
import XCTVapor
import XExpect

@testable import Api

final class SupervisionToolDownloadRouteTests: ApiTestCase, @unchecked Sendable {
  func testValidDownload_redirectsAndLogsEvent() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let parent = try await self.parentWithSubscription { _, sub in
      sub.tier = .light
      sub.stripeId = .init("sub_123")
    }
    let child = try await self.db.create(Child(parentId: parent.id, name: "Test Child"))
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    try await self.createClaim(.blockerSupervise, device.id, child.id, code: code)
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

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
      .orderBy(.createdAt, .asc)
      .all(in: self.db)
    expect(events.count).toEqual(2)
    expect(events[0].domain).toEqual("supervision")
    expect(events[0].detail).toEqual("supervision_tool_download: platform=mac")
    expect(events[1].domain).toEqual("supervision")
    expect(events[1].detail).toEqual("supervision_tool_download: platform=windows")
  }

  func testDownload_blockedForFreeUser() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let parent = try await self.parent()
    let child = try await self.db.create(Child(parentId: parent.id, name: "Test Child"))
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    try await self.createClaim(.blockerSupervise, device.id, child.id, code: code)
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    try await app.test(
      .GET,
      "download-supervision-app/\(code)/platform/mac",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.paymentRequired)
      },
    )
  }
}
