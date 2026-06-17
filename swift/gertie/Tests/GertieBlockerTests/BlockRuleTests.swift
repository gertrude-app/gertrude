import Foundation
import GertieBlocker
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
        #"{"case":"flowTypeIs","value":"browser"}"#,
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

  func testFlowTypeDecodesFromStringFormat() throws {
    let json = Data(#""browser""#.utf8)
    let decoded = try JSONDecoder().decode(FlowType.self, from: json)
    expect(decoded).toEqual(.browser)
  }

  func testFlowTypeDecodesFromLegacyObjectFormat() throws {
    let json = Data(#"{"browser":{}}"#.utf8)
    let decoded = try JSONDecoder().decode(FlowType.self, from: json)
    expect(decoded).toEqual(.browser)
  }

  func testFlowTypeEncodesAsString() throws {
    let data = try JSONEncoder().encode(FlowType.browser)
    expect(String(data: data, encoding: .utf8)!).toEqual(#""browser""#)
  }

  func testBlockRuleDecodesFlowTypeFromBothFormats() throws {
    let objectJson = Data(#"{"case":"flowTypeIs","value":{"browser":{}}}"#.utf8)
    let stringJson = Data(#"{"case":"flowTypeIs","value":"browser"}"#.utf8)
    expect(try JSONDecoder().decode(BlockRule.self, from: objectJson))
      .toEqual(.flowTypeIs(value: .browser))
    expect(try JSONDecoder().decode(BlockRule.self, from: stringJson))
      .toEqual(.flowTypeIs(value: .browser))
  }
}
