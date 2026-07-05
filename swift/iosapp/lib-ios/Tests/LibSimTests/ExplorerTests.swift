import Foundation
import LibCore
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

// Shields-enabled corpus, both grant-consumption policies (undecided — the corpus
// proves the register-math + shield projection hold under either). The shields oracle
// (S3/L4/S1′ + C1-extended) checks every controller reconcile opportunity; the entry/
// exit gap stats surface traffic-starvation exposure instead of asserting it away.
@Test @MainActor func explorerShieldsCorpusHoldsInvariantsBothGrantPolicies() async throws {
  for policy in [RecordingSuspension.GrantPolicy.burnOnFinish, .restartWithinGrant] {
    var aggregate = RecordingExplorer.Stats()
    for seed in 1 ... UInt64(corpusSeedCount) {
      let result = await RecordingExplorer.run(
        seed: seed,
        steps: corpusSteps,
        shields: true,
        grantPolicy: policy,
      )
      if let violation = result.violation {
        let shrunk = await RecordingExplorer.shrink(
          result.actions,
          expecting: violation.kind,
          shields: true,
          grantPolicy: policy,
        )
        let minimal = await RecordingExplorer.replay(shrunk, shields: true, grantPolicy: policy)
        print("=== SHIELDS EXPLORER VIOLATION (seed \(seed), \(policy)) ===")
        print(minimal.report)
        #expect(
          result.violation == nil,
          "seed \(seed) policy \(policy): \(violation) — shrunk to \(shrunk.count) actions: \(shrunk.map(\.description).joined(separator: " → "))",
        )
        return
      }
      aggregate.blockedAllowed += result.stats.blockedAllowed
      aggregate.shieldsRaisedWrites += result.stats.shieldsRaisedWrites
      aggregate.shieldsDroppedWrites += result.stats.shieldsDroppedWrites
      aggregate.flowsSuppressedByShield += result.stats.flowsSuppressedByShield
      aggregate.leaksClosedByShield += result.stats.leaksClosedByShield
      aggregate.safariLeakedUses += result.stats.safariLeakedUses
      aggregate.entryShieldGapMaxSeconds =
        max(aggregate.entryShieldGapMaxSeconds, result.stats.entryShieldGapMaxSeconds)
      aggregate.exitShieldGapMaxSeconds =
        max(aggregate.exitShieldGapMaxSeconds, result.stats.exitShieldGapMaxSeconds)
    }
    print("shields corpus (\(policy)): \(aggregate)")
    #expect(aggregate.blockedAllowed > 10) // suspensions still lift blocking
    #expect(aggregate.shieldsRaisedWrites > 10) // reconciler raises
    #expect(aggregate.shieldsDroppedWrites > 10) // and drops
    #expect(aggregate.flowsSuppressedByShield > 10) // R15 coupling exercised
  }
}

// The persistent-socket leak (OS RULE R13, docs/ios-shields-protocol.md): a connection
// verdicted during a suspension keeps carrying data after blocking resumes. This is a
// REAL property of the WITHOUT-SHIELDS design — the corpus above tolerates it (strict
// flag off); this test proves the explorer surfaces it unaided. Its dual,
// `explorerShieldsCloseTheSocketLeak`, is the flipped form: with the shield reconciler
// on, the same hunt must come up empty (S1′).
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

// The flip (agreed when R13 landed): with the shield reconciler running, the S1′
// detector — which fires whenever a leaked socket is still USABLE after the controller
// had a reconcile opportunity — must find nothing over the same seed budget that
// reliably surfaced the leak without shields. The stat assertions prove the hunt
// wasn't vacuous: sockets were opened during suspensions and later found shielded.
@Test @MainActor func explorerShieldsCloseTheSocketLeak() async throws {
  var leaksClosed = 0
  var connectionsOpened = 0
  for seed in 1 ... UInt64(50) {
    let result = await RecordingExplorer.run(seed: seed, steps: 40, shields: true)
    if let violation = result.violation {
      let shrunk = await RecordingExplorer.shrink(
        result.actions,
        expecting: violation.kind,
        shields: true,
      )
      print("=== SHIELDS LEAK VIOLATION (seed \(seed)) ===")
      print(shrunk.map(\.description).joined(separator: " → "))
      #expect(result.violation == nil, "seed \(seed): \(violation)")
      return
    }
    leaksClosed += result.stats.leaksClosedByShield
    connectionsOpened += result.stats.connectionsOpened
  }
  #expect(connectionsOpened > 10) // the leak path was exercised
  #expect(leaksClosed > 0) // and leaked sockets were found unusable behind the shield
}

@Test @MainActor func explorerIsDeterministic() async throws {
  let first = await RecordingExplorer.run(seed: 42, steps: 30)
  let second = await RecordingExplorer.run(seed: 42, steps: 30)
  #expect(first.actions == second.actions)
  #expect(first.stats == second.stats)
  #expect(first.violation == second.violation)
}

@Test @MainActor func explorerShieldsRunIsDeterministic() async throws {
  let first = await RecordingExplorer
    .run(seed: 42, steps: 30, shields: true, grantPolicy: .restartWithinGrant)
  let second = await RecordingExplorer
    .run(seed: 42, steps: 30, shields: true, grantPolicy: .restartWithinGrant)
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
