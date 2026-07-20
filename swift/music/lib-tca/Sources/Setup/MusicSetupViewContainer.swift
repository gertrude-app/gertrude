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
    case .deviceRecognizedContinueTapped:
      self.store.send(.deviceRecognizedContinueButtonTapped)
    case .explainAccountContinueTapped:
      self.store.send(.explainAccountContinueButtonTapped)
    case .getStartedTapped:
      self.store.send(.getStartedButtonTapped)
    case .nudgeContinueTapped:
      self.store.send(.nudgeContinueButtonTapped)
    case .parentNoTapped:
      self.store.send(.parentNoButtonTapped)
    case .parentYesTapped:
      self.store.send(.parentYesButtonTapped)
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
    case .parentQuestion:
      .parentQuestion
    case .selfManagerNudge:
      .selfManagerNudge
    case .explainAccount:
      .explainAccount(overrideText: self.onboardingConfig?.explainAccountText)
    case .connecting:
      .gertrudeConnection(.checking)
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
      .gertrudeConnection(.unclaimed(code: code, audience: self.claimAudience))
    case .gertrudeConnection(.failed):
      .gertrudeConnection(.failed)
    case .deviceRecognized(let childName):
      .deviceRecognized(childName: childName)
    case .subscriptionRequired(let childName, let remediationUrl):
      .subscriptionRequired(
        childName: childName,
        remediationUrl: remediationUrl,
        overrideText: self.onboardingConfig?.subscriptionRequiredText,
      )
    case .ready:
      .checking
    }
  }
}
