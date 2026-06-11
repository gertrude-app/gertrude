import ComposableArchitecture
import LibViews
import SwiftUI

struct PinResetView: View {
  @Bindable var store: StoreOf<PinResetFeature>
  @Dependency(\.haptics) var haptics

  var body: some View {
    switch self.store.step {
    case .enterCode:
      PinResetCodeView(
        lockout: self.store.pinChallenge.lockout,
        showError: self.store.showCodeError,
        onSubmit: { self.store.send(.codeSubmitted($0)) },
        onCancel: { self.store.send(.cancelTapped) },
      )
    case .setNewPin:
      PinCodeView(
        mode: .set(
          onComplete: { self.store.send(.newPinSubmitted($0)) },
          onConfirmFail: {},
        ),
        onCancel: { self.store.send(.cancelTapped) },
        onPrepHaptics: self.haptics.prepare,
      )
    case .unclaimed:
      ButtonScreenView(
        text: lstr(.pinResetUnavailableBody),
        primary: .init(
          text: lstr(.pinResetContactSupport),
          type: .link(URL(string: "https://gertrude.app/contact")!),
        ),
        secondary: .init(lstr(.pinCancel), animate: false) { self.store.send(.cancelTapped) },
        screenType: .info,
      )
    }
  }
}

#Preview("PIN recovery unavailable") {
  ButtonScreenView(
    text: lstr(.pinResetUnavailableBody),
    primary: .init(
      text: lstr(.pinResetContactSupport),
      type: .link(URL(string: "https://gertrude.app/contact")!),
    ),
    secondary: .init(lstr(.pinCancel), animate: false) {},
    screenType: .info,
  )
}

#Preview("PIN recovery unavailable (dark)") {
  ButtonScreenView(
    text: lstr(.pinResetUnavailableBody),
    primary: .init(
      text: lstr(.pinResetContactSupport),
      type: .link(URL(string: "https://gertrude.app/contact")!),
    ),
    secondary: .init(lstr(.pinCancel), animate: false) {},
    screenType: .info,
  )
  .preferredColorScheme(.dark)
}
