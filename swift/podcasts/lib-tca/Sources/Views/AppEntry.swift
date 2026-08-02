import ComposableArchitecture
import GertieUI
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
    }
    self.inner = Store(
      initialState: .init(),
      reducer: { AppReducer()._printChanges(.custom) },
    )
  }

  public func setupBackgroundTasks() {
    initBgTasks()
  }

  func send(_ action: AppReducer.Action) {
    self.inner.send(action)
  }
}
