import XCore
import XCTest

final class SequenceTests: XCTestCase {
  func testChunkedEmptyArray() {
    XCTAssertEqual([Int]().chunked(into: 3), [])
  }

  func testChunkedEvenGroups() {
    XCTAssertEqual([1, 2, 3, 4].chunked(into: 2), [[1, 2], [3, 4]])
  }

  func testChunkedIncludesRemainder() {
    XCTAssertEqual([1, 2, 3, 4, 5].chunked(into: 2), [[1, 2], [3, 4], [5]])
  }

  func testChunkedSizeOne() {
    XCTAssertEqual([1, 2, 3].chunked(into: 1), [[1], [2], [3]])
  }

  func testChunkedSizeMatchesArray() {
    XCTAssertEqual([1, 2, 3].chunked(into: 3), [[1, 2, 3]])
  }

  func testChunkedSizeLargerThanArray() {
    XCTAssertEqual([1, 2, 3].chunked(into: 5), [[1, 2, 3]])
  }

  func testChunkedPreservesStringOrder() {
    XCTAssertEqual(["first", "second", "third"].chunked(into: 2), [["first", "second"], ["third"]])
  }
}
