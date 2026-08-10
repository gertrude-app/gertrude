import XCTest
import XExpect

@testable import Api

final class CampaignAudienceTests: XCTestCase {
  func testPreparationSeparatesDeliveredFromEligibleRecipients() {
    let audience = [
      TestCampaignRecipient(id: "one", value: "One"),
      TestCampaignRecipient(id: "two", value: "Two"),
      TestCampaignRecipient(id: "three", value: "Three"),
    ]

    let prepared = prepareCampaignAudience(
      audience: audience,
      deliveredIds: Set(["two"]),
      identifiedBy: \.id,
    )

    expect(prepared.audience.map(\.id)).toEqual(["one", "two", "three"])
    expect(prepared.alreadyDelivered.map(\.id)).toEqual(["two"])
    expect(prepared.eligible.map(\.id)).toEqual(["one", "three"])
  }

  func testPreparationDeduplicatesByIdentityKeepingFirst() {
    let audience = [
      TestCampaignRecipient(id: "one", value: "First"),
      TestCampaignRecipient(id: "one", value: "Second"),
    ]

    let prepared = prepareCampaignAudience(
      audience: audience,
      deliveredIds: [],
      identifiedBy: \.id,
    )

    expect(prepared.audience).toEqual([.init(id: "one", value: "First")])
    expect(prepared.eligible).toEqual([.init(id: "one", value: "First")])
  }

  func testSelectionAppliesLimitOnlyToEligibleRecipients() {
    let prepared = prepareCampaignAudience(
      audience: [
        TestCampaignRecipient(id: "one", value: "One"),
        TestCampaignRecipient(id: "two", value: "Two"),
        TestCampaignRecipient(id: "three", value: "Three"),
      ],
      deliveredIds: Set(["one"]),
      identifiedBy: \.id,
    )

    expect(prepared.selectedRecipients(limit: nil).map(\.id)).toEqual(["two", "three"])
    expect(prepared.selectedRecipients(limit: 1).map(\.id)).toEqual(["two"])
    expect(prepared.selectedRecipients(limit: -1)).toEqual([])
  }
}

private struct TestCampaignRecipient: Equatable, Sendable {
  var id: String
  var value: String
}
