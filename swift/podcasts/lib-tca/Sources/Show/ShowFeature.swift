import ComposableArchitecture
import SharingGRDB
import SwiftUI

@Reducer
struct ShowFeature {
  @ObservableState
  struct State: Equatable {
    var show: Show
  }
}
