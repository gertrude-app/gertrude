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
    var isClaimed = false
    var pinChallenge: PinChallengeFeature.State?
    var pendingClaimAfterPin = false
    @Presents var claimFlow: ClaimFlow.State?
    @Presents var pinReset: PinResetFeature.State?
  }

  enum Action: Equatable {
    case view(SettingsView.Event)
    case onAppear
    case delegate(DelegateAction)
    case claimFlow(PresentationAction<ClaimFlow.Action>)
    case pinChallenge(PinChallengeFeature.Action)
    case pinChallengeDismissed
    case pinReset(PresentationAction<PinResetFeature.Action>)
  }

  enum DelegateAction: Equatable {
    case changePinRequested
  }

  @Dependency(\.date) var date
  @Dependency(\.db) var database
  @Dependency(\.keychain) var keychain

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.reclaimableBytes = self.calculateReclaimableBytes()
        state.isClaimed = self.keychain.isClaimed()
        return .none

      case .view(.reclaimStorageTapped):
        self.reclaimAllDownloads()
        state.reclaimableBytes = 0
        return .none

      case .view(.subscribeNowTapped):
        guard self.keychain.hasPincode() else { return .none }
        if state.isClaimed {
          state.claimFlow = ClaimFlow.State(context: .modal, initialStep: .payment)
        } else {
          state.pinChallenge = PinChallengeFeature.State()
        }
        return .none

      case .pinChallenge(.delegate(.verified)):
        state.pendingClaimAfterPin = true
        state.pinChallenge = nil
        return .none

      case .pinChallenge(.delegate(.cancelled)):
        state.pinChallenge = nil
        return .none

      case .pinChallenge:
        return .none

      case .pinChallengeDismissed:
        guard state.pendingClaimAfterPin else { return .none }
        state.pendingClaimAfterPin = false
        state.claimFlow = ClaimFlow.State(context: .modal, initialStep: .showingCode)
        return .none

      case .view(.changePinTapped):
        return .send(.delegate(.changePinRequested))

      case .view(.forgotPinTapped):
        state.pinReset = PinResetFeature.State(isClaimed: self.keychain.isClaimed())
        return .none

      case .pinReset:
        return .none

      case .delegate:
        return .none

      case .claimFlow(.dismiss):
        state.isClaimed = self.keychain.isClaimed()
        return .none

      case .claimFlow:
        return .none
      }
    }
    .ifLet(\.pinChallenge, action: \.pinChallenge) {
      PinChallengeFeature(logBaseId: "8ed78e84") // 8ed78e84-1, 8ed78e84-2
    }
    .ifLet(\.$claimFlow, action: \.claimFlow) {
      ClaimFlow()
    }
    .ifLet(\.$pinReset, action: \.pinReset) {
      PinResetFeature()
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
