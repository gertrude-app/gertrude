import ComposableArchitecture
import SwiftUI

public struct EntryPoint: View {
  private let store: StoreOf<AppReducer>

  public init() {
    let db = try! appDatabase()
    prepareDependencies { $0.defaultDatabase = db }
    self.store = Store(
      initialState: AppReducer.State(),
      reducer: { AppReducer()._printChanges() }
    )
  }

  public var body: some View {
    AppView(store: self.store)
      .onAppear { self.store.send(.appDidLaunch) }
  }
}
