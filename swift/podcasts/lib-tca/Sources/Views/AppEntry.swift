import ComposableArchitecture
import SwiftUI

public struct EntryPoint: View {
  private let store: AppStore

  public init(store: AppStore) {
    self.store = store
  }

  public var body: some View {
    AppView(store: self.store.inner)
      .tint(.violet500)
      .onAppear {
        self.store.send(.appDidLaunch)
      }
  }
}

@MainActor
public struct AppStore {
  let inner: StoreOf<AppReducer>

  public init() {
    let db = try! appDatabase()
    prepareDependencies {
      $0.defaultDatabase = db
      #if targetEnvironment(simulator)
        $0.keychain._load = { key in
          switch key {
          case .pincode:
            "111111".data(using: .utf8)!
          case .installDate:
            "1760103425".data(using: .utf8)!
          case .installId:
            "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF".data(using: .utf8)!
          }
        }
      #endif
    }
    self.inner = Store(
      initialState: .init(),
      reducer: { AppReducer()._printChanges(.custom) }
    )
  }

  public func setupBackgroundTasks() {
    initBgTasks()
  }

  func send(_ action: AppReducer.Action) {
    self.inner.send(action)
  }
}
