import ComposableArchitecture
import XCTest
import XExpect

@testable import BrowserApp

final class ApplicationFeatureTests: XCTestCase {
  @MainActor
  func testDidFinishLaunchingFlipsFlag() async {
    let store = TestStore(initialState: AppReducer.State()) {
      AppReducer()
    }

    expect(store.state.didFinishLaunching).toEqual(false)

    await store.send(.application(.didFinishLaunching)) {
      $0.didFinishLaunching = true
    }

    expect(store.state.didFinishLaunching).toEqual(true)
  }
}
