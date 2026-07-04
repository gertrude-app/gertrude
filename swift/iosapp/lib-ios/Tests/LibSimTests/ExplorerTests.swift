import Foundation
import LibSim
import Testing

private var corpusSeedCount: Int {
  ProcessInfo.processInfo.environment["EXPLORE_SEEDS"].flatMap(Int.init) ?? 25
}

private var corpusSteps: Int {
  ProcessInfo.processInfo.environment["EXPLORE_STEPS"].flatMap(Int.init) ?? 40
}

@Test @MainActor func explorerCorpusHoldsInvariants() async throws {
  var aggregate = RecordingExplorer.Stats()
  for seed in 1 ... UInt64(corpusSeedCount) {
    let result = await RecordingExplorer.run(seed: seed, steps: corpusSteps)
    if let violation = result.violation {
      let shrunk = await RecordingExplorer.shrink(result.actions, expecting: violation.kind)
      let minimal = await RecordingExplorer.replay(shrunk)
      print("=== EXPLORER VIOLATION (seed \(seed)) ===")
      print(minimal.report)
      #expect(
        result.violation == nil,
        "seed \(seed): \(violation) — shrunk to \(shrunk.count) actions: \(shrunk.map(\.description).joined(separator: " → "))",
      )
      return
    }
    aggregate.blockedAllowed += result.stats.blockedAllowed
    aggregate.blockedDropped += result.stats.blockedDropped
    aggregate.sentinelEntries += result.stats.sentinelEntries
    aggregate.rederivedEntries += result.stats.rederivedEntries
    aggregate.broadcasts += result.stats.broadcasts
    aggregate.screenshotsCreated += result.stats.screenshotsCreated
    aggregate.uploadedDistinct += result.stats.uploadedDistinct
  }
  #expect(aggregate.blockedAllowed > 20) // corpus actually lifts blocking
  #expect(aggregate.blockedDropped > 100) // and blocks
  #expect(aggregate.sentinelEntries > 10) // enters via sentinel edge
  #expect(aggregate.rederivedEntries > 5) // and via D2 level-trigger
  #expect(aggregate.screenshotsCreated > 50) // evidence flows
  #expect(aggregate.uploadedDistinct > 50) // and uploads
}

@Test @MainActor func explorerIsDeterministic() async throws {
  let first = await RecordingExplorer.run(seed: 42, steps: 30)
  let second = await RecordingExplorer.run(seed: 42, steps: 30)
  #expect(first.actions == second.actions)
  #expect(first.stats == second.stats)
  #expect(first.violation == second.violation)
}

@Test @MainActor func explorerReplayMatchesRun() async throws {
  let run = await RecordingExplorer.run(seed: 7, steps: 30)
  let replay = await RecordingExplorer.replay(run.actions)
  #expect(replay.violation == run.violation)
  #expect(replay.actions == run.actions) // every generated action was precondition-valid
}
