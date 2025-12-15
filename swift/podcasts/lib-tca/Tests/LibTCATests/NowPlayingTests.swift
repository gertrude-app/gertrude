import ComposableArchitecture
import CustomDump
import Dependencies
import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing

@testable import LibTCA

@MainActor struct NowPlayingTests {
  @Test func `pause and resume current playing episode`() async throws {
    let pauseInvocations = LockIsolated(0)
    let playInvocations = LockIsolated<[Episode.ID]>([])
    await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase {
        try fixtures($0)
        try NowPlayingModel.insert {
          NowPlayingModel(episodeId: 3, isPlaying: true)
        }.execute($0)
      }
      $0.audio.pause = { pauseInvocations.withValue { $0 += 1 } }
      $0.audio.play = { ep, _ in playInvocations.withValue { $0.append(ep.id) } }
    } operation: {
      let store = TestStore(initialState: .init(), reducer: NowPlayingFeature.init)
      #expect(dep(\.db).nowPlaying().isPlaying(episodeId: 3) == true)
      #expect(pauseInvocations.value == 0)
      #expect(playInvocations.value.isEmpty)

      let (episode, show) = dep(\.db).episodeWithShow(3)!
      await store.send(.episodePlayPauseTapped(episode, show))

      #expect(pauseInvocations.value == 1)
      #expect(playInvocations.value.isEmpty)
      #expect(dep(\.db).nowPlaying().isPlaying(episodeId: 3) == false)

      await store.send(.episodePlayPauseTapped(episode, show))

      #expect(pauseInvocations.value == 1)
      #expect(playInvocations.value == [.init(3)])
      #expect(dep(\.db).nowPlaying().isPlaying(episodeId: 3) == true)
    }
  }

  @Test func `play current playing episode when not downloaded`() async throws {
    let clock = TestClock()
    let playInvocations = LockIsolated<[Episode.ID]>([])
    let downloadInvocations = LockIsolated<[Episode.ID]>([])
    await withDependencies {
      $0.continuousClock = clock
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase {
        try fixtures($0)
        try NowPlayingModel.insert {
          NowPlayingModel(episodeId: 4, isPlaying: false)
        }.execute($0)
      }
      $0.audio.play = { ep, _ in
        playInvocations.withValue { $0.append(ep.id) }
      }
      $0.podcasts.downloadAudio = { ep in
        downloadInvocations.withValue { $0.append(ep.id) }
        return true
      }
      $0.network.isConnected = { true }
    } operation: {
      let store = TestStore(initialState: .init(), reducer: NowPlayingFeature.init)

      var nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == false)

      let (episode, show) = dep(\.db).episodeWithShow(4)!
      await store.send(.episodePlayPauseTapped(episode, show))

      await clock.advance(by: .seconds(1)) // test pause

      // nothing changes since we start by setting isPlaying to false as baseline
      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == false)
      #expect(nowPlaying?.episode.downloadedAt == nil) // <- not downloaded yet

      await clock.advance(by: .seconds(1))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.downloadedAt == .distantFuture) // <- track download start
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == false)
      #expect(downloadInvocations.value.isEmpty) // but haven't yet started download

      await clock.advance(by: .seconds(1))

      #expect(downloadInvocations.value == [.init(4)]) // <- started download

      await clock.advance(by: .seconds(1))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.downloadedAt == .reference) // <- finished downloading
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == false)
      #expect(playInvocations.value.isEmpty)

      await clock.advance(by: .seconds(1))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(playInvocations.value == [.init(4)]) // <- started playing
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == true)
    }
  }

  @Test func `play current playing episode when not downloaded and no network`() async throws {
    let clock = TestClock()
    let playInvocations = LockIsolated<[Episode.ID]>([])
    let downloadInvocations = LockIsolated<[Episode.ID]>([])
    await withDependencies {
      $0.continuousClock = clock
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase {
        try fixtures($0)
        try NowPlayingModel.insert {
          NowPlayingModel(episodeId: 4, isPlaying: false)
        }.execute($0)
      }
      $0.audio.play = { ep, _ in
        playInvocations.withValue { $0.append(ep.id) }
      }
      $0.podcasts.downloadAudio = { ep in
        downloadInvocations.withValue { $0.append(ep.id) }
        return true
      }
      $0.network.isConnected = { true }
    } operation: {
      let store = TestStore(initialState: .init(), reducer: NowPlayingFeature.init)

      var nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == false)

      let (episode, show) = dep(\.db).episodeWithShow(4)!
      await store.send(.episodePlayPauseTapped(episode, show))

      await clock.advance(by: .seconds(1)) // test pause

      // nothing changes since we start by setting isPlaying to false as baseline
      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == false)
      #expect(nowPlaying?.episode.downloadedAt == nil) // <- not downloaded yet

      await clock.advance(by: .seconds(1))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.downloadedAt == .distantFuture) // <- track download start
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == false)
      #expect(downloadInvocations.value.isEmpty) // but haven't yet started download

      await clock.advance(by: .seconds(1))

      #expect(downloadInvocations.value == [.init(4)]) // <- started download

      await clock.advance(by: .seconds(1))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.downloadedAt == .reference) // <- finished downloading
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == false)
      #expect(playInvocations.value.isEmpty)

      await clock.advance(by: .seconds(1))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(playInvocations.value == [.init(4)]) // <- started playing
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == true)
    }
  }

  @Test func `download error`() async throws {
    let clock = TestClock()
    // let playInvocations = LockIsolated<[Episode.ID]>([])
    let downloadInvocations = LockIsolated<[Episode.ID]>([])
    await withDependencies {
      $0.continuousClock = clock
      $0.defaultDatabase = try! appDatabase {
        try fixtures($0)
        try NowPlayingModel.insert {
          NowPlayingModel(episodeId: 4, isPlaying: false)
        }.execute($0)
      }
      $0.network.isConnected = { true }
      $0.audio.play = { _, _ in fatalError() }
      $0.podcasts.downloadAudio = { ep in
        downloadInvocations.withValue { $0.append(ep.id) }
        return false
      }
    } operation: {
      let store = TestStore(initialState: .init(), reducer: NowPlayingFeature.init)

      var nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == false)
      #expect(nowPlaying?.episode.downloadedAt == nil)

      let (episode, show) = dep(\.db).episodeWithShow(4)!
      await store.send(.episodePlayPauseTapped(episode, show))

      await clock.advance(by: .seconds(2)) // until right before download

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.downloadedAt == .distantFuture) // <- track download start
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == false)
      #expect(downloadInvocations.value.isEmpty) // but haven't yet started download

      await clock.advance(by: .seconds(2))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(downloadInvocations.value == [.init(4)]) // <- tried to download
      #expect(nowPlaying?.episode.downloadedAt == nil) // <- finished downloading, FAILED
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == false)

      await clock.advance(by: .seconds(1))

      await store.receive(.delegate(.alert(lstr(.episodeDownloadFailed))))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == false)
      #expect(nowPlaying?.episode.downloadedAt == nil)
    }
  }

  @Test func `preempt now playing with not downloaded`() async throws {
    let clock = TestClock()
    let playInvocations = LockIsolated<[Episode.ID]>([])
    let downloadInvocations = LockIsolated<[Episode.ID]>([])
    let pauseInvocations = LockIsolated(0)
    await withDependencies {
      $0.date = .constant(.reference)
      $0.continuousClock = clock
      $0.defaultDatabase = try! appDatabase {
        try fixtures($0)
        try NowPlayingModel.insert {
          NowPlayingModel(episodeId: 3, isPlaying: true)
        }.execute($0)
      }
      $0.network.isConnected = { true }
      $0.audio.play = { ep, _ in
        playInvocations.withValue { $0.append(ep.id) }
      }
      $0.audio.pause = { pauseInvocations.withValue { $0 += 1 } }
      $0.podcasts.downloadAudio = { ep in
        downloadInvocations.withValue { $0.append(ep.id) }
        return true
      }

    } operation: {
      let store = TestStore(initialState: .init(), reducer: NowPlayingFeature.init)

      var nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying.isPlaying(episodeId: 3) == true)

      let (episode, show) = dep(\.db).episodeWithShow(4)!
      await store.send(.episodePlayPauseTapped(episode, show))

      await clock.advance(by: .seconds(1))

      // we should have paused episode 3
      #expect(pauseInvocations.value == 1)
      // we set episode 4 to be playing, but start paused so we can download
      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == false)
      #expect(nowPlaying?.episode.downloadedAt == nil) // <- not downloaded yet

      await clock.advance(by: .seconds(1)) // until right before download

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.downloadedAt == .distantFuture) // <- track download start
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == false)
      #expect(downloadInvocations.value.isEmpty) // but haven't yet started download

      await clock.advance(by: .seconds(2))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(downloadInvocations.value == [.init(4)]) // <- tried to download
      #expect(nowPlaying?.episode.downloadedAt == .reference) // <- finished downloading, success
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == false)

      await clock.advance(by: .seconds(1))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying.isPlaying(episodeId: 4) == true)
      #expect(downloadInvocations.value == [.init(4)])
      #expect(playInvocations.value == [.init(4)])
      #expect(nowPlaying.isPlaying(episodeId: 4) == true)
    }
  }

  @Test func `preempt now playing with downloaded`() async throws {
    let clock = TestClock()
    let playInvocations = LockIsolated<[Episode.ID]>([])
    let pauseInvocations = LockIsolated(0)
    await withDependencies {
      $0.date = .constant(.reference)
      $0.continuousClock = clock
      $0.defaultDatabase = try! appDatabase {
        try fixtures($0)
        try NowPlayingModel.insert {
          NowPlayingModel(episodeId: 3, isPlaying: true)
        }.execute($0)
      }
      $0.network.isConnected = { true }
      $0.audio.play = { ep, _ in
        playInvocations.withValue { $0.append(ep.id) }
      }
      $0.audio.pause = { pauseInvocations.withValue { $0 += 1 } }
      $0.podcasts.downloadAudio = { _ in fatalError() }

    } operation: {
      let store = TestStore(initialState: .init(), reducer: NowPlayingFeature.init)

      var nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying.isPlaying(episodeId: 3) == true)

      let (episode, show) = dep(\.db).episodeWithShow(5)!
      await store.send(.episodePlayPauseTapped(episode, show))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.id == 5)
      #expect(nowPlaying?.isPlaying == false)
      // we should have paused episode 3
      #expect(pauseInvocations.value == 1)

      await clock.advance(by: .seconds(1))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying.isPlaying(episodeId: 5) == true)
      #expect(playInvocations.value == [.init(5)])
      #expect(pauseInvocations.value == 1)
    }
  }
}

func fixtures(_ db: Database) throws {
  try Show.insert { [.mock(1), .mock(2)] }.execute(db)
  try Episode
    .insert { [
      .mock(3, showId: 1) { $0.downloadedAt = .reference },
      .mock(4, showId: 1) { $0.downloadedAt = nil },
      .mock(5, showId: 2) { $0.downloadedAt = .reference },
    ] }
    .execute(db)
}
