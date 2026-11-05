import Core
import Gertie
import XCTest

final class SiriUITrackerTests: XCTestCase {
  let host = RunningApp(pid: 100, bundleId: SiriBundleId.app.rawValue)
  let service = RunningApp(pid: 101, bundleId: SiriBundleId.uiService.rawValue, launchable: false)

  func testChecksHostOnceWhenUIServiceAppears() {
    var tracker = SiriUITracker()
    XCTAssertNil(tracker.newlyPresentedHost(in: [self.host]))
    XCTAssertEqual(tracker.newlyPresentedHost(in: [self.host, self.service]), self.host)
    XCTAssertNil(tracker.newlyPresentedHost(in: [self.host, self.service]))
  }

  func testIdleHostRestartDoesNotTriggerRepeatedChecks() {
    var tracker = SiriUITracker()
    XCTAssertEqual(tracker.newlyPresentedHost(in: [self.host, self.service]), self.host)
    var restartedHost = self.host
    restartedHost.pid = 200
    XCTAssertNil(tracker.newlyPresentedHost(in: [restartedHost, self.service]))
    XCTAssertNil(tracker.newlyPresentedHost(in: [restartedHost]))
    restartedHost.pid = 300
    XCTAssertNil(tracker.newlyPresentedHost(in: [restartedHost]))
  }

  func testNewUIServiceAfterClosureChecksTheReplacementHost() {
    var tracker = SiriUITracker()
    XCTAssertEqual(tracker.newlyPresentedHost(in: [self.host, self.service]), self.host)
    XCTAssertNil(tracker.newlyPresentedHost(in: []))
    var restartedHost = self.host
    restartedHost.pid = 200
    var nextService = self.service
    nextService.pid = 201
    XCTAssertEqual(tracker.newlyPresentedHost(in: [restartedHost, nextService]), restartedHost)
    XCTAssertNil(tracker.newlyPresentedHost(in: [restartedHost, nextService]))
  }

  func testServiceWaitsForHostMetadataBeforeBeingHandled() {
    var tracker = SiriUITracker()
    XCTAssertNil(tracker.newlyPresentedHost(in: [self.service]))
    XCTAssertEqual(tracker.newlyPresentedHost(in: [self.host, self.service]), self.host)
    XCTAssertNil(tracker.newlyPresentedHost(in: [self.host, self.service]))
  }

  func testOtherSiriHelpersDoNotTriggerPresentation() {
    var tracker = SiriUITracker()
    let helper = RunningApp(pid: 102, bundleId: "com.apple.SiriTTSTrainingAgent")
    XCTAssertNil(tracker.newlyPresentedHost(in: [self.host, helper]))
  }

  func testMultipleUIServiceProcessesProduceOneHostCheck() {
    var tracker = SiriUITracker()
    var secondService = self.service
    secondService.pid = 102
    let apps = [self.host, self.service, secondService]
    XCTAssertEqual(tracker.newlyPresentedHost(in: apps), self.host)
    XCTAssertNil(tracker.newlyPresentedHost(in: apps))
  }
}
