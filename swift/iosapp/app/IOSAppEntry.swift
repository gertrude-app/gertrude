import ComposableArchitecture
import Dependencies
import LibApp
import LibClients
import LibViews
import SwiftUI

@main
struct IOSAppEntry: App {
  let store: StoreOf<IOSReducer>
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @Environment(\.scenePhase) private var scenePhase
  @Dependency(\.recorderEvents) private var recorderEvents

  var osMajorVersion: Int {
    ProcessInfo.processInfo.operatingSystemVersion.majorVersion
  }

  var deviceType: String {
    UIDevice.current.model
  }

  init() {
    self.store = Store(
      initialState: IOSReducer.State(),
      reducer: { IOSReducer()._printChanges() },
    )
    self.appDelegate.onTerminate = { [weak store = self.store] in
      store?.send(.programmatic(.appWillTerminate))
    }
  }

  var body: some Scene {
    WindowGroup {
      AppView(store: self.store, osMajorVersion: self.osMajorVersion, deviceType: self.deviceType)
        .onAppear {
          self.store.send(.programmatic(.appDidLaunch))
        }
        .task { [store = self.store, events = self.recorderEvents] in
          for await event in events.events() {
            store.send(.programmatic(.receivedRecorderEvent(event)))
          }
        }
        .onChange(of: self.scenePhase) { _, newPhase in
          switch newPhase {
          case .active:
            self.store.send(.programmatic(.appDidEnterForeground))
          case .background:
            self.store.send(.programmatic(.appDidEnterBackground))
          case .inactive:
            break
          @unknown default:
            break
          }
        }
    }
  }
}

private class AppDelegate: NSObject, UIApplicationDelegate {
  var onTerminate: (() -> Void)?
  func applicationWillTerminate(_ application: UIApplication) {
    self.onTerminate?()
  }
}
