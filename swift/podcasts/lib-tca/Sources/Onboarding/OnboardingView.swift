import ComposableArchitecture
import LibViews
import SwiftUI

struct OnboardingView: View {
  @Bindable var store: StoreOf<OnboardingFeature>

  var body: some View {
    Group {
      switch self.store.screen {
      case .hiThere:
        WelcomeView {
          self.store.send(.primaryBtnTapped)
        }

      case .areYouTheParent:
        ButtonScreenView(
          text: "For the initial setup, we need the parent for a few minutes. Are you the parent?",
          primary: self.btn("Yes, I'm the parent", action: .primaryBtnTapped),
          secondary: self.btn("No, I'm the child", action: .secondaryBtnTapped)
        )

      case .parentRequired:
        ButtonScreenView(
          text: "You'll need your parent to set this up, go get them and click continue.",
          primary: self.btn("Continue", action: .primaryBtnTapped)
        )

      case .explainSetPasscode:
        ButtonScreenView(
          text: "The way this works is you create a PIN that only you (the parent) know. Searching for and subscribing to new podcasts will require this PIN.",
          primary: self.btn("Got it, next", action: .primaryBtnTapped)
        )

      case .strongPasscode:
        ButtonScreenView(
          text: "Make sure your PIN is not something you've used before, and never let your child watch you enter it. Write it down somewhere because there's no way to recover it if you forget it.",
          primary: self.btn("OK, let's go", animate: false, action: .primaryBtnTapped)
        )

      case .passcodeSet(let passcode):
        ButtonScreenView(
          text: "All set! You'll need that PIN whenever you want to add new podcasts. In the free mode, you can subscribe to 1 podcast. To get unlimited subscriptions, upgrade for less than $1 per month.",
          primary: self.btn("Got it, next", action: .finished(passcode))
        )
      }
    }
    .navigationBarBackButtonHidden(true)
    .sheet(isPresented: self.$store.showingPasscodeSheet.sending(\.setShowingPasscodeSheet)) {
      self.store.send(.setShowingPasscodeSheet(false))
    } content: {
      PinCodeView(
        mode: .set(onComplete: { self.store.send(.passcodeSet($0)) }),
        onCancel: { self.store.send(.setShowingPasscodeSheet(false)) },
      )
    }
  }

  func btn(
    _ text: String,
    animate: Bool = false,
    action: OnboardingFeature.Action
  ) -> ButtonScreenView.Config {
    .init(text, animate: animate) {
      self.store.send(action)
    }
  }
}
