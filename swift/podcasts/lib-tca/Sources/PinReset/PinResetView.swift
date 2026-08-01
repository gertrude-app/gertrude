import ComposableArchitecture
import GertieUI
import LibViews
import SwiftUI

struct PinResetView: View {
  @Bindable var store: StoreOf<PinResetFeature>
  @Dependency(\.haptics) var haptics

  var body: some View {
    Group {
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
        GertieActionScreen(
          message: lstr(.pinResetUnavailableBody),
          icon: .info,
          actions: [
            .link(
              lstr(.pinResetContactSupport),
              destination: URL(string: "https://gertrude.app/contact")!,
            ),
            .button(lstr(.pinCancel)) { self.store.send(.cancelTapped) },
          ],
        )
      }
    }
    .onShake { self.store.send(.receivedShake) }
  }
}

#Preview("PIN recovery unavailable") {
  GertieActionScreen(
    message: lstr(.pinResetUnavailableBody),
    icon: .info,
    actions: [
      .link(
        lstr(.pinResetContactSupport),
        destination: URL(string: "https://gertrude.app/contact")!,
      ),
      .button(lstr(.pinCancel)) {},
    ],
  )
}

#Preview("PIN recovery unavailable (dark)") {
  GertieActionScreen(
    message: lstr(.pinResetUnavailableBody),
    icon: .info,
    actions: [
      .link(
        lstr(.pinResetContactSupport),
        destination: URL(string: "https://gertrude.app/contact")!,
      ),
      .button(lstr(.pinCancel)) {},
    ],
  )
  .preferredColorScheme(.dark)
}
