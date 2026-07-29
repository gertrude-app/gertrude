import XCTest
import XExpect

@testable import Api

final class AppNamingStatsTests: ApiTestCase, @unchecked Sendable {
  func testCountsAppsAtEachDashboardThreshold() async throws {
    try await self.db.delete(all: UnidentifiedApp.self)
    for count in [1, 999, 1000, 10000, 50000, 100_000] {
      try await self.db.create(UnidentifiedApp(bundleId: "com.test.\(count)", count: count))
    }

    let output = try await AppNamingStats.resolve(in: .mock)

    expect(output.total).toEqual(6)
    expect(output.above1k).toEqual(4)
    expect(output.above10k).toEqual(3)
    expect(output.above50k).toEqual(2)
    expect(output.above100k).toEqual(1)
  }
}
