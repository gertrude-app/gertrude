import Foundation
import Testing

@testable import LibViews

struct TabLayoutSettleTrackerTests {
  @Test
  func settlesOnceTheLayoutHoldsStillForTheQuietPeriod() {
    let results = Self.results([
      ("low", true, 10),
      ("fixed", true, 10.05),
      ("fixed", true, 10.15),
      ("fixed", true, 10.25),
    ])
    #expect(results == [false, false, false, true])
  }

  @Test
  func waitsForContentBeforeSettling() {
    let results = Self.results([
      ("empty", false, 0),
      ("empty", false, 0.5),
      ("bars", true, 0.6),
      ("bars", true, 0.8),
    ])
    #expect(results == [false, false, false, true])
  }

  @Test
  func givesUpWaitingAfterTheLimit() {
    let results = Self.results([
      ("a", false, 0),
      ("b", true, 0.9),
      ("c", true, 1),
    ])
    #expect(results == [false, false, true])
  }

  private static func results(_ readings: [(String, Bool, TimeInterval)]) -> [Bool] {
    var tracker = TabLayoutSettleTracker()
    return readings.map { signature, hasContent, time in
      tracker.isSettled(signature: signature, hasContent: hasContent, at: time)
    }
  }
}
