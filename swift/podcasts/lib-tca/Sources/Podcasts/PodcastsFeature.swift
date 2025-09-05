import ComposableArchitecture
import SwiftUI

@Reducer
struct PodcastsFeature {
  @ObservableState
  struct State: Equatable {
    var counter: Int = 0
  }
}
