import ComposableArchitecture
import XCTest
import XExpect

@testable import BrowserApp

final class ApplicationFeatureTests: XCTestCase {
  @MainActor
  func testDidFinishLaunchingCreatesInitialTab() async {
    let store = TestStore(initialState: AppReducer.State()) {
      AppReducer()
    } withDependencies: {
      $0.uuid = .incrementing
    }

    expect(store.state.tabs).toEqual([])
    expect(store.state.selectedTabID).toBeNil()

    await store.send(.application(.didFinishLaunching)) {
      $0.tabs = [
        Tab.State(id: UUID(0), url: URL(string: "https://gertrude.app")!),
      ]
      $0.selectedTabID = UUID(0)
    }
  }
}
