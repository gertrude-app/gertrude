import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class AppStoreSyncJobTests: ApiTestCase, @unchecked Sendable {
  override func setUp() async throws {
    try await super.setUp()
    try await self.db.delete(all: AppStore.RatingSnapshot.self)
    try await self.db.delete(all: AppStore.Review.self)
    try await self.db.delete(all: AppStore.RatingEvent.self)
  }

  func testUnchangedRatingsDoesNotInsertNewSnapshot() async throws {
    let initialSnapshot = try await self.db.create(AppStore.RatingSnapshot(
      app: .blocker,
      averageRating: 4.5,
      totalCount: 100,
      reviewCount: 0,
    ))

    try await withDependencies {
      $0.db = self.db
      $0.env = .testValue
      $0.slack = .mock
      $0.appStoreConnect.fetchReviews = { _ in [] }
      $0.appStoreConnect.fetchRatings = { _ in
        ITunesRatings(averageUserRating: 4.5, userRatingCount: 100)
      }
    } operation: {
      await AppStoreSyncJob().syncRatings(for: .blocker)

      let snapshots = try await AppStore.RatingSnapshot.query()
        .where(.app == AppStore.GertrudeApp.blocker.rawValue)
        .all(in: self.db)

      expect(snapshots.count).toEqual(1)
      expect(snapshots[0].id).toEqual(initialSnapshot.id)
    }
  }

  func testChangedRatingsInsertsNewSnapshot() async throws {
    let initialSnapshot = try await self.db.create(AppStore.RatingSnapshot(
      app: .blocker,
      averageRating: 4.5,
      totalCount: 100,
      reviewCount: 0,
    ))

    try await withDependencies {
      $0.db = self.db
      $0.env = .testValue
      $0.slack = .mock
      $0.appStoreConnect.fetchReviews = { _ in [] }
      $0.appStoreConnect.fetchRatings = { _ in
        ITunesRatings(averageUserRating: 4.6, userRatingCount: 101)
      }
    } operation: {
      await AppStoreSyncJob().syncRatings(for: .blocker)

      let snapshots = try await AppStore.RatingSnapshot.query()
        .where(.app == AppStore.GertrudeApp.blocker.rawValue)
        .orderBy(.createdAt, .asc)
        .all(in: self.db)

      expect(snapshots.count).toEqual(2)
      expect(snapshots[0].id).toEqual(initialSnapshot.id)
      expect(snapshots[1].averageRating).toEqual(4.6)
      expect(snapshots[1].totalCount).toEqual(101)
    }
  }

  func testInfersRatingEventWhenSnapshotChanges() async throws {
    try await self.db.create(AppStore.RatingSnapshot(
      app: .blocker,
      averageRating: 4.0,
      totalCount: 10,
      reviewCount: 5,
    ))

    for i in 0 ..< 5 {
      try await self.db.create(AppStore.Review(
        appleId: "review-\(i)",
        app: .blocker,
        rating: 4,
        title: "Title",
        body: "Body",
        reviewerNickname: "User",
        territory: "US",
        reviewCreatedAt: .reference,
      ))
    }

    try await withDependencies {
      $0.db = self.db
      $0.env = .testValue
      $0.slack = .mock
      $0.appStoreConnect.fetchReviews = { _ in [] }
      $0.appStoreConnect.fetchRatings = { _ in
        ITunesRatings(averageUserRating: 4.1, userRatingCount: 11)
      }
    } operation: {
      await AppStoreSyncJob().syncRatings(for: .blocker)

      let events = try await AppStore.RatingEvent.query()
        .where(.app == AppStore.GertrudeApp.blocker.rawValue)
        .all(in: self.db)

      expect(events.count).toEqual(1)
      expect(events[0].stars).toEqual(5)
    }
  }
}
