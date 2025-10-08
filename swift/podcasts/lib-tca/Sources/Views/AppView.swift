import ComposableArchitecture
import LibViews
import SQLiteData
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
        .alert(self.$store.scope(state: \.alert, action: \.alert))
    }
    .overlay(alignment: .bottom) {
      if let nowPlaying = self.store.nowPlaying.data {
        NowPlayingView(
          episode: .init(nowPlaying: nowPlaying),
          show: .init(from: nowPlaying.show),
          minimized: nowPlaying.minimized,
          emit: { event in
            self.store.send(
              .nowPlaying(.view(event)),
              animation: event == .miniPlayerTapped || event == .dismissed
                ? .spring(response: 0.6, dampingFraction: 0.8) : nil
            )
          }
        )
        .opacity(self.store.hideNowPlaying ? 0 : 1)
      }
    }
  }

  init(store: StoreOf<AppReducer>) {
    self.store = store
  }
}
