import ComposableArchitecture
import LibViews
import SharingGRDB
import SwiftUI

@Reducer
struct NowPlayingFeature {
  @ObservableState
  struct State: Equatable {
    var episode: Episode
    var show: Show
    var isPlaying: Bool
    var minimized: Bool
  }

  enum Action: Equatable {
    case view(NowPlayingView.Event)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .view(.miniPlayerTapped), .view(.dismissed):
        state.minimized.toggle()
        return .none
      default:
        return .none
      }
    }
  }
}
