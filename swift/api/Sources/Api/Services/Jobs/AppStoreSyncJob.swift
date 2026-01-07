import Dependencies
import DuetSQL
import Queues
import Vapor

struct AppStoreSyncJob: AsyncScheduledJob {
  @Dependency(\.db) var db
  @Dependency(\.env) var env
  @Dependency(\.slack) var slack
  @Dependency(\.appStoreConnect) var appStoreConnect

  func run(context: QueueContext) async throws {
    guard self.env.mode == .prod else { return }
    await self.exec()
  }

  func exec() async {
    for app in AppStore.GertrudeApp.allCases {
      await self.syncReviews(for: app)
      await self.syncRatings(for: app)
    }
  }

  private func syncReviews(for app: AppStore.GertrudeApp) async {
    do {
      let reviews = try await self.appStoreConnect.fetchReviews(app)

      let existingAppleIds = try await Set(
        AppStore.Review.query()
          .where(.app == app.rawValue)
          .all(in: self.db)
          .map(\.appleId),
      )

      for review in reviews {
        if !existingAppleIds.contains(review.id) {
          let newReview = AppStore.Review(
            appleId: review.id,
            app: app,
            rating: review.rating,
            title: review.title,
            body: review.body,
            reviewerNickname: review.reviewerNickname,
            territory: review.territory,
            reviewCreatedAt: review.createdDate,
          )
          try await self.db.create(newReview)
          await self.notifyNewReview(newReview)
        }
      }

    } catch {
      await self.slack
        .error("Failed to sync reviews for \(app.marketingName): \(error)")
    }
  }

  // app store connect api doesn't give great data about rating-only submissions
  // only aggregate data, so we store snapshots in order to infer events
  func syncRatings(for app: AppStore.GertrudeApp) async {
    do {
      let ratings = try await self.appStoreConnect.fetchRatings(app)

      let reviewCount = try await AppStore.Review.query()
        .where(.app == app.rawValue)
        .count(in: self.db)

      let prevSnapshot = try? await AppStore.RatingSnapshot.query()
        .where(.app == app.rawValue)
        .orderBy(.createdAt, .desc)
        .first(in: self.db)

      let snapshotValuesUnchanged = prevSnapshot.map { prev in
        prev.averageRating == ratings.averageUserRating
          && prev.totalCount == ratings.userRatingCount
          && prev.reviewCount == reviewCount
      } ?? false

      if snapshotValuesUnchanged {
        return
      }

      let newSnapshot = try await self.db.create(AppStore.RatingSnapshot(
        app: app,
        averageRating: ratings.averageUserRating,
        totalCount: ratings.userRatingCount,
        reviewCount: reviewCount,
      ))

      if let prevSnapshot {
        let inferred = inferRatingOnlySubmissions(
          prev: RatingSnapshot(
            averageRating: prevSnapshot.averageRating,
            totalCount: prevSnapshot.totalCount,
            reviewCount: prevSnapshot.reviewCount,
          ),
          new: RatingSnapshot(
            averageRating: newSnapshot.averageRating,
            totalCount: newSnapshot.totalCount,
            reviewCount: newSnapshot.reviewCount,
          ),
        )

        if let inferred {
          let roundedStars = max(1, min(5, Int(inferred.stars.rounded())))
          for _ in 0 ..< inferred.count {
            let event = AppStore.RatingEvent(app: app, stars: roundedStars)
            try await self.db.create(event)
            await self.notifyInferredRating(app: app, stars: roundedStars)
          }
        }
      }
    } catch {
      await self.slack
        .error("Failed to sync ratings for \(app.marketingName): \(error)")
    }
  }

  private func notifyNewReview(_ review: AppStore.Review) async {
    let stars = String(repeating: "⭐️", count: review.rating)
    let title = review.title.map { "*\($0)*\n" } ?? ""
    let message = """
    Received new *app store review* for `\(review.app.marketingName)`:
    \(stars)
    \(title)\(review.body)
    _— \(review.reviewerNickname),_ `\(review.territory)`
    """
    await self.slack.internal(.info, message)
  }

  private func notifyInferredRating(app: AppStore.GertrudeApp, stars: Int) async {
    let starEmoji = String(repeating: "⭐️", count: stars)
    let message = "Received new *app store rating* for `\(app.marketingName)`: \(starEmoji)"
    await self.slack.internal(.info, message)
  }
}

struct RatingSnapshot {
  var averageRating: Double
  var totalCount: Int
  var reviewCount: Int
}

struct InferredRating {
  var count: Int
  var stars: Double
}

func inferRatingOnlySubmissions(
  prev: RatingSnapshot,
  new: RatingSnapshot,
) -> InferredRating? {
  let newRatingOnlyCount = new.totalCount - new.reviewCount
  let oldRatingOnlyCount = prev.totalCount - prev.reviewCount
  let ratingOnlyDelta = newRatingOnlyCount - oldRatingOnlyCount

  guard ratingOnlyDelta > 0 else { return nil }

  let oldTotalStars = prev.averageRating * Double(prev.totalCount)
  let newTotalStars = new.averageRating * Double(new.totalCount)
  let inferredStars = (newTotalStars - oldTotalStars) / Double(ratingOnlyDelta)

  return InferredRating(count: ratingOnlyDelta, stars: inferredStars)
}
