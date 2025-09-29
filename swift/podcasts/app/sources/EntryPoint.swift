import ComposableArchitecture
import LibTCA
import SwiftUI

@main
struct AppEntryPoint: App {
  private let store: AppStore

  public init() {
    self.store = AppStore()
    self.store.setupBackgroundTasks()
  }

  public var body: some Scene {
    WindowGroup {
      EntryPoint(store: self.store)
    }
  }
}
