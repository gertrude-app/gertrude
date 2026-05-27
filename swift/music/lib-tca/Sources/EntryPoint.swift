import ComposableArchitecture
import SwiftUI

public struct EntryPoint: View {
  private let store: AppStore

  public init(store: AppStore) {
    self.store = store
  }

  public var body: some View {
    AppView(store: self.store.inner)
  }
}

@MainActor
public struct AppStore {
  let inner: StoreOf<AppFeature>

  public init() {
    self.inner = Store(
      initialState: .init(),
      reducer: { AppFeature() },
    )
  }
}
