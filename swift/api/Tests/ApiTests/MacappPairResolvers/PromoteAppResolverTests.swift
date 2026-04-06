import DuetSQL
import XCTest
import XExpect

@testable import Api

final class PromoteAppResolverTests: ApiTestCase, @unchecked Sendable {
  func testPromoteAppTransfersCountToAppBundleId() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: UnidentifiedApp.self)
    try await self.db.create(UnidentifiedApp(bundleId: "com.foo", count: 42))

    let context = Context(requestId: "test", dashboardUrl: "/", ipAddress: nil)

    let output = try await PromoteApp.resolve(
      with: .init(
        bundleId: "com.foo",
        newApp: .init(name: "Foo", slug: "foo", categoryId: nil, launchable: true),
        existingAppId: nil,
      ),
      in: context,
    )

    let bundleId = try await AppBundleId.query()
      .where(.bundleId == "com.foo")
      .first(in: self.db)
    expect(bundleId.count).toEqual(42)
    expect(bundleId.identifiedAppId).toEqual(output.identifiedAppId)

    let unidentified = try await UnidentifiedApp.query()
      .where(.bundleId == "com.foo")
      .all(in: self.db)
    expect(unidentified).toHaveCount(0)
  }

  func testPromoteAppWithExistingIdentifiedApp() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: UnidentifiedApp.self)
    let app = try await self.db
      .create(IdentifiedApp(name: "Bar", slug: "bar", launchable: true))
    try await self.db.create(UnidentifiedApp(bundleId: "com.bar", count: 100))

    let context = Context(requestId: "test", dashboardUrl: "/", ipAddress: nil)

    let output = try await PromoteApp.resolve(
      with: .init(bundleId: "com.bar", newApp: nil, existingAppId: app.id),
      in: context,
    )

    expect(output.identifiedAppId).toEqual(app.id)

    let bundleId = try await AppBundleId.query()
      .where(.bundleId == "com.bar")
      .first(in: self.db)
    expect(bundleId.count).toEqual(100)
  }

  func testPromoteAppWithNoUnidentifiedApp() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: UnidentifiedApp.self)

    let context = Context(requestId: "test", dashboardUrl: "/", ipAddress: nil)

    _ = try await PromoteApp.resolve(
      with: .init(
        bundleId: "com.new",
        newApp: .init(name: "New", slug: "new", categoryId: nil, launchable: true),
        existingAppId: nil,
      ),
      in: context,
    )

    let bundleId = try await AppBundleId.query()
      .where(.bundleId == "com.new")
      .first(in: self.db)
    expect(bundleId.count).toEqual(0)
  }
}
