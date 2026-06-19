import Foundation
import Testing

@testable import GertieApp

struct CrossPromoCampaignTests {
  @Test func `decodes a campaign with a free-form string placement`() throws {
    let json = """
    { "campaignId": "v1", "placement": "iosBlockerHome", "style": "sheet", "headline": "H", "body": "B",
      "primaryCta": { "label": "Go", "action": { "openUrl": { "_0": "https://gertrude.app" } } },
      "dismissable": true }
    """
    let campaign = try JSONDecoder().decode(CrossPromoCampaign.self, from: Data(json.utf8))
    #expect(campaign.placement == "iosBlockerHome") // placement is a free-form string now
    #expect(campaign.style == .sheet)
  }

  @Test func `lossy decode drops unknown-action campaigns, keeps the rest`() throws {
    let json = """
    [
      { "campaignId": "v1", "placement": "anyPlacement", "style": "sheet", "headline": "H", "body": "B",
        "primaryCta": { "label": "Go", "action": { "openUrl": { "_0": "https://gertrude.app" } } },
        "dismissable": true },
      { "campaignId": "future", "placement": "anyPlacement", "style": "sheet", "headline": "H", "body": "B",
        "primaryCta": { "label": "Go", "action": { "openDeepLink": { "_0": "x" } } },
        "dismissable": true }
    ]
    """
    let decoded = try JSONDecoder().decode([LossyCrossPromoCampaign].self, from: Data(json.utf8))
    #expect(decoded.compactMap(\.campaign).map(\.campaignId) == ["v1"]) // unknown-action dropped
  }

  @Test func `an unknown placement string is preserved, not dropped`() throws {
    let json = """
    { "campaignId": "x", "placement": "placementNoClientKnows", "style": "screen", "headline": "H", "body": "B",
      "primaryCta": { "label": "Go", "action": { "dismiss": {} } },
      "dismissable": true }
    """
    let decoded = try JSONDecoder().decode(LossyCrossPromoCampaign.self, from: Data(json.utf8))
    #expect(decoded.campaign?.placement == "placementNoClientKnows") // string placement never drops
  }
}
