import ComposableArchitecture
import LibTCA
import SwiftUI

@main
struct AppEntryPoint: App {
  private let store: AppStore

  init() {
    self.store = AppStore()
    self.store.setupBackgroundTasks()
  }

  var body: some Scene {
    WindowGroup {
      EntryPoint(store: self.store)
    }
  }
}
