import ComposableArchitecture
import CustomDump
import DeviceIdentity
import Foundation
import IOSAppsRoute
import PodcastRoute
import SQLiteData
import Testing

@testable import LibTCA

@MainActor
struct PodcastIdentityTests {
  @Test(arguments: [false, true])
  func missingDeviceIdPreservesOrphanTokenAcrossRestart(hasLegacyInstallId: Bool) async throws {
    let fixture = PodcastIdentityFixture()
    fixture.slots[.appMemory] = nil
    fixture.reportFails = true
    if hasLegacyInstallId { fixture.keychain.save(installId: UUID(8)) }
    let identity = fixture.identity()
    let result = identity.resolve()
    expectNoDifference(result.available, true)
    expectNoDifference(result.connection, nil)
    expectNoDifference(fixture.keychain.isClaimed(), false)
    try expectNoDifference(fixture.keychain._load(.orphanedAmToken), Data(UUID(3).uuidString.utf8))
    _ = await identity.report()
    let restarted = fixture.identity()
    expectNoDifference(restarted.resolve().connection, nil)
    _ = await restarted.report()
    expectNoDifference(fixture.requests.compactMap(\.proofToken), [])
    try expectNoDifference(fixture.keychain._load(.orphanedAmToken), Data(UUID(3).uuidString.utf8))
  }

  @Test func failedOrphanPreservationLeavesTokenAndIdentityUntouched() throws {
    let fixture = PodcastIdentityFixture()
    fixture.slots[.appMemory] = nil
    fixture.keychain.save(installId: UUID(8))
    _ = fixture.failedWrites.withValue { $0.insert(.orphanedAmToken) }
    expectNoDifference(fixture.identity().resolve().available, false)
    expectNoDifference(fixture.keychain.loadAmToken(), UUID(3))
    expectNoDifference(fixture.slots[.appMemory], nil)
    try expectNoDifference(fixture.keychain._load(.legacyMigration), nil)
  }

  @Test func orphanTokenAllowsEntitlementRecoveryForResolvedIdentity() async throws {
    let fixture = PodcastIdentityFixture()
    fixture.slots[.appMemory] = nil
    let identity = fixture.identity()
    let session = identity.resolve()
    expectNoDifference(session.deviceId, UUID(2))
    try await withDependencies {
      $0.date.now = .reference
      $0.defaultDatabase = try appDatabase()
      $0.keychain = fixture.keychain
      $0.podcastIdentity.current = { identity.resolution() }
      $0.podcastIdentity.saveToken = { try identity.saveToken($0, childId: $1) }
      $0.podcastIdentity.completeMigration = { try identity.completeMigration() }
      $0.api.getTrialStatus = {
        let current = await identity.resolution()
        expectNoDifference(current.deviceId, UUID(2))
        return .connected(
          token: UUID(4), childId: UUID(5), childName: "Child",
          subscription: .active(expiresAt: .distantFuture),
        )
      }
    } operation: {
      await AppReducer().refreshEntitlement()
      try expectNoDifference(
        fixture.keychain.readConnection(),
        .init(token: UUID(4), deviceId: UUID(2), childId: UUID(5)),
      )
      expectNoDifference(dep(\.db).subscription().status, .active)
      expectNoDifference(fixture.keychain.isClaimed(), true)
      try expectNoDifference(
        fixture.keychain._load(.orphanedAmToken),
        Data(UUID(3).uuidString.utf8),
      )
    }
  }

  @Test func bindsLegacyTokenBeforeAdoptingSharedIdentity() throws {
    let fixture = PodcastIdentityFixture()
    let result = fixture.identity().resolve()
    expectNoDifference(result.deviceId, UUID(1))
    expectNoDifference(result.needsReport, true)
    try expectNoDifference(
      fixture.keychain.readConnection(),
      .init(token: UUID(3), deviceId: UUID(1)),
    )
    expectNoDifference(fixture.id(.appMemory), UUID(1))
  }

  @Test func offlineAdoptionKeepsCredentialsAcrossRestart() async throws {
    let fixture = PodcastIdentityFixture()
    fixture.reportFails = true
    let identity = fixture.identity()
    _ = identity.resolve()
    let offline = await identity.report()
    expectNoDifference(offline.deviceId, UUID(1))
    let restarted = fixture.identity()
    expectNoDifference(restarted.resolve().connection?.token, UUID(3))
    fixture.reportFails = false
    let result = await restarted.report()
    expectNoDifference(result.deviceId, UUID(2))
    expectNoDifference(result.connection?.token, UUID(4))
    expectNoDifference(fixture.requests.map(\.proofToken), [UUID(3), UUID(3)])
  }

  @Test func failedCredentialSaveKeepsOriginalBindingAfterPartialAcknowledgement() async throws {
    let fixture = PodcastIdentityFixture()
    let identity = fixture.identity()
    _ = identity.resolve()
    _ = fixture.failedWrites.withValue { $0.insert(.connection) }
    let result = await identity.report()
    expectNoDifference(result.deviceId, UUID(1))
    expectNoDifference(fixture.id(.appMemory), UUID(2))
    expectNoDifference(result.connection?.token, UUID(3))
    _ = fixture.failedWrites.withValue { $0.remove(.connection) }
    let restarted = fixture.identity()
    expectNoDifference(restarted.resolve().deviceId, UUID(1))
    let retried = await restarted.report()
    expectNoDifference(retried.connection?.token, UUID(4))
    expectNoDifference(fixture.requests.map(\.proofToken), [UUID(3), UUID(3)])
  }

  @Test func failedReceiptDeletionUsesSavedDestinationCredentials() async throws {
    let fixture = PodcastIdentityFixture()
    fixture.deleteReceiptFails = true
    let identity = fixture.identity()
    _ = identity.resolve()
    _ = await identity.report()
    let restarted = fixture.identity()
    expectNoDifference(restarted.resolve().connection?.deviceId, UUID(2))
    fixture.deleteReceiptFails = false
    _ = await restarted.report()
    expectNoDifference(fixture.requests.map(\.proofToken), [UUID(3), UUID(3)])
    expectNoDifference(fixture.slots[.pendingTransition], nil)
  }

  @Test func cleanupFailurePreservesProofUntilRetry() async throws {
    let fixture = PodcastIdentityFixture()
    fixture.set(.identity, UUID(1))
    fixture.slots[.canary] = nil
    fixture.clearFails = true
    let identity = fixture.identity()
    expectNoDifference(identity.resolve().available, false)
    try expectNoDifference(fixture.keychain.readConnection()?.token, UUID(3))
    expectNoDifference(fixture.slots[.pendingTransition], nil)
    fixture.clearFails = false
    let restarted = fixture.identity()
    expectNoDifference(restarted.resolve().available, false)
    let result = await restarted.report()
    expectNoDifference(result.deviceId, UUID(6))
    expectNoDifference(result.migrationPending, true)
    expectNoDifference(fixture.requests.first?.proofToken, UUID(3))
    try restarted.completeMigration()
    try expectNoDifference(fixture.keychain.migrationPending, false)
  }

  @Test func unreadableMarkerDoesNotClearCredentialsOrLibrary() throws {
    let fixture = PodcastIdentityFixture()
    _ = fixture.failedReads.withValue { $0.insert(.migration) }
    expectNoDifference(fixture.identity().resolve().available, false)
    expectNoDifference(fixture.clears, 0)
    expectNoDifference(fixture.keychain.loadAmToken(), UUID(3))
  }

  @Test func siblingMigrationRemainsBlockedOfflineAfterPartialAcknowledgement() async throws {
    let fixture = PodcastIdentityFixture()
    fixture.reason = .resolvedAsMigration
    fixture.deleteReceiptFails = true
    let identity = fixture.identity()
    _ = identity.resolve()
    _ = await identity.report()
    fixture.reportFails = true
    let restarted = fixture.identity()
    expectNoDifference(restarted.resolve().available, false)
    let retried = await restarted.report()
    expectNoDifference(retried.available, false)
    expectNoDifference(fixture.requests.map(\.proofToken), [UUID(3), UUID(3)])
    try expectNoDifference(fixture.keychain.migrationPending, true)
  }

  @Test func nilTokenDoesNotLeaveMismatchedCredentials() async throws {
    let fixture = PodcastIdentityFixture()
    fixture.returnToken = false
    let identity = fixture.identity()
    _ = identity.resolve()
    let result = await identity.report()
    expectNoDifference(result.deviceId, UUID(2))
    try expectNoDifference(fixture.keychain.readConnection(), nil)
    expectNoDifference(fixture.keychain.loadAmToken(), nil)
  }

  @Test func legacyEventMigrationRetriesOriginalDestinationAfterSharedAdoption() async throws {
    let fixture = PodcastIdentityFixture()
    try fixture.keychain.removeConnection()
    fixture.keychain.save(installId: UUID(8))
    fixture.slots[.appMemory] = nil
    fixture.reportFails = true
    let identity = fixture.identity()
    _ = identity.resolve()
    _ = await identity.report()
    fixture.reportFails = false
    let restarted = fixture.identity()
    _ = restarted.resolve()
    _ = await restarted.report()
    expectNoDifference(fixture.legacyReports.map(\.0), [UUID(8), UUID(8)])
    expectNoDifference(fixture.legacyReports.map(\.1), [UUID(7), UUID(7)])
    try expectNoDifference(fixture.keychain._load(.legacyMigration), nil)
  }

  @Test func interruptedLegacyPreparationRestoresOriginalDestination() throws {
    let fixture = PodcastIdentityFixture()
    try fixture.keychain.removeConnection()
    fixture.keychain.save(installId: UUID(8))
    fixture.slots[.appMemory] = nil
    fixture.failedSlot = .appMemory
    expectNoDifference(fixture.identity().resolve().available, false)
    fixture.failedSlot = nil
    expectNoDifference(fixture.identity().resolve().deviceId, UUID(7))
  }

  @Test func migrationClearsEntitlementAndPlaybackButKeepsParentLibraryAndPin() throws {
    let fixture = PodcastIdentityFixture()
    fixture.keychain.save(pincode: 123_456)
    fixture.keychain.save(installDate: .reference)
    fixture.slots[.canary] = nil
    fixture.clearState = PodcastIdentity.clearState
    let reset = LockIsolated(false)
    var downloadedEpisode = Episode.mock
    downloadedEpisode.downloadedAt = .reference
    downloadedEpisode.progress = 120
    let preservedEpisode = downloadedEpisode
    try withDependencies {
      $0.defaultDatabase = try appDatabase()
      $0.audio.reset = { reset.setValue(true) }
      $0.audio.pause = {}
    } operation: {
      try dep(\.db).write { db in
        try Show.insert {
          Show.mock
        }.execute(db)
        try Episode.insert { preservedEpisode }.execute(db)
        try NowPlayingModel.insert { NowPlayingModel(episodeId: Episode.mock.id) }.execute(db)
      }
      _ = try CurrentSubscription.set(status: .active, expiringAt: .distantFuture)
      expectNoDifference(fixture.identity().resolve().migrationPending, true)
      expectNoDifference(dep(\.db).subscription().status, .unpaid)
      expectNoDifference(dep(\.db).tryRead { try Show.all.fetchCount($0) }, 1)
      expectNoDifference(fixture.keychain.loadPincode(), 123_456)
      expectNoDifference(fixture.keychain.loadInstallDate(), .reference)
      expectNoDifference(reset.value, true)
      expectNoDifference(dep(\.db).nowPlaying()?.episode.id, nil)
      let episode = dep(\.db).tryRead { try Episode.find(Episode.mock.id).fetchOne($0) }
      expectNoDifference(episode?.progress, preservedEpisode.progress)
      expectNoDifference(episode?.downloadedAt, preservedEpisode.downloadedAt)
    }
  }

  @Test func staleEntitlementCannotRestoreClearedCredentials() async throws {
    let session = LockIsolated(PodcastIdentityClient.Resolution(deviceId: UUID(1)))
    let started = AsyncStream<Void>.makeStream()
    let response = AsyncStream<GetTrialStatus.Output>.makeStream()
    let saved = LockIsolated(false)
    try await withDependencies {
      $0.defaultDatabase = try appDatabase()
      $0.keychain = dictKeychain()
      $0.podcastIdentity.current = { session.value }
      $0.podcastIdentity.saveToken = { _, _ in saved.setValue(true) }
      $0.api.getTrialStatus = {
        started.continuation.yield(())
        for await output in response.stream {
          return output
        }
        throw CancellationError()
      }
    } operation: {
      _ = try CurrentSubscription.set(status: .unpaid, expiringAt: .reference)
      let task = Task { await AppReducer().refreshEntitlement() }
      for await _ in started.stream {
        break
      }
      session.setValue(.init(available: false, migrationPending: true))
      response.continuation.yield(.connected(
        token: UUID(3), childId: UUID(5), childName: "Child",
        subscription: .active(expiresAt: .distantFuture),
      ))
      await task.value
      expectNoDifference(saved.value, false)
      expectNoDifference(dep(\.db).subscription().status, .unpaid)
    }
  }

  @Test func staleChildResponseCannotRestoreOldClaimScreen() async throws {
    try await withDependencies {
      $0.defaultDatabase = try appDatabase()
    } operation: {
      let state = AppReducer.State(
        mode: .onboarding(.init()), identity: .init(deviceId: UUID(2)),
      )
      state.$identityGeneration.withLock { $0 = 2 }
      let store = TestStore(initialState: state) { AppReducer() }
      await store.send(.mode(.presented(.onboarding(.trialStatusResponse(
        .connected(
          token: UUID(3),
          childId: UUID(5),
          childName: "Old child",
          subscription: .active(expiresAt: .distantFuture),
        ),
        generation: 1,
      )))))
      await store.finish()
    }
  }

  @Test func readFailurePreservesRunningLibraryAndNavigation() async throws {
    try await withDependencies {
      $0.defaultDatabase = try appDatabase()
    } operation: {
      let store = TestStore(initialState: AppReducer.State(
        mode: .podcasts(.init()), identity: .init(deviceId: UUID(1)),
      )) { AppReducer() }
      await store.send(.identityResolved(.init(available: false))) {
        $0.identity = .init(available: false)
        $0.$identityGeneration.withLock { $0 = 1 }
      }
      await store.finish()
    }
  }
}
