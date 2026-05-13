import ComposableArchitecture
import SwiftUI

public struct EntryPoint: View {
  private let store: AppStore

  public init(store: AppStore) {
    self.store = store
  }

  public var body: some View {
    MusicPocViewContainer(store: self.store.inner)
  }
}

@MainActor
public struct AppStore {
  let inner: StoreOf<MusicPocFeature>

  public init() {
    self.inner = Store(
      initialState: .init(),
      reducer: { MusicPocFeature() },
    )
  }
}
