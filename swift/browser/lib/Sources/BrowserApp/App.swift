import ComposableArchitecture
import Foundation

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

  public var currentTabURL: URL? {
    guard let id = self.store.state.selectedTabID else { return nil }
    return self.store.state.tabs[id: id]?.url
  }
}
