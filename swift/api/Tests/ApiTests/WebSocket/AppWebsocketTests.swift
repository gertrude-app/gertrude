import Gertie
import XCTest

@testable import Api

final class AppWebsocketTests: XCTestCase {
  func testReportedAppVersionWinsOverStoredVersion() {
    XCTAssertEqual(
      AppWebsocket.resolveAppVersion(reported: "2.9.8", stored: "2.9.7"),
      "2.9.8",
    )
  }

  func testStoredAppVersionSupportsLegacyClients() {
    XCTAssertEqual(
      AppWebsocket.resolveAppVersion(reported: nil, stored: "2.9.7"),
      "2.9.7",
    )
  }

  func testInvalidAppVersionsFallBackToZero() {
    XCTAssertEqual(
      AppWebsocket.resolveAppVersion(reported: "unknown", stored: "invalid"),
      .zero,
    )
  }
}
