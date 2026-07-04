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
    aggregate.connectionsOpened += result.stats.connectionsOpened
    aggregate.leakedConnectionUses += result.stats.leakedConnectionUses
  }
  #expect(aggregate.blockedAllowed > 20) // corpus actually lifts blocking
  #expect(aggregate.blockedDropped > 100) // and blocks
  #expect(aggregate.sentinelEntries > 10) // enters via sentinel edge
  #expect(aggregate.rederivedEntries > 5) // and via D2 level-trigger
  #expect(aggregate.screenshotsCreated > 50) // evidence flows
  #expect(aggregate.uploadedDistinct > 50) // and uploads
  #expect(aggregate.connectionsOpened > 10) // persistent connections exercised
}

// The persistent-socket leak (OS RULE R13, docs/ios-shields-protocol.md): a connection
// verdicted during a suspension keeps carrying data after blocking resumes. This is a
// REAL property of the shipped design — the corpus above tolerates it (strict flag
// off); this test proves the explorer surfaces it unaided. It flips to expecting NO
// violation once the shields extension lands and closes S1′.
@Test @MainActor func explorerFindsPersistentSocketLeak() async throws {
  for seed in 1 ... UInt64(50) {
    let result = await RecordingExplorer.run(seed: seed, steps: 40, strictSocketLeak: true)
    guard let violation = result.violation else { continue }
    guard violation.kind == "S1P-socket-leak" else {
      Issue.record("unexpected violation hunting the leak: \(violation)")
      return
    }
    let shrunk = await RecordingExplorer.shrink(
      result.actions,
      expecting: violation.kind,
      strictSocketLeak: true,
    )
    print("=== SOCKET LEAK (seed \(seed)) ===")
    print(shrunk.map(\.description).joined(separator: " → "))
    #expect(shrunk.count <= 8) // shrinks to a human-readable recipe
    return
  }
  Issue.record("explorer never found the socket leak in 50 seeds — detector too weak")
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
