import ComposableArchitecture
import LibViews
import SwiftUI

struct ShowViewContainer: View {
  @Bindable var store: StoreOf<ShowFeature>

  var body: some View {
    ShowView(
      show: .init(from: self.store.show),
      episodes: self.store.episodes.map { .init(from: $0) }
    ) {
      self.store.send(.episodeTapped($0))
    }
  }
}
