import XCTest

@testable import Api

final class NtfyClientTests: XCTestCase {
  func testActionsHeaderFromClick() {
    XCTAssertEqual(
      NtfyClient.actionsHeader(click: "https://parents.gertrude.app/security-events"),
      "view, Open, https://parents.gertrude.app/security-events",
    )
  }

  func testActionsHeaderNilForMissingClick() {
    XCTAssertNil(NtfyClient.actionsHeader(click: nil))
    XCTAssertNil(NtfyClient.actionsHeader(click: ""))
  }
}
