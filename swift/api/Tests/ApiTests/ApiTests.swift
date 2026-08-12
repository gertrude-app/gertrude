import DuetSQL
import Gertie
import MacAppRoute
import Vapor
import XCore
import XCTest
import XCTVapor
import XExpect

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@testable import Api

final class ApiTests: ApiTestCase, @unchecked Sendable {
  let token = UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!

  func testDashboardRoute() async throws {
    let parent = try await self.parent()
    let token = parent.token.value
    var request = URLRequest(url: URL(string: "dashboard/GetIdentifiedApps")!)
    request.httpMethod = "POST"
    request.addValue(token.lowercased, forHTTPHeaderField: "X-AdminToken")
    let route = PairQLRoute.dashboard(.adminAuthed(token.rawValue, .getIdentifiedApps))
    let matched = try PairQLRoute.router.match(request: request)
    expect(matched).toEqual(route)
  }

  func testDuetDeleteReturnsRealNumDeleted() async throws {
    let m1 = Browser(match: .bundleId("m".random))
    let m2 = Browser(match: .bundleId("m".random))
    try await self.db.create([m1, m2])
    let numDeleted = try await self.db.delete(Browser.self, where: .id |=| [m1.id, m2.id])
    expect(numDeleted).toEqual(2)
  }

  func testDuetEscapesStringsProperly() async throws {
    let parent = try await self.db.create(Parent.random)
    let m = try await self.db.create(Api.SecurityEvent(parentId: parent.id, event: "foo'bar"))
    let retrieved = try await self.db.find(m.id)
    expect(retrieved.event).toEqual("foo'bar")
  }

  func testDuetUpsertReturningProjectionDecodesIntoCustomType() async throws {
    let existing = CatalogedApp(
      bundleId: "com.test.existing.".random,
      name: "Existing",
      icon: Data("pretend-icon-bytes".utf8),
      iconContentHash: "hash-abc",
      iconUploadedAt: .reference,
    )
    try await self.db.create(existing)
    let newBundleId = "com.test.new.".random

    let rows = try await self.db.upsert(
      [
        CatalogedApp(bundleId: existing.bundleId, name: "Renamed"), // conflicts -> updates
        CatalogedApp(bundleId: newBundleId, name: "New"), // brand-new insert
      ],
      conflictOn: [.bundleId],
      do: .update(set: [.name]),
      returning: [.id, .bundleId, .iconContentHash, .iconUploadedAt, .iconSourceAppVersion],
      as: CatalogedAppIconInfo.self,
    )

    let byBundle = Dictionary(uniqueKeysWithValues: rows.map { ($0.bundleId, $0) })
    expect(rows.count).toEqual(2)
    // conflicting row returns the existing id (updated, not duplicated) ...
    expect(byBundle[existing.bundleId]?.id).toEqual(existing.id)
    // ... and the projection decodes the preserved icon metadata
    expect(byBundle[existing.bundleId]?.iconContentHash).toEqual("hash-abc")
    expect(byBundle[existing.bundleId]?.iconUploadedAt).toEqual(.reference)
    // brand-new row decodes its (absent) icon metadata as nil
    expect(byBundle[newBundleId]?.iconContentHash).toBeNil()
  }

  func testDateDecodingInPairQL() async throws {
    let input = SaveKey.Input(
      isNew: true,
      id: .init(),
      keychainId: .init(),
      key: .mock,
      comment: nil,
      expiration: Date(timeIntervalSince1970: 0),
    )
    let parent = try await self.parent()
    let token = parent.token.value
    var request = URLRequest(url: URL(string: "dashboard/SaveKey")!)
    request.httpMethod = "POST"
    request.addValue(token.lowercased, forHTTPHeaderField: "X-AdminToken")
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601 // <-- without fractional seconds
    request.httpBody = try encoder.encode(input)

    let route = PairQLRoute.dashboard(.adminAuthed(token.rawValue, .saveKey(input)))
    var matched = try? PairQLRoute.router.match(request: request)
    expect(matched).toEqual(route)

    // now test that it accepts fractional seconds
    let json = String(data: request.httpBody!, encoding: .utf8)!
    let fractional = json.replacingOccurrences(
      of: "1970-01-01T00:00:00Z",
      with: "1970-01-01T00:00:00.000Z",
    )
    expect(json).not.toBe(fractional)
    request = URLRequest(url: URL(string: "dashboard/SaveKey")!)
    request.httpMethod = "POST"
    request.addValue(token.lowercased, forHTTPHeaderField: "X-AdminToken")
    request.httpBody = fractional.data(using: .utf8)!

    matched = try? PairQLRoute.router.match(request: request)
    expect(matched).toEqual(route)
  }

  func testUnauthed() throws {
    let input = ConnectUser.Input(
      verificationCode: 0,
      appVersion: "1.0.0",
      modelIdentifier: "MacBookPro16,1",
      username: "kids",
      fullUsername: "kids",
      numericId: 501,
      serialNumber: "X02VH0Y6JG5J",
    )

    var request = URLRequest(url: URL(string: "macos-app/ConnectUser")!)
    request.httpMethod = "POST"
    request.httpBody = try JSON.encode(input).data(using: .utf8)

    let expectedRoute = PairQLRoute.macApp(.unauthed(.connectUser(input)))
    let matched = try PairQLRoute.router.match(request: request)
    expect(matched).toEqual(expectedRoute)
  }

  func testHeaderAuthed() throws {
    let input = FilterLogs(bundleIds: [:], events: [:])
    var request = URLRequest(url: URL(string: "macos-app/LogFilterEvents")!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(input)
    let route = PairQLRoute.macApp(.userAuthed(self.token, .logFilterEvents(input)))

    let missingHeader = try? PairQLRoute.router.match(request: request)
    expect(missingHeader).toEqual(nil)

    request.addValue(self.token.uuidString, forHTTPHeaderField: "X-UserToken")

    let matched = try PairQLRoute.router.match(request: request)
    expect(matched).toEqual(route)
  }

  func testShortUrlRedirect() async throws {
    let shortUrl = try await self.db.create(ShortUrl(
      target: "https://parents.gertrude.app/children/abc/unlock-requests",
    ))

    try await app.test(
      .GET,
      "short-url/\(shortUrl.shortId)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.temporaryRedirect)
        let location = res.headers.first(name: .location)!
        expect(location).toEqual("https://parents.gertrude.app/children/abc/unlock-requests")
      },
    )
  }

  func testChildContextCreated() async throws {
    let child = try await self.childWithComputer()

    let response = try await PairQLRoute.respond(
      to: .macApp(.userAuthed(
        child.token.value.rawValue,
        .createSuspendFilterRequest_v2(.init(duration: 1, comment: nil)),
      )),
      in: .mock,
    )

    expect(response.status).toEqual(.ok)
    let uuid = try JSONDecoder().decode(UUID.self, from: response.body.data!)
    let req = try await self.db.find(MacApp.SuspendFilterRequest.Id(uuid))
    let computerUser = try await req.computerUser(in: self.db)
    expect(computerUser.childId).toEqual(child.id)
  }
}

extension Context {
  static var mock: Self {
    .mock()
  }

  static func mock(dashboardUrl: String = "/") -> Self {
    .init(
      requestId: "mock-req-id",
      dashboardUrl: dashboardUrl,
      ipAddress: nil,
      telemetry: TelemetryBag(),
    )
  }
}

extension Env {
  static var prodMode: Self {
    var env = Env.fromProcess(mode: .testing)
    env.mode = .prod
    return env
  }
}
