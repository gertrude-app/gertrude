import ComposableArchitecture
import Foundation
import GertieApp
import LibViews
import MusicRoute

@Reducer
struct MusicSetupFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    var generation: Int?
    var deviceId: UUID?
    var requiresMigrationSetup = false
    var isSubscriptionOfferPresented = false
    var screen = Screen.checking
    var claimAudience = MusicClaimAudience.parentPartner
    var prefetch = Prefetch.loading
    var resumedStoredConnection = false

    enum Prefetch: Equatable {
      case loading
      case loaded(GetMusicAppStatus_v3.Output)
      case failed
    }

    enum Screen: Equatable {
      case checking
      case welcome
      case parentQuestion
      case selfManagerNudge
      case explainAccount
      case connecting
      case gertrudeConnection(ConnectionStatus)
      case deviceRecognized(childName: String)
      case trialStarted(childName: String, expiresAt: Date)
      case musicAccessUnavailable(childName: String)
      case appleMusicPermission
      case requestingAppleMusicPermission
      case appleMusicDenied
      case appleMusicRestricted
      case appleMusicPrivacyAcknowledgementRequired
      case appleMusicStatusUnavailable
      case appleMusicSubscriptionRequired(canShowOffer: Bool)
      case ready(childName: String)
    }

    enum ConnectionStatus: Equatable {
      case checking
      case unclaimed(code: Int, expiresAt: Date)
      case failed
    }
  }

  indirect enum Action: Equatable {
    case response(Int, Action)
    enum DelegateAction: Equatable {
      case completed(childName: String)
    }

    case appleMusicAuthorizationStatusLoaded(AppleMusicAuthorizationStatus)
    case appleMusicPermissionButtonTapped
    case appleMusicSubscriptionOfferButtonTapped
    case appleMusicSubscriptionOfferPresentationChanged(Bool)
    case appleMusicSubscriptionStatusLoaded(AppleMusicSubscriptionStatus)
    case delegate(DelegateAction)
    case deviceRecognizedContinueButtonTapped
    case explainAccountContinueButtonTapped
    case getStartedButtonTapped
    case musicAppStatusFailed(hasStoredConnection: Bool)
    case musicAppStatusLoaded(GetMusicAppStatus_v3.Output)
    case musicAppStatusPollingFailed
    case nudgeContinueButtonTapped
    case migrationCompleted
    case migrationCompletionFailed
    case onAppear
    case parentNoButtonTapped
    case parentYesButtonTapped
    case prefetchStatusFailed
    case prefetchStatusLoaded(GetMusicAppStatus_v3.Output)
    case refreshConnectionButtonTapped
    case retryButtonTapped
    case settingsButtonTapped
    case trialStartedContinueButtonTapped
  }

  enum CancelID {
    case musicAppStatusPolling
    case identityWork
  }

  @Dependency(\.api) var api
  @Dependency(\.continuousClock) var clock
  @Dependency(\.keychain) var keychain
  @Dependency(\.musicSetup) var musicSetup
  @Dependency(\.musicIdentity) var musicIdentity
  @Dependency(\.systemSettings) var systemSettings

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      var action = action
      if case .response(let generation, let response) = action {
        guard state.generation == generation else { return .none }
        action = response
      }
      switch action {
      case .response:
        return .none

      case .onAppear:
        state.screen = .checking
        state.prefetch = .loading
        if state.requiresMigrationSetup {
          return self.fetchMusicAppStatus(hasStoredConnection: false, generation: state.generation)
        }
        // a returning user already has a connection; skip onboarding, resolve Apple Music
        if let connection = self.keychain.loadConnection(),
           state.generation == nil || connection.deviceId == state.deviceId {
          state.resumedStoredConnection = true
          log(.debug, .setup, "9cfe15f7")
          return self.checkAppleMusicAuthorization(generation: state.generation)
        }
        state.screen = .welcome
        log(.info, .setup, "8502ee88")
        return self.prefetchStatus(generation: state.generation)

      case .prefetchStatusLoaded(let output):
        state.prefetch = .loaded(output)
        guard state.screen == .connecting else { return .none }
        return self.advanceFromPrefetch(&state)

      case .prefetchStatusFailed:
        state.prefetch = .failed
        guard state.screen == .connecting else { return .none }
        return self.advanceFromPrefetch(&state)

      case .getStartedButtonTapped:
        return self.advanceFromPrefetch(&state)

      case .parentYesButtonTapped:
        state.claimAudience = .parentPartner
        state.screen = .explainAccount
        log(.info, .setup, "7606fe61")
        return .none

      case .parentNoButtonTapped:
        state.screen = .selfManagerNudge
        log(.info, .setup, "f09d005a")
        return .none

      case .nudgeContinueButtonTapped:
        state.claimAudience = .selfManagement
        state.screen = .explainAccount
        return .none

      case .explainAccountContinueButtonTapped:
        state.screen = .gertrudeConnection(.checking)
        return self.fetchMusicAppStatus(hasStoredConnection: false, generation: state.generation)

      case .deviceRecognizedContinueButtonTapped:
        return self.checkAppleMusicAuthorization(generation: state.generation)

      case .trialStartedContinueButtonTapped:
        return self.checkAppleMusicAuthorization(generation: state.generation)

      case .retryButtonTapped:
        return self.checkAppleMusicAuthorization(generation: state.generation)

      case .appleMusicPermissionButtonTapped:
        state.screen = .requestingAppleMusicPermission
        let generation = state.generation
        return .run { send in
          await send(Self.response(
            generation,
            .appleMusicAuthorizationStatusLoaded(self.musicSetup.requestAuthorization()),
          ))
        }
        .cancellable(id: CancelID.identityWork)

      case .appleMusicAuthorizationStatusLoaded(let status):
        switch status {
        case .authorized:
          return self.checkAppleMusicSubscription(generation: state.generation)
        case .denied:
          state.screen = .appleMusicDenied
          log(.err, .setup, "e145e6b5")
          return .none
        case .notDetermined:
          state.screen = .appleMusicPermission
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
          return self.finishSetup(&state)
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
        return self.checkAppleMusicSubscription(generation: state.generation)

      case .refreshConnectionButtonTapped:
        state.screen = .gertrudeConnection(.checking)
        return .merge(
          .cancel(id: CancelID.musicAppStatusPolling),
          self.fetchMusicAppStatus(hasStoredConnection: false, generation: state.generation),
        )

      case .musicAppStatusLoaded(.unclaimed(let code, let expiresAt)):
        do {
          try self.keychain.delete(.connection)
        } catch {
          state.screen = .gertrudeConnection(.failed)
          return .cancel(id: CancelID.musicAppStatusPolling)
        }
        let wasAlreadyPolling = state.isShowingUnclaimedConnection
        state.screen = .gertrudeConnection(.unclaimed(code: code, expiresAt: expiresAt))
        if !wasAlreadyPolling {
          log(.info, .setup, "ffbbb03c")
        }
        return wasAlreadyPolling ? .none : self
          .startMusicAppStatusPolling(generation: state.generation)

      case .musicAppStatusLoaded(.claimed(let token, let childId, let childName, let entitlement)):
        return self.enterClaimed(
          &state,
          token: token,
          childId: childId,
          childName: childName,
          entitlement: entitlement,
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

      case .migrationCompleted:
        state.requiresMigrationSetup = false
        return self.finishSetup(&state)

      case .migrationCompletionFailed:
        state.screen = .gertrudeConnection(.failed)
        return .none

      case .delegate:
        return .none
      }
    }
  }

  private func advanceFromPrefetch(_ state: inout State) -> EffectOf<Self> {
    switch state.prefetch {
    case .loading:
      state.screen = .connecting
      return .none
    case .loaded(.claimed(let token, let childId, let childName, let entitlement)):
      log(.info, .setup, "9b438d26")
      return self.enterClaimed(
        &state,
        token: token,
        childId: childId,
        childName: childName,
        entitlement: entitlement,
      )
    case .loaded(.unclaimed), .failed:
      state.screen = .parentQuestion
      return .none
    }
  }

  private func enterClaimed(
    _ state: inout State,
    token: UUID,
    childId: UUID,
    childName: String,
    entitlement: MusicSubscriptionState,
  ) -> EffectOf<Self> {
    let wasAlreadyShowing = state.isShowingMusicAccessUnavailable
    if !wasAlreadyShowing {
      do {
        try self.keychain.writeConnection(.init(
          token: token, childId: childId, childName: childName, deviceId: state.deviceId,
        ))
      } catch {
        state.screen = .gertrudeConnection(.failed)
        return .cancel(id: CancelID.musicAppStatusPolling)
      }
      log(.info, .setup, "aa99a570")
    }
    switch entitlement {
    case .active:
      state.screen = .deviceRecognized(childName: childName)
      return .cancel(id: CancelID.musicAppStatusPolling)
    case .trial(let expiresAt):
      state.screen = .trialStarted(childName: childName, expiresAt: expiresAt)
      return .cancel(id: CancelID.musicAppStatusPolling)
    case .unavailable:
      state.screen = .musicAccessUnavailable(childName: childName)
      if !wasAlreadyShowing {
        log(.warn, .subs, "6ad351da")
      }
      return wasAlreadyShowing ? .none : self
        .startMusicAppStatusPolling(generation: state.generation)
    }
  }

  private func finishSetup(_ state: inout State) -> EffectOf<Self> {
    guard let childName = self.keychain.loadConnection()?.childName else {
      state.screen = .gertrudeConnection(.failed)
      return .cancel(id: CancelID.musicAppStatusPolling)
    }
    if state.requiresMigrationSetup {
      let generation = state.generation
      return .run { send in
        do {
          try await self.musicIdentity.completeMigration()
          await send(Self.response(generation, .migrationCompleted))
        } catch {
          await send(Self.response(generation, .migrationCompletionFailed))
        }
      }
      .cancellable(id: CancelID.identityWork)
    }
    state.screen = .ready(childName: childName)
    if !state.resumedStoredConnection {
      log(.info, .setup, "8af8b414")
    }
    return .merge(
      .cancel(id: CancelID.musicAppStatusPolling),
      .send(.delegate(.completed(childName: childName))),
    )
  }

  private static func response(_ generation: Int?, _ action: Action) -> Action {
    generation.map { .response($0, action) } ?? action
  }

  private func prefetchStatus(generation: Int?) -> EffectOf<Self> {
    .run { send in
      do {
        try await send(Self.response(
          generation,
          .prefetchStatusLoaded(self.api.getMusicAppStatus()),
        ))
      } catch {
        await send(Self.response(generation, .prefetchStatusFailed))
      }
    }
    .cancellable(id: CancelID.identityWork)
  }

  private func checkAppleMusicAuthorization(generation: Int?) -> EffectOf<Self> {
    .run { send in
      await send(Self.response(
        generation,
        .appleMusicAuthorizationStatusLoaded(self.musicSetup.authorizationStatus()),
      ))
    }
    .cancellable(id: CancelID.identityWork)
  }

  private func checkAppleMusicSubscription(generation: Int?) -> EffectOf<Self> {
    .run { send in
      await send(Self.response(
        generation,
        .appleMusicSubscriptionStatusLoaded(self.musicSetup.subscriptionStatus()),
      ))
    }
    .cancellable(id: CancelID.identityWork)
  }

  private func fetchMusicAppStatus(hasStoredConnection: Bool, generation: Int?) -> EffectOf<Self> {
    .run { send in
      do {
        try await send(Self.response(
          generation,
          .musicAppStatusLoaded(self.api.getMusicAppStatus()),
        ))
      } catch {
        await send(Self.response(
          generation,
          .musicAppStatusFailed(hasStoredConnection: hasStoredConnection),
        ))
      }
    }
    .cancellable(id: CancelID.identityWork)
  }

  private func startMusicAppStatusPolling(generation: Int?) -> EffectOf<Self> {
    .run { send in
      while !Task.isCancelled {
        try await self.clock.sleep(for: .seconds(5))
        do {
          try await send(Self.response(
            generation,
            .musicAppStatusLoaded(self.api.getMusicAppStatus()),
          ))
        } catch {
          await send(Self.response(generation, .musicAppStatusPollingFailed))
        }
      }
    }
    .cancellable(id: CancelID.musicAppStatusPolling, cancelInFlight: true)
    .cancellable(id: CancelID.identityWork)
  }
}

extension MusicSetupFeature.State {
  var isReady: Bool {
    if case .ready = self.screen { true } else { false }
  }

  var isShowingUnclaimedConnection: Bool {
    if case .gertrudeConnection(.unclaimed) = self.screen { true } else { false }
  }

  var isShowingMusicAccessUnavailable: Bool {
    if case .musicAccessUnavailable = self.screen { true } else { false }
  }
}
