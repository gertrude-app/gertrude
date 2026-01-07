import DuetSQL
import PairQL

struct AppRatings: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    var app: AppStore.GertrudeApp
  }

  struct Output: PairOutput {
    var app: AppStore.GertrudeApp
    var currentAverage: Double
    var totalCount: Int
    var items: [Item]

    // NB: enum w/ payload would be better, but avoiding overhead for admin
    struct Item: PairNestable {
      var type: ItemType
      var id: UUID
      var stars: Int
      var date: Date
      var title: String?
      var body: String?
      var reviewer: String?
      var territory: String?
    }

    enum ItemType: String, PairNestable {
      case review
      case ratingEvent
    }
  }
}

extension AppRatings: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let reviews = try await AppStore.Review.query()
      .where(.app == input.app.rawValue)
      .orderBy(.reviewCreatedAt, .desc)
      .all(in: context.db)

    let ratingEvents = try await AppStore.RatingEvent.query()
      .where(.app == input.app.rawValue)
      .orderBy(.createdAt, .desc)
      .all(in: context.db)

    let latestSnapshot = try? await AppStore.RatingSnapshot.query()
      .where(.app == input.app.rawValue)
      .orderBy(.createdAt, .desc)
      .first(in: context.db)

    let currentAverage = latestSnapshot?.averageRating ?? 0.0
    let totalCount = latestSnapshot?.totalCount ?? 0

    var items: [(date: Date, item: Output.Item)] = []

    for review in reviews {
      items.append((
        date: review.reviewCreatedAt,
        item: .init(
          type: .review,
          id: review.id.rawValue,
          stars: review.rating,
          date: review.reviewCreatedAt,
          title: review.title,
          body: review.body,
          reviewer: review.reviewerNickname,
          territory: review.territory,
        ),
      ))
    }

    for event in ratingEvents {
      items.append((
        date: event.createdAt,
        item: .init(
          type: .ratingEvent,
          id: event.id.rawValue,
          stars: event.stars,
          date: event.createdAt,
        ),
      ))
    }

    items.sort { $0.date > $1.date }

    return .init(
      app: input.app,
      currentAverage: currentAverage,
      totalCount: totalCount,
      items: items.map(\.item),
    )
  }
}
