import Foundation
import Gertie
import XCTest
import XExpect

@testable import App

final class CodableFixtureTests: XCTestCase {
  let encoder: JSONEncoder = {
    let e = JSONEncoder()
    e.outputFormatting = .sortedKeys
    return e
  }()

  func testRoundTripCanaries() throws {
    try self.assertRoundTrip(FilterState.WithRelativeTimes.suspended(resuming: "5 min"))
    try self.assertRoundTrip(FilterState.WithRelativeTimes.off)
    try self.assertRoundTrip(MenuBarFeature.State.View.enteringConnectionCode)
    try self.assertRoundTrip(MenuBarFeature.State.View.connected(.init(
      filterState: .on, recordingScreen: true, recordingKeystrokes: false,
      adminAttentionRequired: false, updateStatus: nil,
    )))
    try self.assertRoundTrip(AdminWindowFeature.State.HealthCheck.FilterStatus.installed(
      version: "2.5.0", numUserKeys: 42,
    ))
    try self.assertRoundTrip(AdminWindowFeature.Action.View.AdvancedAction.pairqlEndpointSet(
      url: "http://localhost:8080",
    ))
  }

  func testDecodeCanaries() throws {
    try self.assertDecode(MenuBarFeature.Action.self, #"{"case":"resumeFilterClicked"}"#)
    try self.assertDecode(MenuBarFeature.Action.self, #"{"case":"connectSubmit","code":123456}"#)
    try self.assertDecode(
      BlockedRequestsFeature.Action.View.self,
      #"{"case":"filterTextUpdated","text":"google"}"#,
    )
    try self.assertDecode(
      RequestSuspensionFeature.Action.View.self,
      #"{"case":"requestSubmitted","comment":"homework","durationInSeconds":900}"#,
    )
    try self.assertDecode(
      AdminWindowFeature.Action.View.self,
      #"{"case":"advanced","action":{"case":"deleteAllDeviceStorageClicked"}}"#,
    )
    try self.assertDecode(
      OnboardingFeature.Action.View.self,
      #"{"case":"connectChildSubmitted","code":999999}"#,
    )
  }

  private func assertRoundTrip<T: Codable & Equatable>(_ value: T) throws {
    let data = try encoder.encode(value)
    let json = String(data: data, encoding: .utf8)!
    XCTAssert(json.contains(#""case":"#), "\(T.self) missing case discriminant in: \(json)")
    let decoded = try JSONDecoder().decode(T.self, from: data)
    XCTAssertEqual(value, decoded, "Round-trip failed for \(T.self)")
  }

  private func assertDecode(_ type: (some Decodable).Type, _ json: String) throws {
    _ = try JSONDecoder().decode(type, from: Data(json.utf8))
  }
}
