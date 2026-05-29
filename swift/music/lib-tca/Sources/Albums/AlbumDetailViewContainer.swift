import ComposableArchitecture
import LibViews
import SwiftUI

struct AlbumDetailViewContainer: View {
  let store: StoreOf<AlbumDetailFeature>

  var body: some View {
    AlbumDetailView(
      album: AlbumData(album: self.store.album),
      tracks: self.store.tracks.map(TrackData.init),
      transitionSourceID: self.store.transitionSourceID,
      isPlaying: self.store.isPlaying,
      currentTrackID: self.store.currentTrackID?.rawValue,
      onPlayTap: { self.store.send(.playTapped) },
      onTrackTap: { self.store.send(.trackTapped(.init($0))) },
    )
  }
}
