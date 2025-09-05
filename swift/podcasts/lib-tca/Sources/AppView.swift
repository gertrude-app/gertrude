import ComposableArchitecture
import LibViews
import SwiftUI

public struct AppView: View {
  @Bindable var store: StoreOf<AppReducer>

  public var body: some View {
    Group {
      switch self.store.screen {
      case .launching:
        WelcomeView {
          print("primary btn tapped")
        }
      case .onboarding:
        WelcomeView {
          print("primary btn tapped")
        }
      }
    }
  }

  public init(store: StoreOf<AppReducer>) {
    self.store = store
  }
}
