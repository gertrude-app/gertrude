import ComposableArchitecture
import LibViews
import SwiftUI

struct MusicPocViewContainer: View {
  let store: StoreOf<MusicPocFeature>

  var body: some View {
    MusicPocView(
      state: self.store.viewState,
      onAuthorizeTap: { self.store.send(.authorizeButtonTapped) },
      onPlayPauseTap: { self.store.send(.playPauseButtonTapped) },
      onArtworkBlockingChanged: { self.store.send(.artworkBlockingChanged($0)) },
    )
  }
}

private extension MusicPocFeature.State {
  var viewState: MusicPocViewState {
    switch self.status {
    case .needsAuthorization:
      .needsAuthorization
    case .authorizing:
      .authorizing
    case .readyToPlay:
      .readyToPlay(
        MusicPocTrackViewState(
          id: self.track.id,
          title: self.track.title,
          artist: self.track.artist,
          artworkURL: self.track.artworkURL,
          blocksArtwork: self.blocksArtwork,
          isPlaying: self.isPlaying,
          isStarting: self.isStarting,
        ),
      )
    case .denied:
      .denied
    case .failed(let message):
      .failed(message)
    }
  }
}
