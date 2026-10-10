import CustomDump
import Foundation
import IOSAppsRoute
import Security
import Testing

@testable import DeviceIdentity

@MainActor
struct IdentityResolverTests {
  @Test func firstLaunchPromotesLegacyIdInsteadOfLiveVendorId() async {
    let h = IdentityHarness(c: oldId)
    let resolver = h.resolver()
    let outcome = await resolver.resolveAndReport()
    expectNoDifference(outcome, .steady(oldId))
    expectNoDifference(h.storage.readId(.identity), .value(oldId))
    expectNoDifference(h.storage.readId(.canary), .value(oldId))
    expectNoDifference(h.requests, [])
    expectNoDifference(h.events, [])
  }

  @Test(arguments: [true, false]) func freshInstallUsesVendorOrGeneratedId(hasVendor: Bool) async {
    let h = IdentityHarness()
    h.liveVendorId = hasVendor ? oldId : nil
    let outcome = await h.resolver().resolveAndReport()
    expectNoDifference(outcome, .steady(hasVendor ? oldId : newId))
  }

  @Test func siblingAdoptsSharedIdentityWithoutReporting() async {
    let h = IdentityHarness(a: oldId, b: oldId)
    let outcome = await h.resolver().resolveAndReport()
    expectNoDifference(outcome, .steady(oldId))
    expectNoDifference(h.storage.readId(.appMemory), .value(oldId))
    expectNoDifference(h.requests, [])
  }

  @Test(arguments: [IdentitySlot.canary, .identity, .appMemory])
  func failedInitialWritesKeepIdentityUnavailable(slot: IdentitySlot) async {
    let h = IdentityHarness()
    h.writeFailures = [slot]
    let resolver = h.resolver()
    let outcome = await resolver.resolveAndReport()
    expectNoDifference(outcome, .deferred)
    expectNoDifference(resolver.deviceId, nil)
    expectNoDifference(h.publishedIdentities, [])
    expectNoDifference(h.requests, [])
  }

  @Test func sameDeviceRestoreIgnoresChangedLiveVendorId() async {
    let h = IdentityHarness(a: oldId, b: oldId, c: oldId)
    let outcome = await h.resolver().resolveAndReport()
    expectNoDifference(outcome, .steady(oldId))
    expectNoDifference(h.actions, [])
    expectNoDifference(h.events, [])
  }

  @Test func healthyActivationsNeverClearTheMirror() {
    let h = IdentityHarness(a: oldId, b: oldId, c: oldId)
    let resolver = h.resolver()
    for _ in 0 ..< 3 {
      expectNoDifference(resolver.resolveOnForeground(), .steady(oldId))
    }
    expectNoDifference(h.publishedIdentities, [oldId, oldId, oldId])
    expectNoDifference(h.mirror, oldId)
  }

  @Test func sameDeviceKeepsOriginalIdentityBeforeAnyNetworkWork() throws {
    let h = IdentityHarness(a: newId, b: newId, c: oldId)
    let resolver = h.resolver()
    expectNoDifference(resolver.resolveOnForeground(), .adopted(oldId))
    expectNoDifference(resolver.deviceId, oldId)
    expectNoDifference(h.mirror, oldId)
    expectNoDifference(h.requests, [])
    let pending = try JSONDecoder().decode(
      PendingIdentityTransition.self, from: #require(h.data[.pendingTransition]),
    )
    expectNoDifference(pending.kind, .sameDevice)
    expectNoDifference(pending.proofToken, proofId)
    let restarted = h.resolver()
    expectNoDifference(restarted.resolveOnForeground(), .adopted(oldId))
    expectNoDifference(restarted.deviceId, oldId)
    expectNoDifference(h.requests, [])
  }

  @Test func repeatedReportFailuresDoNotBlockOfflineSameDeviceUse() async {
    let h = IdentityHarness(a: newId, b: newId, c: oldId)
    h.reportFails = true
    for _ in 0 ..< 3 {
      let resolver = h.resolver()
      expectNoDifference(resolver.resolveOnForeground(), .adopted(oldId))
      let outcome = await resolver.reportPendingTransition()
      expectNoDifference(outcome, .retry)
      expectNoDifference(resolver.deviceId, oldId)
      expectNoDifference(h.mirror, oldId)
      #expect(h.data[.pendingTransition] != nil)
    }
    expectNoDifference(h.requests.count, 3)
    expectNoDifference(h.requests.first, h.requests.last)
    #expect(!h.publishedIdentities.contains(nil))
  }

  @Test func pendingMigrationRemainsUnavailableOffline() async {
    let h = IdentityHarness(a: oldId, c: oldId)
    h.reportFails = true
    let resolver = h.resolver()
    expectNoDifference(resolver.resolveOnForeground(), .retry)
    expectNoDifference(resolver.deviceId, nil)
    expectNoDifference(h.mirror, nil)
    expectNoDifference(h.requests, [])
    let outcome = await resolver.reportPendingTransition()
    expectNoDifference(outcome, .retry)
    expectNoDifference(resolver.deviceId, nil)
    expectNoDifference(h.mirror, nil)
  }

  @Test(arguments: ["appMemory", "credentials", "credentialsAfterSave", "delete"])
  func interruptedSameDeviceAcknowledgementUsesPersistedCredentialIdentity(
    step: String,
  ) async throws {
    let h = IdentityHarness(a: newId, b: newId, c: oldId)
    h.response = .init(deviceId: newId, reason: .normal, childId: childId, token: newId)
    h.writeFailures = step == "appMemory" ? [.appMemory] : []
    h.credentialsFail = step == "credentials"
    h.credentialsFailAfterSave = step == "credentialsAfterSave"
    h.deleteFails = step == "delete"
    let resolver = h.resolver()
    expectNoDifference(resolver.resolveOnForeground(), .adopted(oldId))
    let reported = await resolver.reportPendingTransition()
    expectNoDifference(reported, .retry)
    let expected = step == "delete" || step == "credentialsAfterSave" ? newId : oldId
    expectNoDifference(h.credentialDeviceId, expected)
    expectNoDifference(resolver.deviceId, expected)
    expectNoDifference(h.mirror, expected)
    #expect(h.data[.pendingTransition] != nil)

    h.reportFails = true
    let restarted = h.resolver()
    expectNoDifference(restarted.resolveOnForeground(), .adopted(expected))
    let retried = await restarted.reportPendingTransition()
    expectNoDifference(retried, .retry)
    expectNoDifference(restarted.deviceId, expected)
    expectNoDifference(h.mirror, expected)
    expectNoDifference(h.requests.last?.proofToken, proofId)
  }

  @Test func unconnectedSameDeviceRetryKeepsOriginalIdentityAfterPartialAcknowledgement() async {
    let h = IdentityHarness(a: newId, b: newId, c: oldId)
    h.credentialDeviceId = nil
    h.connection = nil
    h.proof = nil
    h.response = .init(deviceId: newId, reason: .normal)
    h.deleteFails = true
    let reported = await h.resolver().resolveAndReport()
    expectNoDifference(reported, .retry)
    expectNoDifference(h.storage.readId(.appMemory), .value(newId))
    h.reportFails = true
    let restarted = h.resolver()
    expectNoDifference(restarted.resolveOnForeground(), .adopted(oldId))
    expectNoDifference(h.mirror, oldId)
  }

  @Test(arguments: [IdentitySlot.identity, .appMemory])
  func offlineRetryRespectsPartiallyWrittenCanonicalAcknowledgement(slot: IdentitySlot) async {
    let h = IdentityHarness(a: newId, b: newId, c: oldId)
    h.response = .init(deviceId: oldId, reason: .supervisionCanonical)
    h.writeFailures = [slot]
    let resolver = h.resolver()
    _ = resolver.resolveOnForeground()
    let outcome = await resolver.reportPendingTransition()
    expectNoDifference(outcome, .retry)
    let expected: UUID? = oldId
    expectNoDifference(resolver.deviceId, expected)
    h.reportFails = true
    let restarted = h.resolver()
    let local = restarted.resolveOnForeground()
    expectNoDifference(local, expected.map(IdentityResolver.Outcome.adopted) ?? .retry)
    expectNoDifference(restarted.deviceId, expected)
    let retried = await restarted.reportPendingTransition()
    expectNoDifference(retried, .retry)
    expectNoDifference(restarted.deviceId, expected)
  }

  @Test func siblingMigrationStaysUnavailableAfterFailedAcknowledgementAndRestart() async {
    let h = IdentityHarness(a: newId, b: newId, c: oldId)
    h.response = .init(deviceId: newId, reason: .resolvedAsMigration)
    h.credentialsFail = true
    let resolver = h.resolver()
    expectNoDifference(resolver.resolveOnForeground(), .adopted(oldId))
    let outcome = await resolver.reportPendingTransition()
    expectNoDifference(outcome, .retry)
    expectNoDifference(resolver.deviceId, nil)
    expectNoDifference(h.mirror, nil)
    #expect(h.migrationRequired)
    h.reportFails = true
    let restarted = h.resolver()
    expectNoDifference(restarted.resolveOnForeground(), .retry)
    let retried = await restarted.reportPendingTransition()
    expectNoDifference(retried, .retry)
    expectNoDifference(restarted.deviceId, nil)
    expectNoDifference(h.mirror, nil)
  }

  @Test func racingFirstLaunchReportsLegacyIdentityToWinner() async {
    let h = IdentityHarness(c: oldId)
    h.addWinner = newId
    let outcome = await h.resolver().resolveAndReport()
    expectNoDifference(outcome, .adopted(newId))
    expectNoDifference(h.storage.readId(.canary), .value(newId))
    expectNoDifference(h.requests.first?.kind, .sameDevice)
    expectNoDifference(h.events, [
      .resolution(.adopted(oldId), matchesLiveVendorId: false),
      .resolution(.adopted(newId), matchesLiveVendorId: true),
    ])
    #expect(!h.actions.contains("clear"))
  }

  @Test func failedRaceRepairDefersWithoutReportingOrExposingIdentity() async {
    let h = IdentityHarness(c: oldId)
    h.addWinner = newId
    h.repairFails = true
    let resolver = h.resolver()
    let outcome = await resolver.resolveAndReport()
    expectNoDifference(outcome, .deferred)
    expectNoDifference(resolver.deviceId, nil)
    expectNoDifference(h.requests, [])
  }

  @Test(arguments: IdentitySlot.allCases)
  func unknownReadDefersWithoutMutatingStorage(slot: IdentitySlot) async {
    let h = IdentityHarness(a: oldId, b: oldId, c: oldId)
    h.reads[slot] = .unknown(errSecInteractionNotAllowed)
    let resolver = h.resolver()
    let outcome = await resolver.resolveAndReport()
    expectNoDifference(outcome, .deferred)
    expectNoDifference(resolver.deviceId, nil)
    expectNoDifference(h.mirror, oldId)
    expectNoDifference(h.publishedIdentities, [])
    expectNoDifference(h.actions, [])
  }

  @Test func unknownReadInvalidatesPreviouslyResolvedIdentity() async {
    let h = IdentityHarness(a: oldId, b: oldId, c: oldId)
    let resolver = h.resolver()
    _ = await resolver.resolveAndReport()
    h.reads[.canary] = .unknown(errSecNotAvailable)
    let outcome = await resolver.resolveAndReport()
    expectNoDifference(outcome, .deferred)
    expectNoDifference(resolver.deviceId, nil)
  }

  @Test(arguments: [
    false,
    true
  ]) func migrationClearsBeforePersistenceAndPreservesProof(mismatch: Bool) async {
    let h = IdentityHarness(a: oldId, b: mismatch ? proofId : nil, c: oldId)
    let resolver = h.resolver()
    let outcome = await resolver.resolveAndReport()
    expectNoDifference(outcome, .migrated(newId))
    expectNoDifference(h.actions, [
      "clear", "write:pendingTransition", "write:canary", "write:identity", "markMigration",
      "clear", "markMigration", "report", "write:canary", "write:identity", "write:appMemory",
      "credentials",
      "delete:pendingTransition",
    ])
    expectNoDifference(h.requests.first?.proofToken, proofId)
    expectNoDifference(h.requests.first?.appVersion, "1.10.0")
    expectNoDifference(resolver.deviceId, newId)
    expectNoDifference(h.mirror, newId)
    #expect(h.migrationRequired)
    expectNoDifference(h.data[.pendingTransition], nil)
    if mismatch { #expect(h.events.contains(.canaryMismatch(oldId, proofId))) }
  }

  @Test func pendingWriteFailureStillMintsNewIdentity() async {
    let h = IdentityHarness(a: oldId, c: oldId)
    h.writeFailures = [.pendingTransition]
    let resolver = h.resolver()
    let outcome = await resolver.resolveAndReport()
    expectNoDifference(outcome, .migratedUnreported(newId))
    expectNoDifference(resolver.deviceId, newId)
    expectNoDifference(h.storage.readId(.appMemory), .value(newId))
    expectNoDifference(h.connection, nil)
    expectNoDifference(h.requests, [])
    #expect(h.migrationRequired)
  }

  @Test func migrationRoutingSurvivesAcknowledgementAndRestart() async {
    let h = IdentityHarness(a: oldId, c: oldId)
    _ = await h.resolver().resolveAndReport()
    expectNoDifference(h.data[.pendingTransition], nil)
    let outcome = await h.resolver().resolveAndReport()
    expectNoDifference(outcome, .steady(newId))
    #expect(h.migrationRequired)
  }

  @Test func failedInitialCleanupStopsBeforeWritesOrNetwork() async {
    let h = IdentityHarness(a: oldId, c: oldId)
    h.clearFails = true
    let resolver = h.resolver()
    let outcome = await resolver.resolveAndReport()
    expectNoDifference(outcome, .deferred)
    expectNoDifference(resolver.deviceId, nil)
    expectNoDifference(h.actions, ["clear"])
  }

  @Test func sameDeviceReceiptFailureDoesNotReportOrExposeAnIdentity() async {
    let h = IdentityHarness(a: newId, b: newId, c: oldId)
    h.writeFailures = [.pendingTransition]
    let resolver = h.resolver()
    let outcome = await resolver.resolveAndReport()
    expectNoDifference(outcome, .deferred)
    expectNoDifference(resolver.deviceId, nil)
    expectNoDifference(h.requests, [])
  }

  @Test func unverifiedMigrationOnboardsWithoutOldCredentials() async {
    let h = IdentityHarness(a: oldId, c: oldId)
    h.proof = nil
    h.response = .init(deviceId: newId, reason: .normal)
    let outcome = await h.resolver().resolveAndReport()
    expectNoDifference(outcome, .migrated(newId))
    expectNoDifference(h.requests.first?.proofToken, nil)
    expectNoDifference(h.connection, nil)
  }

  @Test(arguments: [IdentitySlot.canary, .identity])
  func tornMigrationWriteReplaysOriginalProofAfterRestart(slot: IdentitySlot) async throws {
    let h = IdentityHarness(a: oldId, c: oldId)
    h.writeFailures = [slot]
    let resolver = h.resolver()
    let outcome = await resolver.resolveAndReport()
    expectNoDifference(outcome, .retry)
    expectNoDifference(resolver.deviceId, nil)
    expectNoDifference(h.connection, nil)
    h.writeFailures = []
    let retried = await h.resolver().resolveAndReport()
    expectNoDifference(retried, .migrated(newId))
    expectNoDifference(h.requests.first?.proofToken, proofId)
    expectNoDifference(h.requests.first?.oldDeviceId, oldId)
  }

  @Test func pendingAndSlotFailureNeverExposesOldIdentity() async {
    let h = IdentityHarness(a: oldId, c: oldId)
    h.writeFailures = [.pendingTransition, .canary]
    let resolver = h.resolver()
    let outcome = await resolver.resolveAndReport()
    expectNoDifference(outcome, .deferred)
    expectNoDifference(resolver.deviceId, nil)
    expectNoDifference(h.connection, nil)
    expectNoDifference(h.mirror, nil)
  }

  @Test func pendingWinsOverUnreadableIdentitySlots() async throws {
    let h = IdentityHarness()
    try h.pending()
    h.reads[.identity] = .unknown(errSecInteractionNotAllowed)
    let outcome = await h.resolver().resolveAndReport()
    expectNoDifference(outcome, .migrated(newId))
    expectNoDifference(h.requests.first?.kind, .migrated)
  }

  @Test func lostNetworkReplyRetriesIdempotentReportAfterRestart() async {
    let h = IdentityHarness(a: oldId, c: oldId)
    h.reportFails = true
    let resolver = h.resolver()
    let outcome = await resolver.resolveAndReport()
    expectNoDifference(outcome, .retry)
    expectNoDifference(resolver.deviceId, nil)
    #expect(h.data[.pendingTransition] != nil)
    h.reportFails = false
    let retried = await h.resolver().resolveAndReport()
    expectNoDifference(retried, .migrated(newId))
    expectNoDifference(h.requests.count, 2)
    expectNoDifference(h.requests.first, h.requests.last)
    #expect(h.events.contains(.reportFailed))
  }

  @Test func siblingFirstMigrationClearsBeforeAcknowledgementWrites() async {
    let h = IdentityHarness(a: newId, b: newId, c: oldId)
    h.response = .init(
      deviceId: newId,
      reason: .resolvedAsMigration,
      childId: childId,
      token: newId,
    )
    let outcome = await h.resolver().resolveAndReport()
    expectNoDifference(outcome, .migrated(newId))
    expectNoDifference(h.actions, [
      "write:pendingTransition", "report", "clear", "markMigration", "write:canary",
      "write:identity", "write:appMemory", "credentials", "delete:pendingTransition",
    ])
    #expect(h.migrationRequired)
    expectNoDifference(h.connection, newId)
    #expect(h.events.contains(.resolution(.migrated(newId), matchesLiveVendorId: true)))
  }

  @Test func supervisionCanonicalAcknowledgementRestoresSharedIdentity() async {
    let h = IdentityHarness(a: newId, b: newId, c: oldId)
    h.response = .init(
      deviceId: oldId,
      reason: .supervisionCanonical,
      childId: childId,
      token: proofId,
    )
    let outcome = await h.resolver().resolveAndReport()
    expectNoDifference(outcome, .adopted(oldId))
    expectNoDifference(h.storage.readId(.identity), .value(oldId))
    expectNoDifference(h.storage.readId(.canary), .value(oldId))
    #expect(!h.migrationRequired)
    expectNoDifference(h.events, [
      .resolution(.adopted(oldId), matchesLiveVendorId: false),
    ])
  }

  @Test func childConflictPinsOnlyPrivateMemoryAndRetriesNextActivation() async {
    let h = IdentityHarness(a: newId, b: newId, c: oldId)
    h.response = .init(deviceId: oldId, reason: .childConflictPin, childId: childId, token: proofId)
    let resolver = h.resolver()
    let outcome = await resolver.resolveAndReport()
    expectNoDifference(outcome, .pinned(oldId))
    #expect(h.events.contains(.resolution(.pinned(oldId), matchesLiveVendorId: false)))
    expectNoDifference(h.storage.readId(.identity), .value(newId))
    expectNoDifference(h.storage.readId(.canary), .value(newId))
    expectNoDifference(h.storage.readId(.appMemory), .value(oldId))
    #expect(!h.actions.contains("write:identity"))
    #expect(!h.actions.contains("write:canary"))
    h.response = nil
    let retried = await resolver.resolveAndReport()
    expectNoDifference(retried, .adopted(newId))
    expectNoDifference(h.requests.count, 2)
  }

  @Test(arguments: [IdentitySlot.canary, .identity, .appMemory])
  func acknowledgementWriteFailuresRetainReceipt(slot: IdentitySlot) async throws {
    let h = IdentityHarness(a: newId, b: newId, c: oldId)
    try h.pending(.sameDevice)
    h.writeFailures = [slot]
    let resolver = h.resolver()
    let outcome = await resolver.resolveAndReport()
    expectNoDifference(outcome, .retry)
    expectNoDifference(resolver.deviceId, oldId)
    #expect(h.data[.pendingTransition] != nil)
    h.writeFailures = []
    let retried = await h.resolver().resolveAndReport()
    expectNoDifference(retried, .adopted(newId))
  }

  @Test(arguments: ["credentials", "delete", "marker", "clear"])
  func consumerAndReceiptFailuresRetry(step: String) async throws {
    let h = IdentityHarness(a: oldId, c: oldId)
    try h.pending()
    h.credentialsFail = step == "credentials"
    h.deleteFails = step == "delete"
    h.markerFails = step == "marker"
    h.clearFails = step == "clear"
    let resolver = h.resolver()
    let outcome = await resolver.resolveAndReport()
    expectNoDifference(outcome, step == "clear" || step == "marker" ? .deferred : .retry)
    expectNoDifference(resolver.deviceId, nil)
    #expect(h.data[.pendingTransition] != nil)
    h.credentialsFail = false
    h.deleteFails = false
    h.markerFails = false
    h.clearFails = false
    let retried = await h.resolver().resolveAndReport()
    expectNoDifference(retried, .migrated(newId))
  }

  @Test func persistentNovelReadStaysUnknownAndLogsAfterFiveActivations() async {
    let h = IdentityHarness(a: oldId, b: oldId, c: oldId)
    h.reads[.canary] = .unknown(-999)
    let resolver = h.resolver()
    for _ in 0 ..< 6 {
      let outcome = await resolver.resolveAndReport()
      expectNoDifference(outcome, .deferred)
    }
    expectNoDifference(h.events.count(where: { $0 == .persistentUnknownRead(.canary, -999) }), 1)
    expectNoDifference(h.actions, [])
    h.reads[.canary] = nil
    let retried = await resolver.resolveAndReport()
    expectNoDifference(retried, .steady(oldId))
  }

  @Test(arguments: [false, true])
  func corruptPendingSettlesPrivateMemoryBeforeDeletingReceipt(migrated: Bool) async {
    let h = IdentityHarness(a: newId, b: newId, c: oldId)
    if migrated {
      h.connection = nil
      h.proof = nil
      h.mirror = nil
    }
    h.data[.pendingTransition] = Data("broken".utf8)
    let resolver = h.resolver()
    let outcome = resolver.resolveOnForeground()
    expectNoDifference(outcome, .steady(newId))
    expectNoDifference(resolver.deviceId, newId)
    expectNoDifference(h.storage.readId(.appMemory), .value(newId))
    expectNoDifference(h.data[.pendingTransition], nil)
    expectNoDifference(h.actions, ["write:appMemory", "delete:pendingTransition"])
    #expect(h.events.contains(.invalidPendingTransition))
    let restarted = await h.resolver().resolveAndReport()
    expectNoDifference(restarted, .steady(newId))
    expectNoDifference(h.requests, [])
    expectNoDifference(h.connection, migrated ? nil : proofId)
  }

  @Test(arguments: [
    "missingIdentity",
    "missingCanary",
    "mismatch",
    "unreadableIdentity",
    "unreadableCanary"
  ])
  func corruptPendingWithUncertainHardwareStateDefersWithoutWrites(state: String) {
    let h = IdentityHarness(a: newId, b: newId, c: oldId)
    let corrupt = Data("broken".utf8)
    h.data[.pendingTransition] = corrupt
    switch state {
    case "missingIdentity": h.data[.identity] = nil
    case "missingCanary": h.data[.canary] = nil
    case "mismatch": h.data[.canary] = Data(oldId.uuidString.utf8)
    case "unreadableIdentity": h.reads[.identity] = .unknown(errSecInteractionNotAllowed)
    default: h.reads[.canary] = .unknown(errSecInteractionNotAllowed)
    }
    let resolver = h.resolver()
    expectNoDifference(resolver.resolveOnForeground(), .deferred)
    expectNoDifference(resolver.deviceId, nil)
    expectNoDifference(h.data[.pendingTransition], corrupt)
    expectNoDifference(h.storage.readId(.appMemory), .value(oldId))
    expectNoDifference(h.actions, [])
  }

  @Test(arguments: [false, true])
  func corruptPendingRecoveryRetriesFailedPersistence(deleteFails: Bool) async {
    let h = IdentityHarness(a: newId, b: newId, c: oldId)
    let corrupt = Data("broken".utf8)
    h.data[.pendingTransition] = corrupt
    h.deleteFails = deleteFails
    h.writeFailures = deleteFails ? [] : [.appMemory]
    let resolver = h.resolver()
    expectNoDifference(resolver.resolveOnForeground(), .deferred)
    expectNoDifference(resolver.deviceId, nil)
    expectNoDifference(h.data[.pendingTransition], corrupt)
    expectNoDifference(
      h.actions,
      deleteFails
        ? ["write:appMemory", "delete:pendingTransition"] : ["write:appMemory"],
    )
    h.deleteFails = false
    h.writeFailures = []
    let restarted = await h.resolver().resolveAndReport()
    expectNoDifference(restarted, .steady(newId))
    expectNoDifference(h.storage.readId(.appMemory), .value(newId))
    expectNoDifference(h.data[.pendingTransition], nil)
    expectNoDifference(h.requests, [])
  }

  @Test func undecryptablePendingUsesTheSameRecoveryAsMalformedData() {
    let h = IdentityHarness(a: newId, b: newId, c: oldId)
    h.reads[.pendingTransition] = .unknown(errSecDecode)
    let resolver = h.resolver()
    expectNoDifference(resolver.resolveOnForeground(), .steady(newId))
    expectNoDifference(h.storage.readId(.appMemory), .value(newId))
    expectNoDifference(h.actions, ["write:appMemory", "delete:pendingTransition"])
    #expect(h.events.contains(.invalidPendingTransition))
  }

  @Test func simultaneousForegroundCallsShareOneResolution() async {
    let h = IdentityHarness(a: newId, b: newId, c: oldId)
    let resolver = h.resolver()
    var reply: CheckedContinuation<ReportIdentityTransition.Output, Never>?
    var first: Task<IdentityResolver.Outcome, Never>?
    await withCheckedContinuation { started in
      h.transport = { _ in
        await withCheckedContinuation { continuation in
          reply = continuation
          started.resume()
        }
      }
      first = Task { await resolver.resolveAndReport() }
    }
    var second: Task<IdentityResolver.Outcome, Never>?
    await withCheckedContinuation { started in
      second = Task {
        started.resume()
        return await resolver.resolveAndReport()
      }
    }
    expectNoDifference(resolver.deviceId, oldId)
    expectNoDifference(h.requests.count, 1)
    expectNoDifference(h.events, [.resolution(.adopted(oldId), matchesLiveVendorId: false)])
    reply?.resume(returning: .init(deviceId: newId, reason: .normal))
    let outcome = await first?.value
    expectNoDifference(outcome, .adopted(newId))
    let retried = await second?.value
    expectNoDifference(retried, .adopted(newId))
    expectNoDifference(h.requests.count, 1)
    expectNoDifference(resolver.deviceId, newId)
    expectNoDifference(h.events, [
      .resolution(.adopted(oldId), matchesLiveVendorId: false),
      .resolution(.adopted(newId), matchesLiveVendorId: true),
    ])
  }
}
