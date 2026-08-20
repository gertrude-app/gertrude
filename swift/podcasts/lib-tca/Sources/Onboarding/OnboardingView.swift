import ComposableArchitecture
import Foundation
import GertieUI
import LibCore
import LibViews
import PodcastRoute
import SwiftUI

struct OnboardingView: View {
  @Bindable var store: StoreOf<OnboardingFeature>
  @Dependency(\.haptics) var haptics

  var body: some View {
    self.content
      .navigationBarBackButtonHidden(true)
      .task { self.store.send(.onAppear) }
      .sheet(isPresented: self.$store.showingPasscodeSheet.sending(\.setShowingPasscodeSheet)) {
        self.store.send(.setShowingPasscodeSheet(false))
      } content: {
        PinCodeView(
          mode: .set(
            onComplete: { self.store.send(.passcodeSet($0)) },
            onConfirmFail: { self.store.send(.passcodeConfirmFailed) },
          ),
          onCancel: { self.store.send(.setShowingPasscodeSheet(false)) },
          onPrepHaptics: self.haptics.prepare,
        )
      }
  }

  @ViewBuilder private var content: some View {
    if let claimStore = self.store.scope(state: \.claimFlow, action: \.claimFlow.presented) {
      ClaimFlowView(store: claimStore)
    } else {
      switch self.store.screen {
      case .hiThere:
        PodcastsWelcomeScreen {
          self.store.send(.primaryBtnTapped)
        }

      case .areYouTheParent:
        GertieActionScreen(
          message: lstr(.onboardingAreYouParent),
          actions: [
            self.btn(lstr(.onboardingYesParent), action: .primaryBtnTapped),
            self.btn(lstr(.onboardingNoChild), action: .secondaryBtnTapped),
          ],
          accessibilityIdentifier: "onboarding-screen-are-you-the-parent",
        )

      case .parentRequired:
        GertieActionScreen(
          message: lstr(.onboardingParentRequired),
          action: self.btn(lstr(.onboardingContinue), action: .primaryBtnTapped),
        )

      case .connecting:
        GertieLoadingScreen(message: lstr(.onboardingConnecting))

      case .accountDetected:
        ClaimSuccessView(
          entitlement: nil,
          deviceName: self.autoDetectDeviceName,
          buttonLabel: lstr(.claimContinue),
          onEvent: { _ in self.store.send(.primaryBtnTapped) },
        )

      case .explainAccountRequired:
        GertieActionScreen(
          message: remoteCopy(
            self.store.appConfig.explainAccountText,
            or: lstr(.onboardingExplainAccount),
          ),
          action: self.btn(lstr(.onboardingGotItNext), action: .primaryBtnTapped),
          accessibilityIdentifier: "onboarding-screen-explain-account-required",
        )

      case .connectAccountOrSkip:
        GertieActionScreen(
          message: lstr(.onboardingConnectOrSkip),
          actions: [
            self.btn(lstr(.onboardingConnectNow), action: .primaryBtnTapped),
            self.btn(lstr(.onboardingSkipForNow), action: .secondaryBtnTapped),
          ],
          accessibilityIdentifier: "onboarding-screen-connect-account-or-skip",
        )

      case .explainSetPasscode:
        GertieActionScreen(
          message: lstr(.onboardingExplainPin),
          action: self.btn(lstr(.onboardingGotItNext), action: .primaryBtnTapped),
          accessibilityIdentifier: "onboarding-screen-explain-set-passcode",
        )

      case .strongPasscode:
        GertieActionScreen(
          message: lstr(
            self.store.pinRecoveryAvailable
              ? .onboardingStrongPinConnected
              : .onboardingStrongPin,
          ),
          action: self.btn(lstr(.onboardingOkLetsGo), action: .primaryBtnTapped),
          accessibilityIdentifier: "onboarding-screen-strong-passcode",
        )
      }
    }
  }

  private func btn(
    _ text: String,
    action: OnboardingFeature.Action,
  ) -> GertieScreenAction {
    .button(text) {
      self.store.send(action)
    }
  }

  private var autoDetectDeviceName: String? {
    self.store.trialStatus?.connectedChildName.map {
      String(format: lstr(.claimDeviceName), $0, self.deviceFormFactor)
    }
  }

  private var deviceFormFactor: String {
    UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
  }
}
