import ComposableArchitecture
import LibViews
import SwiftUI

struct AddShowView: View {
  @Bindable var store: StoreOf<AddShowFeature>

  var body: some View {
    Group {
      if !self.store.authorized {
        PinCodeView(
          mode: .verify(
            self.store.passcode,
            lockout: self.store.lockout,
            onVerify: { self.store.send(.passcodeVerified) },
            onFail: { self.store.send(.passcodeFailed) },
          ),
          onCancel: { self.store.send(.passcodeCancelled) },
        )
      } else {
        Text("Authorized")
      }
    }
  }
}
