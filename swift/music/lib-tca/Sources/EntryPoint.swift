import ComposableArchitecture
import GertieUI
import LibViews
import SwiftUI

#if canImport(UIKit)
  import UIKit
#endif

public struct EntryPoint: View {
  private let store: AppStore

  public init(store: AppStore) {
    self.store = store
    #if canImport(UIKit)
      UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(
        Color.gertrudeBrandAccent,
      )
    #endif
  }

  public var body: some View {
    AppView(store: self.store.inner)
      .tint(.gertrudeBrandAccent)
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
