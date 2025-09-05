import ComposableArchitecture
import LibTCA
import SwiftUI

@main
struct IOSAppEntry: App {
  let store: StoreOf<AppReducer>

  init() {
    self.store = Store(
      initialState: AppReducer.State(),
      reducer: { AppReducer()._printChanges() }
    )
  }

  var body: some Scene {
    WindowGroup {
      AppView(store: self.store)
        .onAppear {
          self.store.send(.appDidLaunch)
        }
    }
  }
}
