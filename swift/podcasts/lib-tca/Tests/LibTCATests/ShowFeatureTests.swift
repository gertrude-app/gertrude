import ComposableArchitecture
import Dependencies
import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing

@testable import LibTCA

@MainActor struct ShowFeatureTests {
  @Test func `archiving during download should not restore downloaded state`() async throws {
    let clock = TestClock()
    let episode = Episode.mock(2, showId: 1)
    let releaseDownload = LockIsolated<CheckedContinuation<Void, Never>?>(nil)

    try? FileManager.default.removeItem(at: episode.localAudioUrl.deletingLastPathComponent())
    defer {
      try? FileManager.default.removeItem(at: episode.localAudioUrl.deletingLastPathComponent())
    }

    try await withDependencies {
      $0.continuousClock = clock
      $0.date = .constant(.reference)
      $0.api.logEvent = { _, _, _, _ in }
      $0.fileSystem.removeItem = { try FileManager.default.removeItem(at: $0) }
      $0.fileSystem.fileExists = { FileManager.default.fileExists(atPath: $0.path) }
      $0.defaultDatabase = try! appDatabase {
        try Show.insert { [Show.mock(1)] }.execute($0)
        try Episode.insert { [episode] }.execute($0)
      }
      $0.podcasts.downloadAudio = { episode in
        do {
          try FileManager.default.createDirectory(
            at: episode.localAudioUrl.deletingLastPathComponent(),
            withIntermediateDirectories: true,
          )
          try Data("ok".utf8).write(to: episode.localAudioUrl)
        } catch {
          return false
        }
        // Pause after the file exists locally but before trackedDownload() records success.
        await withCheckedContinuation {
          releaseDownload.setValue($0)
        }
        return true
      }
      $0.network.isConnected = { true }
    } operation: {
      let show = try await dep(\.db).read { db in try Show.fetchOne(db)! }
      let store = TestStore(initialState: ShowFeature.State(show: show), reducer: ShowFeature.init)
      store.exhaustivity = .off

      // Start the real reducer-driven download flow.
      await store.send(.episodeView(episode.id, .downloadTapped))

      await clock.advance(by: .seconds(3))

      while releaseDownload.value == nil {
        await Task.yield()
      }

      #expect(FileManager.default.fileExists(atPath: episode.localAudioUrl.path))

      // Race the in-flight download with the real archive action, which deletes the file
      // and clears downloadedAt immediately.
      await store.send(.episodeView(episode.id, .toggleArchivedTapped))

      let archivedMidFlight = dep(\.db).tryRead { db in
        try Episode.find(episode.id).fetchOne(db)
      }
      #expect(archivedMidFlight?.isArchived == true)
      #expect(FileManager.default.fileExists(atPath: episode.localAudioUrl.path) == false)

      releaseDownload.withValue {
        $0?.resume()
        $0 = nil
      }

      await clock.advance(by: .seconds(2))
      await store.finish()

      let refreshed = dep(\.db).tryRead { db in
        try Episode.find(episode.id).fetchOne(db)
      }

      // This is the regression: the archive path already won, so the download completion
      // should not be able to stamp the episode back to "downloaded".
      #expect(refreshed?.isArchived == true)
      #expect(refreshed?.downloadedAt == nil)
      #expect(FileManager.default.fileExists(atPath: episode.localAudioUrl.path) == false)
    }
  }

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
