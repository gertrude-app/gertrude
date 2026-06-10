import ComposableArchitecture
import LibViews
import SQLiteData
import SwiftUI

struct SettingsViewContainer: View {
  @Bindable var store: StoreOf<SettingsFeature>
  @Dependency(\.keychain) var keychain
  @Dependency(\.haptics) var haptics

  var body: some View {
    SettingsView(
      status: self.store.subscription.settingsViewStatus,
      expiresAt: self.store.subscription.expiresAt,
      reclaimableStorageGb: self.reclaimableGb,
      isClaimed: self.store.isClaimed,
      legacyMigrationNag: self.store.subscription.legacyMigrationNag,
      onEvent: { self.store.send(.view($0)) },
    )
    .onAppear { self.store.send(.onAppear) }
    .sheet(
      item: self.$store.scope(state: \.claimFlow, action: \.claimFlow),
      content: { store in
        ClaimFlowView(store: store)
      },
    )
    .sheet(
      isPresented: Binding(
        get: { self.store.pinChallenge != nil },
        set: { if !$0 { self.store.send(.pinChallenge(.pincodeCancelled)) } },
      ),
      onDismiss: { self.store.send(.pinChallengeDismissed) },
      content: {
        PinCodeView(
          mode: .verify(
            self.pincode,
            lockout: self.store.pinChallenge?.lockout,
            onVerify: { self.store.send(.pinChallenge(.pincodeVerified)) },
            onFail: { self.store.send(.pinChallenge(.pincodeFailed)) },
          ),
          onCancel: { self.store.send(.pinChallenge(.pincodeCancelled)) },
          onPrepHaptics: self.haptics.prepare,
        )
      },
    )
  }

  private var pincode: Int {
    if let pin = self.keychain.loadPincode() {
      return pin
    } else {
      log(.error("a58eb83d"), "missing pincode")
      return Int.random(in: 100_000 ... 999_999)
    }
  }

  private var reclaimableGb: Double? {
    let gb = Double(self.store.reclaimableBytes) / 1_000_000_000
    return gb >= 1.0 ? gb : nil
  }
}
