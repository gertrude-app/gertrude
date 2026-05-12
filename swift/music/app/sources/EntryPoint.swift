import LibTCA
import SwiftUI

@main
struct AppEntryPoint: App {
  private let store: AppStore

  init() {
    self.store = AppStore()
  }

  var body: some Scene {
    WindowGroup {
      EntryPoint(store: self.store)
    }
  }
}
