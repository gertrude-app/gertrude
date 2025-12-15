import Foundation
import Testing

@testable import LibTCA

@MainActor struct ExtensionsTests {
  @Test func `int redacted`() {
    #expect(123_456.redacted == "123•••")
    #expect(111_111.redacted == "111•••")
    #expect(999_999_999.redacted == "999••••••")
    #expect(12.redacted == "12")
    #expect(123.redacted == "123")
    #expect(1234.redacted == "123•")
    #expect(0.redacted == "0")
    #expect((-123_456).redacted == "-12••••")
  }
}
