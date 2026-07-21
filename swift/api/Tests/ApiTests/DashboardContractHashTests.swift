import XCTest

@testable import Api

final class DashboardContractHashTests: XCTestCase {
  func testContractHashIsAvailableAndWellFormed() {
    let hash = DashboardTsCodegenRoute.currentContractHash
    XCTAssertNotNil(hash, "contract hash should compute at static init; if nil, codegen reflection threw")
    XCTAssertEqual(hash?.count, 64, "SHA-256 hex digest is always 64 chars")
    XCTAssertTrue(
      hash?.allSatisfy(\.isHexDigit) ?? false,
      "contract hash should be all hex digits",
    )
  }
}
