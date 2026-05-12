import ComposableArchitecture
import LibViews
import SwiftUI

struct MusicPocViewContainer: View {
  let store: StoreOf<MusicPocFeature>

  var body: some View {
    MusicPocView(
      state: self.store.status.viewState,
      onAuthorizeTap: { self.store.send(.authorizeButtonTapped) },
      onPlayTap: { self.store.send(.playButtonTapped) },
    )
  }
}

private extension MusicPocStatus {
  var viewState: MusicPocViewState {
    switch self {
    case .needsAuthorization:
      .needsAuthorization
    case .authorizing:
      .authorizing
    case .readyToPlay:
      .readyToPlay
    case .playing:
      .playing
    case .denied:
      .denied
    case .failed(let message):
      .failed(message)
    }
  }
}
