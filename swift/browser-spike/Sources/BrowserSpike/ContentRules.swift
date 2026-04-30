import Foundation
import WebKit

enum ContentRules {
  static let identifierBaseline = "spike-baseline-rules"
  static let identifierExpanded = "spike-expanded-rules"

  static let baselineJSON: String = """
  [
    {
      "trigger": { "url-filter": ".*google-analytics\\\\.com.*" },
      "action": { "type": "block" }
    },
    {
      "trigger": {
        "url-filter": ".*youtube\\\\.com.*",
        "unless-domain": ["youtube.com", "youtu.be"]
      },
      "action": { "type": "block" }
    },
    {
      "trigger": {
        "url-filter": ".*httpbin\\\\.org.*",
        "resource-type": ["script"]
      },
      "action": { "type": "block" }
    }
  ]
  """

  static func makeExpandedJSON(noiseRuleCount: Int) -> String {
    var rules: [[String: Any]] = []
    rules.append([
      "trigger": ["url-filter": ".*google-analytics\\.com.*"],
      "action": ["type": "block"],
    ])
    rules.append([
      "trigger": [
        "url-filter": ".*youtube\\.com.*",
        "unless-domain": ["youtube.com", "youtu.be"],
      ],
      "action": ["type": "block"],
    ])
    rules.append([
      "trigger": [
        "url-filter": ".*fakecdn\\.org.*",
        "resource-type": ["script"],
      ],
      "action": ["type": "block"],
    ])
    for i in 0 ..< noiseRuleCount {
      rules.append([
        "trigger": ["url-filter": ".*noise-host-\(i)\\.example.*"],
        "action": ["type": "block"],
      ])
    }
    let data = try! JSONSerialization.data(withJSONObject: rules, options: [])
    return String(data: data, encoding: .utf8)!
  }

  @MainActor
  static func compileAndAttach(
    json: String,
    identifier: String,
    to controller: WKUserContentController,
  ) async throws -> (TimeInterval, WKContentRuleList) {
    let store = WKContentRuleListStore.default()!
    let start = Date()
    let list: WKContentRuleList = try await withCheckedThrowingContinuation { cont in
      store.compileContentRuleList(forIdentifier: identifier, encodedContentRuleList: json) {
        list, error in
        if let error { cont.resume(throwing: error)
          return
        }
        guard let list else {
          cont.resume(throwing: NSError(domain: "spike", code: 1))
          return
        }
        cont.resume(returning: list)
      }
    }
    let elapsed = Date().timeIntervalSince(start)
    controller.removeAllContentRuleLists()
    controller.add(list)
    return (elapsed, list)
  }
}
