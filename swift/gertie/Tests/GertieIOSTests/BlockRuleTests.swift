import Foundation
import GertieIOS
import XCTest
import XExpect

final class BlockRuleTests: XCTestCase {
  func testWireFormatAndRoundTrip() throws {
    let cases: [(BlockRule, String)] = [
      (
        .hostnameEquals(value: "ex.com"),
        #"{"case":"hostnameEquals","value":"ex.com"}"#,
      ),
      (
        .flowTypeIs(value: .browser),
        #"{"case":"flowTypeIs","value":{"browser":{}}}"#,
      ),
      (
        .both(a: .hostnameEquals(value: "a.com"), b: .targetContains(value: "bad")),
        #"{"a":{"case":"hostnameEquals","value":"a.com"},"b":{"case":"targetContains","value":"bad"},"case":"both"}"#,
      ),
      (
        .unless(
          rule: .hostnameContains(value: "ads"),
          negatedBy: [.hostnameEquals(value: "safe.com")],
        ),
        #"{"case":"unless","negatedBy":[{"case":"hostnameEquals","value":"safe.com"}],"rule":{"case":"hostnameContains","value":"ads"}}"#,
      ),
    ]
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    for (rule, expected) in cases {
      let data = try encoder.encode(rule)
      expect(String(data: data, encoding: .utf8)!).toEqual(expected)
      expect(try JSONDecoder().decode(BlockRule.self, from: data)).toEqual(rule)
    }
  }
}
