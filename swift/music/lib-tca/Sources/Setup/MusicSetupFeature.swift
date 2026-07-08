import ComposableArchitecture
import Foundation
import GertieApp
import MusicRoute

@Reducer
struct MusicSetupFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    var isSubscriptionOfferPresented = false
    var screen = Screen.checking

    enum Screen: Equatable {
      case checking
      case welcome
      case appleMusicPermission
      case appleMusicDenied
      case appleMusicRestricted
      case appleMusicPrivacyAcknowledgementRequired
      case appleMusicStatusUnavailable
      case appleMusicSubscriptionRequired(canShowOffer: Bool)
      case gertrudeConnection(ConnectionStatus)
      case ready(childName: String)
    }

    enum ConnectionStatus: Equatable {
      case checking
      case unclaimed(code: Int, expiresAt: Date)
      case failed
    }
  }

  enum Action: Equatable {
    enum DelegateAction: Equatable {
      case completed(childName: String)
    }

    case appleMusicAuthorizationStatusLoaded(
      AppleMusicAuthorizationStatus,
      showWelcomeIfNeeded: Bool,
    )
    case appleMusicPermissionButtonTapped
    case appleMusicSubscriptionOfferButtonTapped
    case appleMusicSubscriptionOfferPresentationChanged(Bool)
    case appleMusicSubscriptionStatusLoaded(AppleMusicSubscriptionStatus)
    case delegate(DelegateAction)
    case getStartedButtonTapped
    case musicAppStatusFailed(hasStoredConnection: Bool)
    case musicAppStatusLoaded(GetMusicAppStatus.Output)
    case musicAppStatusPollingFailed
    case onAppear
    case refreshConnectionButtonTapped
    case retryButtonTapped
    case settingsButtonTapped
  }

  enum CancelID {
    case musicAppStatusPolling
  }

  @Dependency(\.api) var api
  @Dependency(\.continuousClock) var clock
  @Dependency(\.keychain) var keychain
  @Dependency(\.musicSetup) var musicSetup
  @Dependency(\.systemSettings) var systemSettings

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.screen = .checking
        return self.checkAppleMusic(showWelcomeIfNeeded: true)

      case .retryButtonTapped:
        state.screen = .checking
        return self.checkAppleMusic(showWelcomeIfNeeded: false)

      case .getStartedButtonTapped:
        state.screen = .appleMusicPermission
        return .none

      case .appleMusicPermissionButtonTapped:
        state.screen = .checking
        return .run { send in
          await send(.appleMusicAuthorizationStatusLoaded(
            self.musicSetup.requestAuthorization(),
            showWelcomeIfNeeded: false,
          ))
        }

      case .appleMusicAuthorizationStatusLoaded(let status, let showWelcomeIfNeeded):
        switch status {
        case .authorized:
          return self.checkAppleMusicSubscription()
        case .denied:
          state.screen = .appleMusicDenied
          log(.err, .setup, "e145e6b5")
          return .none
        case .notDetermined:
          state.screen = showWelcomeIfNeeded ? .welcome : .appleMusicPermission
          return .none
        case .restricted:
          state.screen = .appleMusicRestricted
          log(.err, .setup, "c58a3b1d")
          return .none
        case .unknown:
          state.screen = .appleMusicStatusUnavailable
          log(.warn, .setup, "7d682c16")
          return .none
        }

      case .appleMusicSubscriptionStatusLoaded(let status):
        switch status {
        case .canPlayCatalogContent:
          return self.checkGertrudeConnection(&state)
        case .permissionDenied:
          state.screen = .appleMusicDenied
          log(.err, .setup, "8a026e2c")
          return .none
        case .privacyAcknowledgementRequired:
          state.screen = .appleMusicPrivacyAcknowledgementRequired
          log(.warn, .setup, "af4f5985")
          return .none
        case .subscriptionRequired(let canShowOffer):
          state.screen = .appleMusicSubscriptionRequired(canShowOffer: canShowOffer)
          log(.warn, .subs, "bfa4b9e6", detail: "canShowOffer=\(canShowOffer)")
          return .none
        case .unknown:
          state.screen = .appleMusicStatusUnavailable
          log(.warn, .subs, "e1c0d002")
          return .none
        }

      case .appleMusicSubscriptionOfferButtonTapped:
        state.isSubscriptionOfferPresented = true
        log(.info, .subs, "c380387c")
        return .none

      case .appleMusicSubscriptionOfferPresentationChanged(let isPresented):
        state.isSubscriptionOfferPresented = isPresented
        guard !isPresented else { return .none }
        state.screen = .checking
        return self.checkAppleMusicSubscription()

      case .refreshConnectionButtonTapped:
        let hasStoredConnection = self.keychain.loadConnection() != nil
        state.screen = .gertrudeConnection(.checking)
        return .merge(
          .cancel(id: CancelID.musicAppStatusPolling),
          self.fetchMusicAppStatus(hasStoredConnection: hasStoredConnection),
        )

      case .musicAppStatusLoaded(.unclaimed(let code, let expiresAt)):
        self.keychain.deleteConnection()
        let wasAlreadyPolling = state.isShowingUnclaimedConnection
        state.screen = .gertrudeConnection(.unclaimed(code: code, expiresAt: expiresAt))
        return wasAlreadyPolling ? .none : self.startMusicAppStatusPolling()

      case .musicAppStatusLoaded(.claimed(let token, let childId, let childName)):
        self.keychain.save(connection: .init(
          token: token,
          childId: childId,
          childName: childName,
        ))
        state.screen = .ready(childName: childName)
        log(.info, .setup, "aa99a570")
        return .merge(
          .cancel(id: CancelID.musicAppStatusPolling),
          .send(.delegate(.completed(childName: childName))),
        )

      case .musicAppStatusFailed(let hasStored):
        log(.err, .setup, "d3cb7281", detail: "stored=\(hasStored)")
        guard !hasStored else { return .none }
        state.screen = .gertrudeConnection(.failed)
        return .cancel(id: CancelID.musicAppStatusPolling)

      case .musicAppStatusPollingFailed:
        log(.err, .setup, "0f92a6a8")
        return .none

      case .settingsButtonTapped:
        return .run { _ in
          await self.systemSettings.openAppSettings()
        }

      case .delegate:
        return .none
      }
    }
  }

  private func checkAppleMusic(showWelcomeIfNeeded: Bool) -> EffectOf<Self> {
    .run { send in
      await send(.appleMusicAuthorizationStatusLoaded(
        self.musicSetup.authorizationStatus(),
        showWelcomeIfNeeded: showWelcomeIfNeeded,
      ))
    }
  }

  private func checkAppleMusicSubscription() -> EffectOf<Self> {
    .run { send in
      await send(.appleMusicSubscriptionStatusLoaded(self.musicSetup.subscriptionStatus()))
    }
  }

  private func checkGertrudeConnection(_ state: inout State) -> EffectOf<Self> {
    let storedConnection = self.keychain.loadConnection()
    if let storedConnection {
      state.screen = .ready(childName: storedConnection.childName)
      return .merge(
        .send(.delegate(.completed(childName: storedConnection.childName))),
        self.fetchMusicAppStatus(hasStoredConnection: true),
      )
    } else {
      state.screen = .gertrudeConnection(.checking)
      return self.fetchMusicAppStatus(hasStoredConnection: false)
    }
  }

  private func fetchMusicAppStatus(hasStoredConnection: Bool) -> EffectOf<Self> {
    .run { send in
      do {
        try await send(.musicAppStatusLoaded(self.api.getMusicAppStatus()))
      } catch {
        await send(.musicAppStatusFailed(hasStoredConnection: hasStoredConnection))
      }
    }
  }

  private func startMusicAppStatusPolling() -> EffectOf<Self> {
    .run { send in
      while !Task.isCancelled {
        try await self.clock.sleep(for: .seconds(5))
        do {
          try await send(.musicAppStatusLoaded(self.api.getMusicAppStatus()))
        } catch {
          await send(.musicAppStatusPollingFailed)
        }
      }
    }
    .cancellable(id: CancelID.musicAppStatusPolling, cancelInFlight: true)
  }
}

extension MusicSetupFeature.State {
  var isReady: Bool {
    if case .ready = self.screen { true } else { false }
  }

  var isShowingUnclaimedConnection: Bool {
    if case .gertrudeConnection(.unclaimed) = self.screen { true } else { false }
  }
}
