import Foundation
import XCTest
import XExpect

@testable import Api

final class EnumCodableFixtureTests: XCTestCase {
  let encoder: JSONEncoder = {
    let e = JSONEncoder()
    e.outputFormatting = .sortedKeys
    e.dateEncodingStrategy = .iso8601
    return e
  }()

  let decoder: JSONDecoder = {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .iso8601
    return d
  }()

  // MARK: - full wire-format tests (critical types)

  func testNotificationMethodConfig() throws {
    let cases: [(Parent.NotificationMethod.Config, String)] = [
      (
        .slack(channelId: "C123", channelName: "alerts", token: "xoxb-tok"),
        #"{"case":"slack","channelId":"C123","channelName":"alerts","token":"xoxb-tok"}"#,
      ),
      (
        .email(email: "a@b.com"),
        #"{"case":"email","email":"a@b.com"}"#,
      ),
      (
        .text(phoneNumber: "+15551234567"),
        #"{"case":"text","phoneNumber":"+15551234567"}"#,
      ),
    ]
    for (value, expected) in cases {
      let data = try encoder.encode(value)
      expect(String(data: data, encoding: .utf8)!).toEqual(expected)
      expect(try self.decoder.decode(Parent.NotificationMethod.Config.self, from: data))
        .toEqual(value)
    }
  }

  func testNotificationMethodConfigDecodesExistingDbJson() throws {
    let slackJson = #"{"case":"slack","channelId":"C999","channelName":"ops","token":"xoxb-abc"}"#
    let slack = try decoder.decode(
      Parent.NotificationMethod.Config.self,
      from: Data(slackJson.utf8),
    )
    expect(slack).toEqual(.slack(channelId: "C999", channelName: "ops", token: "xoxb-abc"))

    let emailJson = #"{"case":"email","email":"parent@example.com"}"#
    let email = try decoder.decode(
      Parent.NotificationMethod.Config.self,
      from: Data(emailJson.utf8),
    )
    expect(email).toEqual(.email(email: "parent@example.com"))

    let textJson = #"{"case":"text","phoneNumber":"+18005551234"}"#
    let text = try decoder.decode(
      Parent.NotificationMethod.Config.self,
      from: Data(textJson.utf8),
    )
    expect(text).toEqual(.text(phoneNumber: "+18005551234"))
  }

  func testSecurityEventsFeedEvent() throws {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let childEvent = SecurityEventsFeed.FeedEvent.child(.init(
      id: .init(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!),
      childId: .init(UUID(uuidString: "00000000-0000-0000-0000-000000000002")!),
      childName: "Franny",
      deviceId: .init(UUID(uuidString: "00000000-0000-0000-0000-000000000003")!),
      deviceName: "iMac",
      event: "keystrokeLineRecorded",
      detail: "some detail",
      explanation: "A keystroke was recorded",
      severity: .medium,
      createdAt: date,
    ))
    let childJson = #"{"case":"child","childId":"00000000-0000-0000-0000-000000000002","childName":"Franny","createdAt":"2023-11-14T22:13:20Z","detail":"some detail","deviceId":"00000000-0000-0000-0000-000000000003","deviceName":"iMac","event":"keystrokeLineRecorded","explanation":"A keystroke was recorded","id":"00000000-0000-0000-0000-000000000001","severity":"medium"}"#
    let childData = try encoder.encode(childEvent)
    expect(String(data: childData, encoding: .utf8)!).toEqual(childJson)
    expect(try self.decoder.decode(SecurityEventsFeed.FeedEvent.self, from: childData))
      .toEqual(childEvent)

    let adminEvent = SecurityEventsFeed.FeedEvent.admin(.init(
      id: .init(UUID(uuidString: "00000000-0000-0000-0000-000000000004")!),
      event: "adminLogin",
      detail: nil,
      explanation: "Admin logged in",
      severity: .all,
      ipAddress: "1.2.3.4",
      createdAt: date,
    ))
    let adminJson = #"{"case":"admin","createdAt":"2023-11-14T22:13:20Z","event":"adminLogin","explanation":"Admin logged in","id":"00000000-0000-0000-0000-000000000004","ipAddress":"1.2.3.4","severity":"all"}"#
    let adminData = try encoder.encode(adminEvent)
    expect(String(data: adminData, encoding: .utf8)!).toEqual(adminJson)
    expect(try self.decoder.decode(SecurityEventsFeed.FeedEvent.self, from: adminData))
      .toEqual(adminEvent)
  }

  // MARK: - round-trip canaries (all other types)

  func testRoundTripCanaries() throws {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let childId = Child.Id(UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!)
    let ssId = Api.Screenshot.Id(UUID(uuidString: "00000000-0000-0000-0000-000000000005")!)
    try self.assertRoundTrip(ClaimIOSDevice.ChildAssignment.existingChild(id: childId))
    try self.assertRoundTrip(DecideFilterSuspensionRequest.Decision.accepted(
      durationInSeconds: 600, extraMonitoring: ".screenshots",
    ))
    try self.assertRoundTrip(DecideFilterSuspensionRequest.Decision.rejected)
    try self.assertRoundTrip(UserActivity.Item.screenshot(.init(
      id: ssId, ids: [ssId], url: "https://example.com/s.png",
      width: 1920, height: 1080, duringSuspension: false,
      flagged: true, createdAt: date, deletedAt: nil,
    )))
    try self.assertRoundTrip(ChildComputerStatus.filterSuspended(resuming: date))
    try self.assertRoundTrip(ChildComputerStatus.offline)
    try self.assertRoundTrip(PlanStatus.free)
    try self.assertRoundTrip(PlanStatus.complimentary)
    try self.assertRoundTrip(PlanStatus.fullTrial(until: date, substrate: nil))
    try self.assertRoundTrip(PlanStatus.fullTrial(
      until: date,
      substrate: .init(tier: .light, status: .current(renewsAt: date)),
    ))
    try self.assertRoundTrip(PlanStatus.light(status: .current(renewsAt: date)))
    try self.assertRoundTrip(PlanStatus.full(status: .pastDue(since: date)))
    try self.assertRoundTrip(GetSubscriptionPanel_v2.Action.startCheckout(tier: .full))
    try self.assertRoundTrip(GetSubscriptionPanel_v2.Action.changeSubscriptionTier(to: .full))
    try self.assertRoundTrip(GetSubscriptionPanel_v2.Action.startFullTrial)
  }

  private func assertRoundTrip<T: Codable & Equatable>(_ value: T) throws {
    let data = try encoder.encode(value)
    let json = String(data: data, encoding: .utf8)!
    XCTAssert(json.contains(#""case":"#), "\(T.self) missing case discriminant in: \(json)")
    let decoded = try decoder.decode(T.self, from: data)
    XCTAssertEqual(value, decoded, "Round-trip failed for \(T.self)")
  }
}
