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
      purchaseInProgress: self.store.purchaseInProgress,
      reclaimableStorageGb: self.reclaimableGb,
      onEvent: { self.store.send(.view($0)) },
    )
    .onAppear { self.store.send(.onAppear) }
  }

  private var reclaimableGb: Double? {
    let gb = Double(self.store.reclaimableBytes) / 1_000_000_000
    return gb >= 1.0 ? gb : nil
  }
}
