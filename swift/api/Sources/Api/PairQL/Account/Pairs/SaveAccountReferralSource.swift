import PairQL

struct SaveAccountReferralSource: Pair {
  static let auth: ClientAuth = .parent

  enum Source: String, Codable, Sendable, Equatable, CaseIterable {
    case friendFamily = "friend_family"
    case communityGroup = "community_group"
    case searchEngine = "search_engine"
    case aiChat = "ai_chat"
    case appStore = "app_store"
    case socialMedia = "social_media"
    case articleNews = "article_news"
    case other
  }

  struct Input: PairInput {
    var source: Source
    var otherText: String?
  }
}

extension SaveAccountReferralSource: Resolver {
  static func resolve(with input: Input, in context: AccountOwnerContext) async throws -> Output {
    let parent = context.accountOwner
    guard !isTestAddress(parent.email.rawValue) else { return .success }
    let otherText = input.otherText?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .prefix(280)
    let detail = if input.source == .other, let otherText, !otherText.isEmpty {
      "referral source survey: other — \"\(otherText)\""
    } else {
      "referral source survey: \(input.source.rawValue)"
    }
    try await recordReferralSurveyAnswer(
      detail,
      parent: parent,
      context: "account",
      in: context.db,
    )
    return .success
  }
}
