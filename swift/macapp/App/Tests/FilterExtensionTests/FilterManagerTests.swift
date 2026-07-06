import Core
import Dependencies
import NetworkExtension
import TestSupport
import XCTest
import XExpect

@testable import LiveFilterExtensionClient

final class FilterManagerTests: XCTestCase {
  func testFailedReinstallRestoresFilterConfig() async {
    let configUpdated = spySync(on: NEFilterProviderConfiguration.self, returning: ())
    let enabled = mockSync(returning: [(), ()])
    let saved = mock(always: Error?.none)

    let result = await withDependencies {
      $0.mainQueue = .immediate
      $0.system.loadFilterConfiguration = { .doesNotExistOrLoadedSuccessfully }
      $0.system.filterProviderConfiguration = { nil } // <-- no config -> install fails
      $0.system.isNEFilterManagerSharedEnabled = { false }
      $0.system.disableNEFilterManagerShared = {}
      $0.system.removeFilterConfiguration = { nil }
      $0.system.requestExtensionActivation = { _ in } // <-- never resolves -> timeout
      $0.system.updateNEFilterManagerShared = configUpdated.fn
      $0.system.enableNEFilterManagerShared = enabled.fn
      $0.system.saveNEFilterManagerShared = saved.fn
    } operation: {
      await FilterManager().reinstallFilter()
    }

    switch result {
    case .timedOutWaiting: break
    default: XCTFail("expected .timedOutWaiting, got \(result)")
    }

    // the removed config was put back, so a failed reinstall can't leave machine unfiltered
    expect(configUpdated.calls.count).toEqual(1)
    expect(configUpdated.calls.first?.filterDataProviderBundleIdentifier)
      .toEqual(FILTER_EXT_BUNDLE_ID)
    expect(enabled.called).toEqual(true)
  }
}
