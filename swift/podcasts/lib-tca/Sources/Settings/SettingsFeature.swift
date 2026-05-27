import ComposableArchitecture
import LibViews
import SQLiteData
import SwiftUI

@Reducer
struct SettingsFeature {
  @ObservableState
  struct State: Equatable {
    @Fetch(CurrentSubscription()) var subscription: Subscription = .fallback
    var reclaimableBytes: Int = 0
  }

  enum Action: Equatable {
    case view(SettingsView.Event)
    case onAppear
    case delegate(DelegateAction)
  }

  enum DelegateAction: Equatable {
    case changePinRequested
  }

  @Dependency(\.date) var date
  @Dependency(\.db) var database

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.reclaimableBytes = self.calculateReclaimableBytes()
        return .none

      case .view(.reclaimStorageTapped):
        self.reclaimAllDownloads()
        state.reclaimableBytes = 0
        return .none

      case .view(.subscribeNowTapped):
        return .none

      case .view(.changePinTapped):
        return .send(.delegate(.changePinRequested))

      case .delegate:
        return .none
      }
    }
  }

  func calculateReclaimableBytes() -> Int {
    let nowPlayingId = self.database.nowPlaying()?.episode.id
    let now = self.date.now
    let episodes = self.database.tryRead { db in
      try Episode
        .where { $0.downloadedAt.isNot(nil) }
        .where { #sql("\($0.downloadedAt) < \(now)") }
        .where { if let id = nowPlayingId { $0.id.neq(id) } }
        .fetchAll(db)
    }
    return episodes.reduce(0) { $0 + $1.sizeInBytes }
  }

  func reclaimAllDownloads() {
    let nowPlayingId = self.database.nowPlaying()?.episode.id
    let now = self.date.now
    let episodes = self.database.tryRead { db in
      try Episode
        .where { $0.downloadedAt.isNot(nil) }
        .where { #sql("\($0.downloadedAt) < \(now)") }
        .where { if let id = nowPlayingId { $0.id.neq(id) } }
        .fetchAll(db)
    }
    if episodes.isEmpty { return }
    let bytes = episodes.reduce(0) { $0 + $1.sizeInBytes }
    let discardResult = safelyDiscardEpisodeDownloads(
      episodes.map(\.id),
      source: .reclaimStorage,
    )
    log(
      .info("ad696f72"),
      "reclaim storage",
      detail: "requestedEpisodes:\(episodes.count) invalidatedEpisodes:\(discardResult.invalidatedEpisodes.count) protectedEpisodes:\(discardResult.protectedEpisodeIds.count) requestedBytes:\(bytes) invalidatedBytes:\(discardResult.invalidatedEpisodes.reduce(0) { $0 + $1.sizeInBytes })",
    )
  }
}
