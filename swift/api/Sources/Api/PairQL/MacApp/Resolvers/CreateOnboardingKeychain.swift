import Dependencies
import DuetSQL
import Gertie
import MacAppRoute

extension CreateOnboardingKeychain: Resolver {
  static func resolve(with domain: Input, in context: MacApp.ChildContext) async throws -> Output {
    let cleaned = domain
      .lowercased()
      .replacingOccurrences(of: "https://", with: "")
      .replacingOccurrences(of: "http://", with: "")
      .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

    guard !cleaned.isEmpty, cleaned.contains(".") else {
      return .failure
    }

    @Dependency(\.keychainCrawler) var crawler
    let reachable = await (try? crawler.validateDomain(cleaned)) ?? false
    guard reachable else { return .failure }

    let childId = context.child.id
    let parentId = context.child.parentId
    @Dependency(\.websockets) var websockets
    @Dependency(\.logger) var logger
    @Dependency(\.slack) var slack

    let task = Task {
      do {
        let existing = try await Keychain.query()
          .where(.parentId == parentId)
          .where(.rootDomain == cleaned)
          .all(in: context.db)
        if !existing.isEmpty { return }

        let response = try await crawler.analyze(cleaned)
        await slack.internal(.info, crawlerSlackMessage(input: cleaned, response: response))
        let keychain = try await context.db.create(Keychain(
          parentId: parentId,
          name: response.name,
          isPublic: false,
          description: response.description,
          rootDomain: cleaned,
        ))
        for recommended in response.recommendedKeys {
          guard let gertieKey = gertieKey(from: recommended) else { continue }
          try await context.db.create(Key(keychainId: keychain.id, key: gertieKey))
        }
        try await context.db.create(ChildKeychain(childId: childId, keychainId: keychain.id))
        try await websockets.send(.userUpdated, to: .user(childId))
      } catch {
        logger.error("11ac6efb keychain crawl failed for `\(cleaned)`: \(error)")
        await slack.error("11ac6efb keychain crawl failed for `\(cleaned)`:\n```\n\(error)\n```")
      }
    }

    if context.env.mode == .test {
      await task.value
    }

    return .success
  }
}

private func crawlerSlackMessage(input: String, response: CrawlerResponse) -> String {
  let fence = "```"
  var lines: [String] = []
  lines.append("Name:        \(response.name)")
  lines.append("Description: \(response.description)")
  lines.append("Domain:      \(response.domain)")
  lines.append("")
  lines.append("Recommended Keys (\(response.recommendedKeys.count)):")
  if response.recommendedKeys.isEmpty {
    lines.append("  (none)")
  } else {
    for key in response.recommendedKeys {
      let comment = key.comment.map { " — \($0)" } ?? ""
      lines.append("  • \(key.type)  \(key.domain)\(comment)")
    }
  }
  lines.append("")
  lines.append("Rejected Domains (\(response.rejectedDomains.count)):")
  if response.rejectedDomains.isEmpty {
    lines.append("  (none)")
  } else {
    for rejected in response.rejectedDomains {
      lines.append("  • \(rejected.domain) — \(rejected.reason)")
    }
  }
  lines.append("")
  lines.append("LLM Flagged (\(response.llmFlagged.count)):")
  if response.llmFlagged.isEmpty {
    lines.append("  (none)")
  } else {
    for domain in response.llmFlagged {
      lines.append("  • \(domain)")
    }
  }
  lines.append("")
  lines.append("Warnings (\(response.warnings.count)):")
  if response.warnings.isEmpty {
    lines.append("  (none)")
  } else {
    for warning in response.warnings {
      lines.append("  • \(warning)")
    }
  }
  return "*Keychain Crawler Response* for `\(input)`\n\(fence)\n"
    + lines.joined(separator: "\n") + "\n\(fence)"
}

private func gertieKey(from recommended: CrawlerResponse.RecommendedKey) -> Gertie.Key? {
  guard let domain = Gertie.Key.Domain(recommended.domain) else { return nil }
  switch recommended.type {
  case "domain":
    return .domain(domain: domain, scope: .webBrowsers)
  case "anySubdomain":
    return .anySubdomain(domain: domain, scope: .webBrowsers)
  default:
    return nil
  }
}
