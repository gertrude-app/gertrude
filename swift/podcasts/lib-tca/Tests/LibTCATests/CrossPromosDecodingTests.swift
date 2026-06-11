import Foundation
import PodcastRoute
import Testing

struct CrossPromosDecodingTests {
  @Test func `a campaign with an unknown action type is dropped, the rest survive`() throws {
    let json = """
    { "promos": [
      { "campaignId": "v1", "placement": "amChildHome", "style": "sheet", "headline": "H", "body": "B",
        "primaryCta": { "label": "Go", "action": { "openUrl": { "_0": "https://gertrude.app" } } },
        "dismissable": true },
      { "campaignId": "future", "placement": "amChildHome", "style": "sheet", "headline": "H", "body": "B",
        "primaryCta": { "label": "Go", "action": { "openDeepLink": { "_0": "x" } } },
        "dismissable": true },
      { "campaignId": "v2", "placement": "amOnboardingParent", "style": "screen", "headline": "H", "body": "B",
        "primaryCta": { "label": "Go", "action": { "openAppStoreProduct": { "_0": "123" } } },
        "dismissable": true }
    ] }
    """
    let output = try JSONDecoder().decode(CrossPromos.Output.self, from: Data(json.utf8))
    #expect(output.promos.map(\.campaignId) == [
      "v1",
      "v2",
    ]) // unknown-action campaign dropped, order kept
  }

  @Test func `a fully valid envelope keeps every campaign`() throws {
    let json = """
    { "promos": [
      { "campaignId": "a", "placement": "amChildHome", "style": "sheet", "headline": "H", "body": "B",
        "primaryCta": { "label": "Go", "action": { "openUrl": { "_0": "https://gertrude.app" } } },
        "dismissable": true },
      { "campaignId": "b", "placement": "amOnboardingParent", "style": "screen", "headline": "H", "body": "B",
        "primaryCta": { "label": "Go", "action": { "openAppStoreProduct": { "_0": "123" } } },
        "dismissable": true }
    ] }
    """
    let output = try JSONDecoder().decode(CrossPromos.Output.self, from: Data(json.utf8))
    #expect(output.promos.map(\.campaignId) == ["a", "b"])
  }
}
