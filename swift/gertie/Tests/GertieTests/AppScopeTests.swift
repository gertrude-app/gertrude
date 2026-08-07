import Gertie
import XCTest
import XExpect

final class AppScopeTests: XCTestCase {
  func testNormalizedStripsSingleLeadingDotFromBundleId() {
    expect(AppScope.Single.bundleId(".com.apple.sharingd").normalized)
      .toEqual(.bundleId("com.apple.sharingd"))
  }

  func testNormalizedLeavesCleanBundleIdUnchanged() {
    expect(AppScope.Single.bundleId("com.apple.sharingd").normalized)
      .toEqual(.bundleId("com.apple.sharingd"))
  }

  func testNormalizedLeavesIdentifiedAppSlugUnchanged() {
    expect(AppScope.Single.identifiedAppSlug("slack").normalized)
      .toEqual(.identifiedAppSlug("slack"))
  }

  func testNormalizedStripsOnlyOneLeadingDot() {
    expect(AppScope.Single.bundleId("..com.x").normalized)
      .toEqual(.bundleId(".com.x"))
  }
}
