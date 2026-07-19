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
        isPlaying: self.store.isPlaying,
        isLoading: self.store.isLoading || self.store.isLoadingTracks,
        isLoadingTracks: self.store.isLoadingTracks,
        currentTrackID: self.store.currentTrackID?.rawValue,
        onAddToPlaylist: { self.store.send(.addToPlaylistTapped) },
        onAddToQueue: { self.store.send(.addToQueueTapped) },
        onPlayNext: { self.store.send(.playNextTapped) },
        onPlayTap: { self.store.send(.playTapped) },
        onTrackAddToPlaylist: { self.store.send(.trackAddToPlaylistTapped(.init($0))) },
        onTrackAddToQueue: { self.store.send(.trackAddToQueueTapped(.init($0))) },
        onTrackPlayNext: { self.store.send(.trackPlayNextTapped(.init($0))) },
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
    .task(id: self.store.album.id) {
      _ = self.store.send(.onAppear)
    }
  }
}
