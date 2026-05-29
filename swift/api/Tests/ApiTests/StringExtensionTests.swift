import XCTest
import XExpect

@testable import Api

final class StringExtensionTests: XCTestCase {
  func testWithoutTrailingSlashesRemovesOnlyTrailingSlashes() {
    expect("https://dash.test///".withoutTrailingSlashes).toEqual("https://dash.test")
    expect("/relative/path///".withoutTrailingSlashes).toEqual("/relative/path")
    expect("/".withoutTrailingSlashes).toEqual("")
    expect("https://dash.test".withoutTrailingSlashes).toEqual("https://dash.test")
  }
}
