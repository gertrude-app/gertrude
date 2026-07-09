import ComposableArchitecture
import LibViews
import SwiftUI

struct AlbumDetailViewContainer: View {
  let store: StoreOf<AlbumDetailFeature>

  var body: some View {
    ZStack(alignment: .top) {
      AlbumDetailView(
        album: AlbumData(album: self.store.album),
        tracks: self.store.album.tracks.map {
          TrackData(track: $0)
        },
        transitionSourceID: self.store.transitionSourceID,
        isPlaying: self.store.isPlaying,
        isLoading: self.store.isLoading || self.store.isLoadingTracks,
        isLoadingTracks: self.store.isLoadingTracks,
        currentTrackID: self.store.currentTrackID?.rawValue,
        onPlayTap: { self.store.send(.playTapped) },
        onTrackTap: { self.store.send(.trackTapped(.init($0))) },
      )

      if let failure = self.store.playbackFailure {
        PlaybackErrorBanner(
          title: failure.title,
          message: failure.message,
          systemImage: failure.systemImage,
          actionTitle: failure.actionTitle,
          onActionTap: { self.store.send(.playbackFailureActionTapped) },
          onDismissTap: { self.store.send(.playbackFailureDismissed) },
        )
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .transition(.move(edge: .top).combined(with: .opacity))
      }
    }
    .animation(.snappy(duration: 0.22), value: self.store.playbackFailure)
    .onAppear {
      self.store.send(.onAppear)
    }
  }
}
