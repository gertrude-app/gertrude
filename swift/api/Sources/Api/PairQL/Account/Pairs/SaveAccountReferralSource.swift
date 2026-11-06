import PairQL
import TSCodable

struct SaveAccountReferralSource: Pair {
  static let auth: ClientAuth = .parent

  @TSCodable
  enum Source: PairNestable {
    case friendFamily
    case communityGroup
    case searchEngine
    case aiChat
    case appStore
    case socialMedia
    case articleNews
    case other(text: String)
  }

  struct Input: PairInput {
    var source: Source
  }
}

extension SaveAccountReferralSource: Resolver {
  static func resolve(with input: Input, in context: AccountOwnerContext) async throws -> Output {
    let parent = context.accountOwner
    guard !isTestAddress(parent.email.rawValue) else { return .success }
    try await recordReferralSurveyAnswer(
      "referral source survey: \(input.source.surveyDetail)",
      parent: parent,
      context: "account",
      in: context.db,
    )
    return .success
  }
}

extension SaveAccountReferralSource.Source {
  var surveyDetail: String {
    switch self {
    case .friendFamily: return "friend_family"
    case .communityGroup: return "community_group"
    case .searchEngine: return "search_engine"
    case .aiChat: return "ai_chat"
    case .appStore: return "app_store"
    case .socialMedia: return "social_media"
    case .articleNews: return "article_news"
    case .other(let text):
      let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(280)
      return trimmed.isEmpty ? "other" : "other — \"\(trimmed)\""
    }
  }
}
