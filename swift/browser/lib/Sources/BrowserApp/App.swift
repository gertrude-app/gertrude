import ComposableArchitecture
import Foundation
import SwiftUI

@MainActor public struct App {
  let store = Store(
    initialState: AppReducer.State(),
    reducer: { AppReducer() },
  )

  public init() {}

  public func send(_ action: ApplicationAction) {
    switch action {
    case .didFinishLaunching:
      self.store.send(.application(.didFinishLaunching))
    }
  }

  public var rootView: some View {
    RootView(store: self.store)
  }
}
