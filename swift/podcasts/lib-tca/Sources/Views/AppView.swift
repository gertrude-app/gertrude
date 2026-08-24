import ComposableArchitecture
import Dependencies
import GertieApp
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
        .crossPromoPresentations(
          store: self.$store.scope(state: \.crossPromo, action: \.crossPromo),
          onImageLoadFailure: Self.crossPromoImageLoadFailed,
        )
    }
    .alert(self.$store.scope(state: \.alert, action: \.alert))
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
    .killSwitch(
      store: self.store.scope(state: \.killSwitch, action: \.killSwitch),
      suggestedUpdatesEnabled: self.store.canPresentSuggestedKillSwitch,
    )
  }

  private var miniNowPlayingVisible: Bool {
    self.store.nowPlaying.data?.minimized == true && !self.store.hideNowPlaying
  }

  @MainActor
  private static func crossPromoImageLoadFailed(
    _ campaign: CrossPromoCampaign,
    _ image: CrossPromoImage,
    _ error: any Error,
  ) {
    log(
      .warn,
      .setup,
      "af5b46ca",
      detail: "campaign=\(campaign.campaignId) placement=\(campaign.placement) "
        + "url=\(image.url) error=\(error)",
    )
  }

  init(store: StoreOf<AppReducer>) {
    self.store = store
  }
}
