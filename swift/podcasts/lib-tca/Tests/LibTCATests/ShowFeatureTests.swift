import ComposableArchitecture
import Dependencies
import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing

@testable import LibTCA

@MainActor struct ShowFeatureTests {
  @Test func `marking completed episode as unplayed clears progress and lastPlayedAt`(
  ) async throws {
    let now = Date.reference
    try await withDependencies {
      $0.date = .constant(now)
      $0.defaultDatabase = try! appDatabase {
        try Show.insert { [.mock(1)] }.execute($0)
        try Episode
          .insert { [
            Episode.mock(1, showId: 1) {
              $0.progress = 1234.5
              $0.lastPlayedAt = now - .days(1)
              $0.completedAt = now - .days(1)
            },
          ] }
          .execute($0)
      }
    } operation: {
      let show = try await dep(\.db).read { db in try Show.fetchOne(db)! }
      let store = TestStore(initialState: ShowFeature.State(show: show), reducer: ShowFeature.init)
      store.exhaustivity = .off

      var episode = try await dep(\.db).read { db in try Episode.fetchOne(db)! }
      #expect(episode.completedAt != nil)
      #expect(episode.progress == 1234.5)
      #expect(episode.lastPlayedAt != nil)

      await store.send(.episodeView(episode.id, .toggleCompletedTapped))

      episode = try await dep(\.db).read { db in try Episode.fetchOne(db)! }
      #expect(episode.completedAt == nil)
      #expect(episode.progress == 0)
      #expect(episode.lastPlayedAt == nil)
    }
  }
}
