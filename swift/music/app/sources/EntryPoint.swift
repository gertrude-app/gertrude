import LibTCA
import SwiftUI

@main
struct AppEntryPoint: App {
  @UIApplicationDelegateAdaptor(MusicAppDelegate.self) private var appDelegate
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
