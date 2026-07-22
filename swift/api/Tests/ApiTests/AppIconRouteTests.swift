import Foundation
import XCTest
import XCTVapor
import XExpect

@testable import Api

final class AppIconRouteTests: ApiTestCase, @unchecked Sendable {
  func testReturnsIconBytesForKnownHash() async throws {
    let pngBytes = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    let hash = "test-hash-\(UUID().uuidString)"
    try await self.db.create(CatalogedApp(
      bundleId: "com.example.AppIconTest-\(UUID().uuidString)",
      name: "AppIconTest",
      icon: pngBytes,
      iconContentHash: hash,
    ))

    try await app.test(
      .GET,
      "app-icon/\(hash)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.ok)
        expect(res.headers.first(name: .contentType)).toEqual("image/png")
        expect(res.headers.first(name: .cacheControl))
          .toEqual("public, max-age=31536000, immutable")
        expect(res.body.readableBytes).toEqual(pngBytes.count)
      },
    )
  }

  func testReturns404ForUnknownHash() async throws {
    try await app.test(
      .GET,
      "app-icon/missing-\(UUID().uuidString)",
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.notFound)
      },
    )
  }
}
