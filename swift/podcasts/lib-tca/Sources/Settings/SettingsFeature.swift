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
    var pinChallenge: PinChallenge?
    var pendingClaimAfterPin = false
    @Presents var claimFlow: ClaimFlow.State?

    struct PinChallenge: Equatable {
      var lockout: Date?
    }
  }

  enum Action: Equatable {
    case view(SettingsView.Event)
    case onAppear
    case delegate(DelegateAction)
    case claimFlow(PresentationAction<ClaimFlow.Action>)
    case pincodeVerified
    case pincodeFailed
    case pincodeCancelled
    case pinChallengeDismissed
  }

  enum DelegateAction: Equatable {
    case changePinRequested
  }

  @Dependency(\.date) var date
  @Dependency(\.db) var database
  @Dependency(\.keychain) var keychain
  @Dependency(\.haptics) var haptics

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
          state.pinChallenge = State.PinChallenge(lockout: .pinLockout())
        }
        return .none

      case .pincodeVerified:
        self.insertAttempt(success: true)
        let wasLockedOut = state.pinChallenge?.lockout != nil
        state.pendingClaimAfterPin = true
        state.pinChallenge = nil
        return .run { _ in
          await self.haptics.notification(.success)
          if wasLockedOut { log(.info("9899b3f4"), "pin lockout cleared") }
        }

      case .pincodeFailed:
        self.insertAttempt(success: false)
        let lockout = Date.pinLockout()
        let newlyLockedOut = lockout != nil && state.pinChallenge?.lockout == nil
        state.pinChallenge?.lockout = lockout
        return .run { _ in
          await self.haptics.notification(.error)
          if newlyLockedOut { log(.info("129a84fd"), "pin lockout set") }
        }

      case .pincodeCancelled:
        state.pinChallenge = nil
        return .none

      case .pinChallengeDismissed:
        guard state.pendingClaimAfterPin else { return .none }
        state.pendingClaimAfterPin = false
        state.claimFlow = ClaimFlow.State(context: .modal, initialStep: .showingCode)
        return .none

      case .view(.changePinTapped):
        return .send(.delegate(.changePinRequested))

      case .delegate:
        return .none

      case .claimFlow(.dismiss):
        state.isClaimed = self.keychain.isClaimed()
        return .none

      case .claimFlow:
        return .none
      }
    }
    .ifLet(\.$claimFlow, action: \.claimFlow) {
      ClaimFlow()
    }
  }

  func insertAttempt(success: Bool) {
    self.database.tryWrite { db in
      try PinAttempt.insert {
        PinAttempt.Draft(success: success, createdAt: self.date.now)
      }.execute(db)
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
