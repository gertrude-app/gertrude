import Foundation
import XCTest
import XExpect

@testable import App

/// Corpus + determinism tests for the MacExplorer. Env knobs for deeper local
/// hunts: `EXPLORE_SEEDS=100 EXPLORE_STEPS=60 just macapp-test --filter
/// MacExplorerTests` (from `swift/`). A failing seed's report (printed on
/// failure) contains the full action script; shrink it with
/// `MacExplorer.shrink(_:expecting:)` and freeze the result as a named
/// regression scenario.
final class MacExplorerTests: XCTestCase {
  var seeds: UInt64 {
    ProcessInfo.processInfo.environment["EXPLORE_SEEDS"].flatMap { UInt64($0) } ?? 12
  }

  var steps: Int {
    ProcessInfo.processInfo.environment["EXPLORE_STEPS"].flatMap { Int($0) } ?? 30
  }

  @MainActor
  func testExplorerCorpusFindsNoViolations() async throws {
    var reports: [String] = []
    var stats = MacExplorer.Stats()
    for seed in 0 ..< self.seeds {
      let result = await MacExplorer.run(seed: seed, steps: self.steps)
      if let violation = result.violation {
        reports.append("seed \(seed): \(violation)\n\(result.report)")
      }
      stats = accumulate(stats, result.stats)
    }
    if !reports.isEmpty {
      XCTFail(
        "explorer found \(reports.count) violation(s):\n\n\(reports.joined(separator: "\n\n"))",
      )
    }
    // non-vacuity: the corpus must actually exercise the interesting regions
    expect(stats.suspensionAllows > 0).toBeTrue()
    expect(stats.awolDrops > 0).toBeTrue()
    expect(stats.failOpenAllows > 0).toBeTrue()
    expect(stats.expectedAllows > 0).toBeTrue()
    expect(stats.blockedDropped > 0).toBeTrue()
  }

  @MainActor
  func testExplorerIsDeterministic() async throws {
    let first = await MacExplorer.run(seed: 7, steps: 25)
    let second = await MacExplorer.run(seed: 7, steps: 25)
    expect(second.actions).toEqual(first.actions)
    expect(second.violation).toEqual(first.violation)
    expect(second.stats).toEqual(first.stats)
  }
}

private func accumulate(
  _ total: MacExplorer.Stats,
  _ run: MacExplorer.Stats,
) -> MacExplorer.Stats {
  var stats = total
  stats.blockedDropped += run.blockedDropped
  stats.expectedAllows += run.expectedAllows
  stats.failOpenAllows += run.failOpenAllows
  stats.awolDrops += run.awolDrops
  stats.downtimeDrops += run.downtimeDrops
  stats.suspensionAllows += run.suspensionAllows
  stats.indeterminateSkips += run.indeterminateSkips
  stats.connectionsOpened += run.connectionsOpened
  stats.leakedConnectionUses += run.leakedConnectionUses
  stats.xpcSendFailures += run.xpcSendFailures
  stats.xpcReconnects += run.xpcReconnects
  stats.suspensionGrantsDelivered += run.suspensionGrantsDelivered
  stats.suspensionGrantsLost += run.suspensionGrantsLost
  stats.rulesDeliveries += run.rulesDeliveries
  stats.messagesDelivered += run.messagesDelivered
  return stats
}
