import ComposableArchitecture
import LibViews
import SQLiteData
import SwiftUI

struct SettingsViewContainer: View {
  @Bindable var store: StoreOf<SettingsFeature>

  var body: some View {
    SettingsView(
      status: self.store.subscription.settingsViewStatus,
      expiresAt: self.store.subscription.expiresAt,
      reclaimableStorageGb: self.reclaimableGb,
      isClaimed: self.store.isClaimed,
      legacyMigrationNag: self.store.subscription.legacyMigrationNag,
      priceTextOverride: self.store.appConfig.accountPriceText,
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
      item: self.$store.scope(state: \.pinReset, action: \.pinReset),
      content: { store in
        PinResetView(store: store)
      },
    )
    .sheet(
      isPresented: Binding(
        get: { self.store.pinChallenge != nil },
        set: { if !$0 { self.store.send(.pinChallenge(.pincodeCancelled)) } },
      ),
      onDismiss: { self.store.send(.pinChallengeDismissed) },
      content: {
        if let store = self.store.scope(state: \.pinChallenge, action: \.pinChallenge) {
          PinChallengeView(store: store, context: .settings)
        }
      },
    )
  }

  private var reclaimableGb: Double? {
    let gb = Double(self.store.reclaimableBytes) / 1_000_000_000
    return gb >= 1.0 ? gb : nil
  }
}
