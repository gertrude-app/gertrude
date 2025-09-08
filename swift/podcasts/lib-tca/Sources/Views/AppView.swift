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
        ) { store in
          OnboardingView(store: store)
        }
        .navigationDestination(
          item: self.$store.scope(
            state: \.mode?.podcasts,
            action: \.mode.podcasts
          )
        ) { store in
          PodcastsView(store: store)
        }
    }
  }

  init(store: StoreOf<AppReducer>) {
    self.store = store
  }
}
