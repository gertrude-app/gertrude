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

  @Test func `empty file download is treated as a failed download`() async throws {
    let clock = TestClock()
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
      $0.network.isConnected = { true }
      $0.audio.play = { _, _ in fatalError() }
      $0.fileSystem.fileExists = { _ in true } // <- file is present
      $0.fileSystem.fileSize = { _ in 0 } // <- but empty, so download must fail validation
      $0.podcasts.downloadAudio = { ep in
        downloadInvocations.withValue { $0.append(ep.id) }
        return true // <- transport says "success", validation has to reject it
      }
    } operation: {
      let store = TestStore(initialState: .init(), reducer: NowPlayingFeature.init)

      var nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == false)
      #expect(nowPlaying?.episode.downloadedAt == nil)

      let (episode, show) = dep(\.db).episodeWithShow(4)!
      await store.send(.episodePlayPauseTapped(episode, show))

      await clock.advance(by: .seconds(2))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.downloadedAt == .distantFuture)
      #expect(downloadInvocations.value.isEmpty)

      await clock.advance(by: .seconds(2))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(downloadInvocations.value == [.init(4)])
      #expect(nowPlaying?.episode.downloadedAt == nil)
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == false)

      await clock.advance(by: .seconds(1))

      await store.receive(.delegate(.alert(lstr(.episodeDownloadFailed))))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.id == 4 && nowPlaying?.isPlaying == false)
      #expect(nowPlaying?.episode.downloadedAt == nil)
    }
  }

  @Test func `concurrent dupe downloads share one in-flight task`() async throws {
    let downloadInvocations = LockIsolated<[Episode.ID]>([])
    let releaseDownload = LockIsolated<CheckedContinuation<Void, Never>?>(nil)

    await withDependencies {
      $0.continuousClock = ImmediateClock()
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase {
        try fixtures($0)
      }
      $0.network.isConnected = { true }
      $0.podcasts.downloadAudio = { ep in
        downloadInvocations.withValue { $0.append(ep.id) }
        await withCheckedContinuation {
          releaseDownload.setValue($0)
        }
        return true
      }
    } operation: {
      guard let episode = dep(\.db).tryRead({ db in
        try Episode.find(Episode.ID(4)).fetchOne(db)!
      }) else {
        Issue.record("missing episode fixture")
        return
      }

      let first = Task { await trackedDownload(episode: episode) }

      while releaseDownload.value == nil {
        await Task.yield()
      }

      let second = Task { await trackedDownload(episode: episode) }
      await Task.yield()

      #expect(downloadInvocations.value == [.init(4)])

      releaseDownload.withValue {
        $0?.resume()
        $0 = nil
      }

      let outcomes = await [first.value, second.value]
      #expect(outcomes.allSatisfy {
        if case .success = $0 {
          true
        } else {
          false
        }
      })
      #expect(downloadInvocations.value == [.init(4)])

      let refreshed = dep(\.db).tryRead { db in
        try Episode.find(Episode.ID(4)).fetchOne(db)
      }
      #expect(refreshed?.downloadedAt == .reference)
    }
  }

  @Test func `resume downloaded episode with empty file re-downloads`() async throws {
    let clock = TestClock()
    let playInvocations = LockIsolated<[Episode.ID]>([])
    let downloadInvocations = LockIsolated<[Episode.ID]>([])
    let fileSize = LockIsolated<Int64>(0)
    await withDependencies {
      $0.continuousClock = clock
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase {
        try fixtures($0)
        try NowPlayingModel.insert {
          NowPlayingModel(episodeId: 5, isPlaying: false)
        }.execute($0)
      }
      $0.network.isConnected = { true }
      $0.audio.play = { ep, _ in
        playInvocations.withValue { $0.append(ep.id) }
      }
      $0.fileSystem.fileExists = { _ in true } // <- looks downloaded at first glance
      $0.fileSystem.fileSize = { _ in fileSize.value } // <- starts empty, flips after re-download
      $0.podcasts.downloadAudio = { ep in
        fileSize.setValue(2) // <- recovery path makes the local file playable again
        downloadInvocations.withValue { $0.append(ep.id) }
        return true
      }
    } operation: {
      let store = TestStore(initialState: .init(), reducer: NowPlayingFeature.init)

      var nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.id == 5 && nowPlaying?.isPlaying == false)
      #expect(nowPlaying?.episode.downloadedAt == .reference)

      let (episode, show) = dep(\.db).episodeWithShow(5)!
      await store.send(.episodePlayPauseTapped(episode, show))

      await clock.advance(by: .seconds(1))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.id == 5 && nowPlaying?.isPlaying == false)
      #expect(nowPlaying?.episode
        .downloadedAt == .distantFuture) // <- resumes by re-downloading first
      #expect(downloadInvocations.value.isEmpty)
      #expect(playInvocations.value.isEmpty)

      await clock.advance(by: .seconds(2))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.downloadedAt == .reference)
      #expect(downloadInvocations.value == [.init(5)])
      #expect(playInvocations.value.isEmpty)

      await clock.advance(by: .seconds(1))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.id == 5 && nowPlaying?.isPlaying == true)
      #expect(downloadInvocations.value == [.init(5)])
      #expect(playInvocations.value == [.init(5), .init(5)])
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

  @Test func `speed button tap persists rate to db and calls audio dep`() async throws {
    let setRateInvocations = LockIsolated<[Double]>([])
    await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase {
        try fixtures($0)
        try NowPlayingModel.insert {
          NowPlayingModel(episodeId: 3, isPlaying: true)
        }.execute($0)
      }
      $0.audio.setPlaybackRate = { rate in setRateInvocations.withValue { $0.append(rate) } }
    } operation: {
      let store = TestStore(initialState: .init(), reducer: NowPlayingFeature.init)

      await store.send(.view(.speedButtonTapped(1.5)))

      #expect(setRateInvocations.value == [1.5])
      let show = dep(\.db).show(id: Show.ID(1))!
      #expect(show.playbackRate == 1.5)
    }
  }

  @Test func `stored show rate is applied when episode starts playing`() async throws {
    let clock = TestClock()
    let setRateInvocations = LockIsolated<[Double]>([])
    let playInvocations = LockIsolated<[Episode.ID]>([])
    let pauseInvocations = LockIsolated(0)
    await withDependencies {
      $0.date = .constant(.reference)
      $0.continuousClock = clock
      $0.defaultDatabase = try! appDatabase {
        try Show.insert { [.mock(1), .mock(2) { $0.playbackRate = 1.5 }] }.execute($0)
        try Episode.insert { [
          .mock(3, showId: 1) { $0.downloadedAt = .reference },
          .mock(4, showId: 1) { $0.downloadedAt = nil },
          .mock(5, showId: 2) { $0.downloadedAt = .reference },
        ] }.execute($0)
        try NowPlayingModel.insert {
          NowPlayingModel(episodeId: 3, isPlaying: true)
        }.execute($0)
      }
      $0.audio.play = { ep, _ in playInvocations.withValue { $0.append(ep.id) } }
      $0.audio.pause = { pauseInvocations.withValue { $0 += 1 } }
      $0.audio.setPlaybackRate = { rate in setRateInvocations.withValue { $0.append(rate) } }
      $0.podcasts.downloadAudio = { _ in fatalError() }
    } operation: {
      let store = TestStore(initialState: .init(), reducer: NowPlayingFeature.init)

      let (episode, show) = dep(\.db).episodeWithShow(5)!
      await store.send(.episodePlayPauseTapped(episode, show))

      #expect(pauseInvocations.value == 1)

      await clock.advance(by: .seconds(1))

      #expect(playInvocations.value == [.init(5)])
      #expect(setRateInvocations.value.contains(1.5))
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

  @Test func `system play event resumes paused episode and seeds progress`() async throws {
    let playInvocations = LockIsolated<[Episode.ID]>([])
    await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase {
        try fixtures($0)
        try NowPlayingModel.insert {
          NowPlayingModel(episodeId: 3, isPlaying: false)
        }.execute($0)
      }
      $0.audio.play = { ep, _ in playInvocations.withValue { $0.append(ep.id) } }
    } operation: {
      let store = TestStore(initialState: .init(), reducer: NowPlayingFeature.init)

      var nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.id == 3 && nowPlaying?.isPlaying == false)

      await store.send(.system(.play(30)))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying.isPlaying(episodeId: 3) == true)
      #expect(nowPlaying?.bufferedProgress == 30)
      let (episode, _) = dep(\.db).episodeWithShow(3)!
      #expect(episode.progress == 30)
      #expect(playInvocations.value == [.init(3)])
    }
  }

  @Test func `audio route removed saves progress and pauses`() async throws {
    await withDependencies {
      $0.defaultInMemoryStorage = .init()
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase {
        try fixtures($0)
        try NowPlayingModel.insert {
          NowPlayingModel(episodeId: 3, isPlaying: true)
        }.execute($0)
      }
      $0.audio.pause = {}
    } operation: {
      let store = TestStore(initialState: .init(), reducer: NowPlayingFeature.init)

      var nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.id == 3 && nowPlaying?.isPlaying == true)

      await store.send(.system(.audioRouteRemoved(position: 60)))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.isPlaying == false)
      #expect(nowPlaying?.bufferedProgress == 60)
      let (episode, _) = dep(\.db).episodeWithShow(3)!
      #expect(episode.progress == 60)
    }
  }

  @Test func `background progress update syncs when moved past threshold`() async throws {
    await withDependencies {
      $0.defaultInMemoryStorage = .init()
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase {
        try fixtures($0)
        try NowPlayingModel.insert {
          NowPlayingModel(episodeId: 3, isPlaying: true)
        }.execute($0)
      }
    } operation: {
      let state = NowPlayingFeature.State()
      state.$appInForeground.withLock { $0 = false }
      let store = TestStore(initialState: state, reducer: NowPlayingFeature.init)

      await store.send(.system(.progressUpdated(13.0)))

      let nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.bufferedProgress == 13.0)
      let (episode, _) = dep(\.db).episodeWithShow(3)!
      #expect(episode.progress == 13.0)
    }
  }

  @Test func `app backgrounded saves current playing position`() async throws {
    await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase {
        try fixtures($0)
        try NowPlayingModel.insert {
          NowPlayingModel(episodeId: 3, isPlaying: true)
        }.execute($0)
      }
      $0.audio.getPlayingPosition = { 42 }
    } operation: {
      let store = TestStore(initialState: .init(), reducer: NowPlayingFeature.init)

      await store.send(.appBackgrounded)
      await store.finish()

      let nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.bufferedProgress == 42)
      let (episode, _) = dep(\.db).episodeWithShow(3)!
      #expect(episode.progress == 42)
    }
  }

  @Test func `interruption ended with shouldResume rewinds 3s and resumes`() async throws {
    let playInvocations = LockIsolated<[Episode.ID]>([])
    let seekInvocations = LockIsolated<[Double]>([])
    await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase {
        try fixtures($0)
        try NowPlayingModel.insert {
          NowPlayingModel(episodeId: 3, isPlaying: false)
        }.execute($0)
      }
      $0.audio.play = { ep, _ in playInvocations.withValue { $0.append(ep.id) } }
      $0.audio.seek = { time in seekInvocations.withValue { $0.append(time) } }
    } operation: {
      let store = TestStore(initialState: .init(), reducer: NowPlayingFeature.init)

      var nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.id == 3 && nowPlaying?.isPlaying == false)

      await store.send(.system(.interruptionEnded(shouldResume: true, from: 60)))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying.isPlaying(episodeId: 3) == true)
      #expect(nowPlaying?.bufferedProgress == 57)
      #expect(seekInvocations.value == [57])
      #expect(playInvocations.value == [.init(3)])
    }
  }

  @Test func `interruption ended without shouldResume is a no-op`() async throws {
    let playInvocations = LockIsolated<[Episode.ID]>([])
    let seekInvocations = LockIsolated<[Double]>([])
    await withDependencies {
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase {
        try fixtures($0)
        try NowPlayingModel.insert {
          NowPlayingModel(episodeId: 3, isPlaying: false, progress: 60)
        }.execute($0)
      }
      $0.audio.play = { ep, _ in playInvocations.withValue { $0.append(ep.id) } }
      $0.audio.seek = { time in seekInvocations.withValue { $0.append(time) } }
    } operation: {
      let store = TestStore(initialState: .init(), reducer: NowPlayingFeature.init)

      var nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.id == 3 && nowPlaying?.isPlaying == false)
      #expect(nowPlaying?.bufferedProgress == 60)

      await store.send(.system(.interruptionEnded(shouldResume: false, from: 60)))

      nowPlaying = dep(\.db).nowPlaying()
      #expect(nowPlaying?.episode.id == 3 && nowPlaying?.isPlaying == false)
      #expect(nowPlaying?.bufferedProgress == 60)
      #expect(seekInvocations.value.isEmpty)
      #expect(playInvocations.value.isEmpty)
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
