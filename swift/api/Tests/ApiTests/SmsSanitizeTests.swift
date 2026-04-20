import XCTest

@testable import Api

final class SmsSanitizeTests: XCTestCase {
  func testEnDashToHyphen() {
    XCTAssertEqual(
      "Alice Smith–Laptop".sanitizedForSms(),
      "Alice Smith-Laptop",
    )
  }

  func testDiaeresisStripped() {
    XCTAssertEqual("Raphaël".sanitizedForSms(), "Raphael")
    XCTAssertEqual("Jaël".sanitizedForSms(), "Jael")
    XCTAssertEqual("naïve".sanitizedForSms(), "naive")
    XCTAssertEqual("Zoë".sanitizedForSms(), "Zoe")
  }

  func testGsm7CharsUnchanged() {
    XCTAssertEqual("Clément".sanitizedForSms(), "Clément")
    XCTAssertEqual("François".sanitizedForSms(), "François")
    XCTAssertEqual("Søren".sanitizedForSms(), "Søren")
  }

  func testNonLatinScriptsUnchanged() {
    XCTAssertEqual("이민우".sanitizedForSms(), "이민우")
  }

  func testEmojiUnchanged() {
    XCTAssertEqual("Baby daddy 💀".sanitizedForSms(), "Baby daddy 💀")
  }

  func testSmartQuotesToStraight() {
    XCTAssertEqual("Don\u{2018}t \u{201C}stop\u{201D}".sanitizedForSms(), "Don't \"stop\"")
  }

  func testEmDashAndEllipsis() {
    XCTAssertEqual("A\u{2014}B \u{2026}".sanitizedForSms(), "A-B ...")
  }

  func testNonBreakingSpaceToSpace() {
    XCTAssertEqual("line1\u{00A0}line2".sanitizedForSms(), "line1 line2")
  }

  func testPlainAsciiUnchanged() {
    let ascii = "Hello World 123 !@#$%"
    XCTAssertEqual(ascii.sanitizedForSms(), ascii)
  }

  func testMinusSignToHyphen() {
    XCTAssertEqual("5\u{2212}3".sanitizedForSms(), "5-3")
  }

  func testOtherDashes() {
    XCTAssertEqual("a\u{2010}b\u{2011}c\u{2015}d".sanitizedForSms(), "a-b-c-d")
  }

  func testMoreQuoteVariants() {
    XCTAssertEqual("\u{201A}hi\u{201B}".sanitizedForSms(), "'hi'")
    XCTAssertEqual("\u{201E}test\u{201F}".sanitizedForSms(), "\"test\"")
  }

  func testAccentedLatinStripped() {
    XCTAssertEqual("āčźĀČŹ".sanitizedForSms(), "aczACZ")
    XCTAssertEqual("ẽĩõũ".sanitizedForSms(), "eiou")
  }

  func testGsm7SpecialCharsPreserved() {
    XCTAssertEqual("£100".sanitizedForSms(), "£100")
    XCTAssertEqual("¿Hola?".sanitizedForSms(), "¿Hola?")
    XCTAssertEqual("¡Hola!".sanitizedForSms(), "¡Hola!")
    XCTAssertEqual("§1".sanitizedForSms(), "§1")
    XCTAssertEqual("Über".sanitizedForSms(), "Über")
    XCTAssertEqual("Änderung".sanitizedForSms(), "Änderung")
  }

  func testNonGsm7LatinAccentsStripped() {
    XCTAssertEqual("Sí".sanitizedForSms(), "Si")
  }
}
