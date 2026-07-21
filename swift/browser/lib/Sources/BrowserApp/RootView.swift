import ComposableArchitecture
import SwiftUI

struct RootView: View {
  let store: StoreOf<AppReducer>

  var body: some View {
    WithPerceptionTracking {
      if let id = self.store.selectedTabID,
         let tabStore = self.store.scope(state: \.tabs[id: id], action: \.tabs[id: id]) {
        TabContentView(store: tabStore)
      } else {
        Color.clear
      }
    }
  }
}
