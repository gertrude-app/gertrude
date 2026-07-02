import ComposableArchitecture
import Dependencies
import GertieTcaFeatures
import LibViews
import PodcastRoute
import SQLiteData
import SwiftUI

struct AppView: View {
  @Bindable var store: StoreOf<AppReducer>
  @Dependency(\.locale) var locale

  var body: some View {
    NavigationStack {
      EmptyView()
        .navigationDestination(
          item: self.$store.scope(
            state: \.mode?.onboarding,
            action: \.mode.onboarding,
          ),
        ) { store in
          OnboardingView(store: store)
        }
        .navigationDestination(
          item: self.$store.scope(
            state: \.mode?.podcasts,
            action: \.mode.podcasts,
          ),
        ) { store in
          PodcastsView(store: store)
        }
        .alert(self.$store.scope(state: \.alert, action: \.alert))
        .sheet(item: self.crossPromoStore(style: .sheet)) { store in
          CrossPromoView(store: store)
        }
      #if os(iOS)
        .fullScreenCover(item: self.crossPromoStore(style: .screen)) { store in
          CrossPromoView(store: store)
        }
      #endif
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
                ? .nowPlayingSpring : nil,
            )
          },
        )
        .opacity(self.store.hideNowPlaying ? 0 : 1)
      }
    }
    .environment(\.miniNowPlayingVisible, self.miniNowPlayingVisible)
    .environment(\.lang, Lang(locale: self.locale))
    .appUpdateGate(
      store: self.store.scope(state: \.appUpdate, action: \.appUpdate),
      suggestedUpdatesEnabled: self.store.canPresentSuggestedAppUpdate,
    )
  }

  private var miniNowPlayingVisible: Bool {
    self.store.nowPlaying.data?.minimized == true && !self.store.hideNowPlaying
  }

  private func crossPromoStore(
    style: CrossPromoStyle,
  ) -> Binding<StoreOf<CrossPromoFeature>?> {
    let base = self.$store.scope(state: \.crossPromo, action: \.crossPromo)
    return Binding(
      get: { base.wrappedValue.flatMap { $0.campaign.style == style ? $0 : nil } },
      set: { base.wrappedValue = $0 },
    )
  }

  init(store: StoreOf<AppReducer>) {
    self.store = store
  }
}
