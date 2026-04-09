import XCTest

@testable import App

final class CreateStandardUserTests: XCTestCase {
  func testCancelMarkerClassifiedAsCancelled() {
    let stderr = """
    Creating user record…
    sysadminctl[12345:6789] errAuthorizationCanceled: The authorization was cancelled by the user.
    """
    XCTAssertEqual(
      classifyCreateStandardUserFailure(stderr: stderr),
      .cancelledByAdminAuth,
    )
  }

  func testBareCancelMarkerClassifiedAsCancelled() {
    XCTAssertEqual(
      classifyCreateStandardUserFailure(stderr: "errAuthorizationCanceled"),
      .cancelledByAdminAuth,
    )
  }

  func testEmptyStderrClassifiedAsUnknown() {
    XCTAssertEqual(
      classifyCreateStandardUserFailure(stderr: ""),
      .unknownFailure(stderr: ""),
    )
  }

  func testUnrelatedNoiseClassifiedAsUnknown() {
    let stderr = "IOServiceMatchingfailed for: AppleM2ScalerParavirtDriver\n"
    XCTAssertEqual(
      classifyCreateStandardUserFailure(stderr: stderr),
      .unknownFailure(stderr: stderr),
    )
  }
}
