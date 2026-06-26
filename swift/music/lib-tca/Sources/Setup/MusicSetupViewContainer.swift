import ComposableArchitecture
import LibViews
import SwiftUI

#if os(iOS) && canImport(MusicKit)
  import MusicKit
#endif

struct MusicSetupViewContainer: View {
  @Bindable var store: StoreOf<MusicSetupFeature>

  var body: some View {
    self.content
      .task {
        guard self.store.screen == .checking else { return }
        _ = self.store.send(.onAppear)
      }
  }

  @ViewBuilder
  private var content: some View {
    #if os(iOS) && canImport(MusicKit)
      MusicSetupView(
        state: self.store.viewState,
        onEvent: self.handleEvent,
      )
      .musicSubscriptionOffer(
        isPresented: self.$store.isSubscriptionOfferPresented
          .sending(\.appleMusicSubscriptionOfferPresentationChanged),
      )
    #else
      MusicSetupView(
        state: self.store.viewState,
        onEvent: self.handleEvent,
      )
    #endif
  }

  private func handleEvent(_ event: MusicSetupViewEvent) {
    switch event {
    case .appleMusicPermissionTapped:
      self.store.send(.appleMusicPermissionButtonTapped)
    case .getStartedTapped:
      self.store.send(.getStartedButtonTapped)
    case .refreshConnectionTapped:
      self.store.send(.refreshConnectionButtonTapped)
    case .retryTapped:
      self.store.send(.retryButtonTapped)
    case .settingsTapped:
      self.store.send(.settingsButtonTapped)
    case .subscriptionOfferTapped:
      self.store.send(.appleMusicSubscriptionOfferButtonTapped)
    }
  }
}

private extension MusicSetupFeature.State {
  var viewState: MusicSetupViewState {
    switch self.screen {
    case .checking:
      .checking
    case .welcome:
      .welcome
    case .appleMusicPermission:
      .appleMusicPermission
    case .appleMusicDenied:
      .appleMusicDenied
    case .appleMusicRestricted:
      .appleMusicRestricted
    case .appleMusicPrivacyAcknowledgementRequired:
      .appleMusicPrivacyAcknowledgementRequired
    case .appleMusicStatusUnavailable:
      .appleMusicStatusUnavailable
    case .appleMusicSubscriptionRequired(let canShowOffer):
      .appleMusicSubscriptionRequired(canShowOffer: canShowOffer)
    case .gertrudeConnection(.checking):
      .gertrudeConnection(.checking)
    case .gertrudeConnection(.unclaimed(let code, _)):
      .gertrudeConnection(.unclaimed(code: code))
    case .gertrudeConnection(.failed):
      .gertrudeConnection(.failed)
    case .ready:
      .checking
    }
  }
}
