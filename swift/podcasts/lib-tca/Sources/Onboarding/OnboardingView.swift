import ComposableArchitecture
import Foundation
import LibViews
import SwiftUI

struct OnboardingView: View {
  @Bindable var store: StoreOf<OnboardingFeature>
  @Dependency(\.haptics) var haptics

  var body: some View {
    Group {
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

      case .explainSetPasscode:
        ButtonScreenView(
          text: lstr(.onboardingExplainPin),
          primary: self.btn(lstr(.onboardingGotItNext), action: .primaryBtnTapped),
        )

      case .strongPasscode:
        ButtonScreenView(
          text: lstr(.onboardingStrongPin),
          primary: self.btn(lstr(.onboardingOkLetsGo), animate: false, action: .primaryBtnTapped),
        )

      case .passcodeSet(let passcode):
        ButtonScreenView(
          text: lstr(.onboardingAllSet),
          primary: self.btn(lstr(.onboardingGotItNext), action: .finished(passcode)),
        )
      }
    }
    .navigationBarBackButtonHidden(true)
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
}
