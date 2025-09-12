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
    .overlay(alignment: .bottom) {
      if let nowPlaying = self.store.nowPlaying {
        NowPlayingView(
          episode: .init(from: nowPlaying.episode),
          show: .init(from: nowPlaying.show),
          minimized: nowPlaying.minimized,
          emit: { event in
            self.store.send(
              .nowPlaying(.view(event)),
              animation: event == .miniPlayerTapped || event == .dismissed
                ? .spring(response: 0.6, dampingFraction: 0.8) : .default
            )
          }
        )
      }
    }
  }

  init(store: StoreOf<AppReducer>) {
    self.store = store
  }
}
