import ComposableArchitecture
import Foundation
import LibCore
import LibViews
import PodcastRoute
import SwiftUI

struct OnboardingView: View {
  @Bindable var store: StoreOf<OnboardingFeature>
  @Dependency(\.haptics) var haptics

  var body: some View {
    Group {
      if let claimStore = self.store.scope(state: \.claimFlow, action: \.claimFlow.presented) {
        ClaimFlowView(store: claimStore)
      } else {
        switch self.store.screen {
        case .hiThere:
          WelcomeView {
            self.store.send(.primaryBtnTapped)
          }

        case .areYouTheParent:
          ButtonScreenView(
            text: lstr(.onboardingAreYouParent),
            primary: self.btn(lstr(.onboardingYesParent), action: .primaryBtnTapped),
            secondary: self.btn(lstr(.onboardingNoChild), action: .secondaryBtnTapped),
          )

        case .parentRequired:
          ButtonScreenView(
            text: lstr(.onboardingParentRequired),
            primary: self.btn(lstr(.onboardingContinue), action: .primaryBtnTapped),
          )

        case .connecting:
          LoadingScreenView(text: lstr(.onboardingConnecting))

        case .accountDetected:
          ClaimSuccessView(
            entitlement: nil,
            deviceName: self.autoDetectDeviceName,
            buttonLabel: lstr(.claimContinue),
            onEvent: { _ in self.store.send(.primaryBtnTapped) },
          )

        case .explainAccountRequired:
          ButtonScreenView(
            text: lstr(.onboardingExplainAccount),
            primary: self.btn(lstr(.onboardingGotItNext), action: .primaryBtnTapped),
          )

        case .connectAccountOrSkip:
          ButtonScreenView(
            text: lstr(.onboardingConnectOrSkip),
            primary: self.btn(lstr(.onboardingConnectNow), action: .primaryBtnTapped),
            secondary: self.btn(lstr(.onboardingSkipForNow), action: .secondaryBtnTapped),
          )

        case .explainSetPasscode:
          ButtonScreenView(
            text: lstr(.onboardingExplainPin),
            primary: self.btn(lstr(.onboardingGotItNext), action: .primaryBtnTapped),
          )

        case .strongPasscode:
          ButtonScreenView(
            text: lstr(
              self.store.pinRecoveryAvailable
                ? .onboardingStrongPinConnected
                : .onboardingStrongPin,
            ),
            primary: self.btn(lstr(.onboardingOkLetsGo), animate: false, action: .primaryBtnTapped),
          )
        }
      }
    }
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

  func btn(
    _ text: String,
    animate: Bool = false,
    action: OnboardingFeature.Action,
  ) -> ButtonScreenView.Config {
    .init(text, animate: animate) {
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
