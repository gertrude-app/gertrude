import ComposableArchitecture
import LibViews
import SwiftUI

struct PinChallengeView: View {
  enum Context: String {
    case addShow
    case settings
  }

  let store: StoreOf<PinChallengeFeature>
  let context: Context
  @Dependency(\.haptics) var haptics
  @Dependency(\.keychain) var keychain

  var body: some View {
    PinCodeView(
      mode: .verify(
        self.pincode,
        lockout: self.store.lockout,
        onVerify: { self.store.send(.pincodeVerified) },
        onFail: { self.store.send(.pincodeFailed) },
      ),
      onCancel: { self.store.send(.pincodeCancelled) },
      onPrepHaptics: self.haptics.prepare,
    )
  }

  private var pincode: Int {
    if let pin = self.keychain.loadPincode() {
      return pin
    } else {
      log(.error("17cb36cc"), "missing pincode", detail: "context:\(self.context.rawValue)")
      return Int.random(in: 100_000 ... 999_999)
    }
  }
}
