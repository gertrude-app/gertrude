import ComposableArchitecture
import LibViews
import SwiftUI

struct AppView: View {
  @Bindable var store: StoreOf<AppReducer>

  var body: some View {
    NavigationStack {
      EmptyView()
        .navigationDestination(
          item: self.$store.scope(
            state: \.mode?.onboarding,
            action: \.mode.onboarding
          )
        ) { onboardingStore in
          OnboardingView(store: onboardingStore)
        }
        .navigationDestination(
          item: self.$store.scope(
            state: \.mode?.podcasts,
            action: \.mode.podcasts
          )
        ) { _ in
          Text("Podcasts")
        }
    }
  }

  init(store: StoreOf<AppReducer>) {
    self.store = store
  }
}
