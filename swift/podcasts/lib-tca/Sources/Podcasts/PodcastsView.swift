import ComposableArchitecture
import LibViews
import SharingGRDB
import SwiftUI

struct PodcastsView: View {
  @Bindable var store: StoreOf<PodcastsFeature>

  var body: some View {
    PodcastsHomeView(
      shows: self.store.shows.map { .init(from: $0) },
      onAddShowTap: { self.store.send(.addShowTapped) },
      onShowTap: { self.store.send(.showTapped(.init($0))) }
    )
    .navigationBarBackButtonHidden(true)
    .navigationDestination(
      item: self.$store.scope(
        state: \.destination?.addShow,
        action: \.destination.addShow
      ),
      destination: { store in
        AddShowView(store: store)
      }
    )
    .navigationDestination(
      item: self.$store.scope(
        state: \.destination?.show,
        action: \.destination.show
      ),
      destination: { store in
        ShowViewContainer(store: store)
      }
    )
    .onAppear {
      self.store.send(.onAppear)
    }
  }
}

extension PodcastsHomeView.ShowDataWithStats {
  init(from showInfo: PodcastsFeature.ShowInfo) {
    self.init(
      data: .init(
        id: showInfo.id.rawValue,
        name: showInfo.name,
        author: showInfo.author,
        description: showInfo.description,
        showArtwork: showInfo.showArtwork,
        artworkImage: showLocalArtworkImage(showId: showInfo.id),
        artworkUrl: showInfo.artworkUrl
      ),
      totalEpisodes: showInfo.totalEpisodes,
      unplayedEpisodes: showInfo.unplayedEpisodes,
      mostRecentPubDate: showInfo.mostRecentPubDate,
    )
  }
}
