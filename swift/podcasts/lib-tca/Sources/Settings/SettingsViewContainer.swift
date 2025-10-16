import ComposableArchitecture
import LibViews
import SQLiteData
import SwiftUI

struct SettingsViewContainer: View {
  @Bindable var store: StoreOf<SettingsFeature>

  var body: some View {
    SettingsView(
      status: self.store.subscription.viewStatus,
      expiresAt: self.store.subscription.expiresAt,
      onEvent: { self.store.send(.view($0)) }
    )
  }
}
