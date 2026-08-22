import Foundation
import MusicRoute
import XCTest
import XExpect

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@testable import Api

final class MusicCrossPromosResolverTests: XCTestCase, @unchecked Sendable {
  let input = CrossPromos.Input(
    deviceId: UUID(1),
    appVersion: "1.1.0",
    modelIdentifier: "iPhone17,1",
    iosVersion: "26.0",
    locale: "en_US",
  )

  func testRouteMatches() throws {
    var request = URLRequest(url: URL(string: "gertrude-music/CrossPromos")!)
    request.httpMethod = "POST"
    request.httpBody = try JSONEncoder().encode(self.input)

    let matched = try PairQLRoute.router.match(request: request)

    expect(matched).toEqual(.music(.unauthed(.crossPromos(self.input))))
  }

  func testReturnsNoCampaignsUntilConfigured() async throws {
    let output = try await CrossPromos.resolve(with: self.input, in: .mock)

    expect(output.promos).toEqual([])
  }
}
