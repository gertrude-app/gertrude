import ComposableArchitecture
import CustomDump
import DeviceIdentity
import Foundation
import IOSAppsRoute
import Security
import Testing

@testable import LibTCA

@MainActor
@Suite
struct MusicIdentityTests {
  @Test
  func transientMigrationMarkerReadDuringReportingPreservesConnectionAndReceipt() async throws {
    let harness = MusicIdentityFixture()
    harness.keychain.client.save(connection: harness.legacyConnection)
    let identity = harness.identity()
    _ = identity.resolve()
    let connection = try harness.keychain.client.readConnection()
    let receipt = harness.data[.pendingTransition]
    harness.keychain.readFailuresRemaining.withValue { $0[.migration] = 1 }

    let result = await identity.report()

    expectNoDifference(result.available, false)
    expectNoDifference(result.migrationPending, false)
    try expectNoDifference(harness.keychain.client.readConnection(), connection)
    expectNoDifference(harness.clearedChildren, [])
    expectNoDifference(harness.data[.pendingTransition], receipt)
    expectNoDifference(harness.requests.count, 0)
    try expectNoDifference(harness.keychain.client._load(.migration), nil)

    expectNoDifference(identity.resolve().deviceId, UUID(1))
    let retried = await identity.report()
    expectNoDifference(retried.deviceId, UUID(2))
    expectNoDifference(retried.connection?.childName, "Harriet")
    expectNoDifference(harness.data[.pendingTransition], nil)
  }

  @Test
  func unreadableMigrationMarkerPreservesConfirmedMigrationUntilRetry() async throws {
    let harness = MusicIdentityFixture()
    harness.keychain.client.save(connection: harness.legacyConnection)
    harness.reason = .resolvedAsMigration
    harness.deleteReceiptFails = true
    let identity = harness.identity()
    _ = identity.resolve()
    _ = await identity.report()
    let connection = try harness.keychain.client.readConnection()
    let receipt = harness.data[.pendingTransition]
    let clearedChildren = harness.clearedChildren
    harness.keychain.readFailuresRemaining.withValue { $0[.migration] = 1 }

    let result = await identity.report()

    expectNoDifference(result.available, false)
    try expectNoDifference(harness.keychain.client.readConnection(), connection)
    expectNoDifference(harness.clearedChildren, clearedChildren)
    expectNoDifference(harness.data[.pendingTransition], receipt)
    try expectNoDifference(identity.migrationPending, true)

    harness.deleteReceiptFails = false
    let retried = await identity.report()
    expectNoDifference(retried.available, true)
    expectNoDifference(retried.migrationPending, true)
    expectNoDifference(harness.data[.pendingTransition], nil)
  }

  @Test
  func unavailableIdentityWithoutConfirmedMigrationPreservesRuntimeState() async {
    let connection = MusicAppConnection(
      token: UUID(3), childId: UUID(5), childName: "Harriet", deviceId: UUID(1),
    )
    var state = AppFeature.State(
      identityGeneration: 1,
      identity: .init(deviceId: UUID(1), connection: connection),
    )
    state.library.status = .loaded(.mock)
    state.playback.session = .init(currentItem: playbackItem("old-track"))
    state.setup.screen = .ready(childName: "Harriet")
    let stopped = LockIsolated(false)
    let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
      $0.playback.stop = { stopped.setValue(true) }
    }
    store.exhaustivity = .off(showSkippedAssertions: false)
    await store.send(.identityResolved(.init(available: false)))
    await store.finish()
    expectNoDifference(store.state.library.status, state.library.status)
    expectNoDifference(store.state.playback.session, state.playback.session)
    expectNoDifference(store.state.setup.screen, state.setup.screen)
    expectNoDifference(stopped.value, false)
  }

  @Test
  func legacyConnectionIsBoundBeforeSharedIdentityAdoption() throws {
    let harness = MusicIdentityFixture()
    harness.keychain.client.save(connection: harness.legacyConnection)
    let identity = harness.identity()

    let resolution = identity.resolve()

    expectNoDifference(resolution.deviceId, UUID(1))
    expectNoDifference(resolution.needsReport, true)
    try expectNoDifference(identity.connection()?.deviceId, UUID(1))
    expectNoDifference(harness.id(.appMemory), UUID(1))
  }

  @Test
  func offlineSameDeviceReportKeepsOriginalCredentialsAcrossRestart() async throws {
    let harness = MusicIdentityFixture()
    harness.keychain.client.save(connection: harness.legacyConnection)
    harness.reportFails = true
    let identity = harness.identity()
    _ = identity.resolve()
    let offline = await identity.report()
    expectNoDifference(offline.available, true)
    expectNoDifference(offline.deviceId, UUID(1))

    let restarted = harness.identity()
    expectNoDifference(restarted.resolve().deviceId, UUID(1))
    try expectNoDifference(restarted.connection()?.token, UUID(3))
    harness.reportFails = false
    let acknowledged = await restarted.report()
    expectNoDifference(acknowledged.deviceId, UUID(2))
    try expectNoDifference(restarted.connection()?.token, UUID(4))
    expectNoDifference(harness.requests.map(\.proofToken), [UUID(3), UUID(3)])
  }

  @Test
  func failedCredentialSaveDoesNotAdoptPartiallyWrittenIdentity() async throws {
    let harness = MusicIdentityFixture()
    harness.keychain.client.save(connection: harness.legacyConnection)
    let identity = harness.identity()
    _ = identity.resolve()
    _ = harness.keychain.writeFailures.withValue { $0.insert(.connection) }
    _ = await identity.report()
    expectNoDifference(harness.id(.appMemory), UUID(2))
    expectNoDifference(identity.deviceId, UUID(1))
    try expectNoDifference(identity.connection()?.token, UUID(3))

    _ = harness.keychain.writeFailures.withValue { $0.remove(.connection) }
    let restarted = harness.identity()
    expectNoDifference(restarted.resolve().deviceId, UUID(1))
    _ = await restarted.report()
    try expectNoDifference(restarted.connection()?.deviceId, UUID(2))
    expectNoDifference(harness.requests.map(\.proofToken), [UUID(3), UUID(3)])
  }

  @Test
  func failedReceiptDeletionUsesSuccessfullySavedCredentialsOnRestart() async throws {
    let harness = MusicIdentityFixture()
    harness.keychain.client.save(connection: harness.legacyConnection)
    let identity = harness.identity()
    _ = identity.resolve()
    harness.deleteReceiptFails = true
    _ = await identity.report()
    expectNoDifference(identity.deviceId, UUID(2))
    let restarted = harness.identity()
    expectNoDifference(restarted.resolve().deviceId, UUID(2))
    try expectNoDifference(restarted.connection()?.token, UUID(4))
    harness.deleteReceiptFails = false
    _ = await restarted.report()
    expectNoDifference(harness.requests.map(\.proofToken), [UUID(3), UUID(3)])
  }

  @Test
  func migrationClearsConnectionAndCachesBeforeReportingAndSurvivesRestart() async throws {
    let harness = MusicIdentityFixture()
    harness.data[.identity] = Data(UUID(1).uuidString.utf8)
    harness.data[.canary] = nil
    harness.keychain.client.save(connection: harness.legacyConnection)
    harness.reportFails = true
    let identity = harness.identity()
    let resolution = identity.resolve()
    expectNoDifference(resolution.available, false)
    expectNoDifference(resolution.migrationPending, true)
    expectNoDifference(harness.keychain.client.loadConnection(), nil)
    expectNoDifference(harness.clearedChildren, [UUID(5)])
    expectNoDifference(harness.requests.count, 0)
    _ = await identity.report()

    let restarted = harness.identity()
    expectNoDifference(restarted.resolve().available, false)
    harness.reportFails = false
    let acknowledged = await restarted.report()
    expectNoDifference(acknowledged.available, true)
    expectNoDifference(acknowledged.migrationPending, true)
    try expectNoDifference(restarted.connection()?.deviceId, UUID(2))
    try restarted.completeMigration()
    try expectNoDifference(restarted.migrationPending, false)
    expectNoDifference(harness.requests.map(\.proofToken), [UUID(3), UUID(3)])
  }

  @Test
  func siblingMigrationClearsStateAndKeepsSetupPendingAfterAcknowledgement() async throws {
    let harness = MusicIdentityFixture()
    harness.keychain.client.save(connection: harness.legacyConnection)
    harness.reason = .resolvedAsMigration
    let identity = harness.identity()
    expectNoDifference(identity.resolve().available, true)
    let result = await identity.report()
    expectNoDifference(result.migrationPending, true)
    expectNoDifference(harness.clearedChildren, [UUID(5)])
    try expectNoDifference(identity.connection()?.deviceId, UUID(2))
    try expectNoDifference(identity.connection()?.childName, "")
  }

  @Test
  func uncertainCredentialReadDoesNotResolveOrRewriteLegacyIdentity() {
    let harness = MusicIdentityFixture()
    harness.keychain.client.save(connection: harness.legacyConnection)
    _ = harness.keychain.readFailures.withValue { $0.insert(.connection) }
    let identity = harness.identity()
    expectNoDifference(identity.resolve().available, false)
    expectNoDifference(harness.id(.appMemory), UUID(1))
    expectNoDifference(harness.data[.pendingTransition], nil)
  }

  @Test
  func failedMigrationCleanupPreservesProofForRetryAfterRestart() async throws {
    let harness = MusicIdentityFixture()
    harness.data[.canary] = nil
    harness.keychain.client.save(connection: harness.legacyConnection)
    harness.clearFails = true
    let identity = harness.identity()
    expectNoDifference(identity.resolve().available, false)
    try expectNoDifference(harness.keychain.client.readConnection()?.token, UUID(3))
    expectNoDifference(harness.data[.pendingTransition], nil)
    expectNoDifference(harness.requests.count, 0)
    harness.clearFails = false
    let restarted = harness.identity()
    expectNoDifference(restarted.resolve().available, false)
    try expectNoDifference(restarted.migrationPending, true)
    expectNoDifference(harness.clearedChildren, [UUID(5), UUID(5)])
    try expectNoDifference(harness.keychain.client.readConnection(), nil)

    let acknowledged = await restarted.report()
    expectNoDifference(harness.requests.map(\.proofToken), [UUID(3)])
    expectNoDifference(acknowledged.available, true)
    expectNoDifference(acknowledged.connection?.childId, UUID(5))
    expectNoDifference(harness.data[.pendingTransition], nil)
  }

  @Test
  func acknowledgementWithoutCredentialsDiscardsMismatchedConnection() async throws {
    let harness = MusicIdentityFixture()
    harness.keychain.client.save(connection: harness.legacyConnection)
    harness.returnsCredentials = false
    let identity = harness.identity()
    _ = identity.resolve()
    let result = await identity.report()
    expectNoDifference(result.available, true)
    expectNoDifference(result.deviceId, UUID(2))
    try expectNoDifference(identity.connection(), nil)
    expectNoDifference(harness.keychain.client.loadConnection(), nil)
  }

  @Test
  func stalePlaylistResponseCannotRestoreClearedLibrary() async {
    let store = TestStore(initialState: LibraryFeature.State(generation: 2)) {
      LibraryFeature()
    }
    await store.send(.response(1, .playlistMutationResponse(.updated(.mock), rollback: nil)))
    expectNoDifference(store.state.status, .loading)
  }

  @Test
  func migrationRecoveryBypassesStoredConnectionShortcut() async {
    let keychain = KeychainStore()
    keychain.client.save(connection: .init(
      token: UUID(4), childId: UUID(5), childName: "", deviceId: UUID(2),
    ))
    let store = TestStore(initialState: MusicSetupFeature.State(
      generation: 2, deviceId: UUID(2), requiresMigrationSetup: true,
    )) { MusicSetupFeature() } withDependencies: {
      $0.keychain = keychain.client
      $0.appEvent.record = { _ in }
      $0.api.getMusicAppStatus = {
        .claimed(token: UUID(4), childId: UUID(5), childName: "Harriet", entitlement: .active)
      }
    }
    await store.send(.onAppear)
    await store.receive(.response(2, .musicAppStatusLoaded(.claimed(
      token: UUID(4), childId: UUID(5), childName: "Harriet", entitlement: .active,
    )))) {
      $0.screen = .deviceRecognized(childName: "Harriet")
    }
    expectNoDifference(keychain.client.loadConnection()?.deviceId, UUID(2))
    expectNoDifference(store.state.resumedStoredConnection, false)
  }

  @Test
  func unavailableMigratedIdentityClearsRuntimePlaybackAndLibrary() async {
    let connection = MusicAppConnection(
      token: UUID(3), childId: UUID(5), childName: "Harriet", deviceId: UUID(1),
    )
    var state = AppFeature.State(
      identityGeneration: 1,
      identity: .init(deviceId: UUID(1), connection: connection),
    )
    state.library.status = .loaded(.mock)
    state.playback.session = .init(currentItem: playbackItem("old-track"))
    state.setup.screen = .ready(childName: "Harriet")
    let stopped = LockIsolated(false)
    let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
      $0.playback.stop = { stopped.setValue(true) }
    }
    store.exhaustivity = .off(showSkippedAssertions: false)
    await store.send(.identityResolved(.init(available: false, migrationPending: true)))
    await store.finish()
    expectNoDifference(store.state.library.status, .loading)
    expectNoDifference(store.state.playback.session, nil)
    expectNoDifference(store.state.setup.requiresMigrationSetup, true)
    expectNoDifference(stopped.value, true)
  }

  @Test
  func staleAuthenticationFailureDoesNotDeleteReplacementConnection() async {
    let keychain = KeychainStore()
    let connection = MusicAppConnection(
      token: UUID(4), childId: UUID(5), childName: "Harriet", deviceId: UUID(2),
    )
    keychain.client.save(connection: connection)
    var state = AppFeature.State()
    state.library.generation = 2
    let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
      $0.keychain = keychain.client
    }
    await store.send(.library(.response(1, .delegate(.connectionInvalid))))
    expectNoDifference(keychain.client.loadConnection(), connection)
  }

  @Test
  func migrationMarkerRemainsUntilAppleMusicSetupCompletes() async {
    let keychain = KeychainStore()
    keychain.client.save(connection: .init(
      token: UUID(4), childId: UUID(5), childName: "Harriet", deviceId: UUID(2),
    ))
    let completed = LockIsolated(false)
    let store = TestStore(initialState: MusicSetupFeature.State(
      generation: 2, deviceId: UUID(2), requiresMigrationSetup: true,
    )) { MusicSetupFeature() } withDependencies: {
      $0.keychain = keychain.client
      $0.appEvent.record = { _ in }
      $0.musicIdentity.completeMigration = { completed.setValue(true) }
    }
    await store.send(.appleMusicSubscriptionStatusLoaded(.canPlayCatalogContent))
    await store.receive(.response(2, .migrationCompleted)) {
      $0.requiresMigrationSetup = false
      $0.screen = .ready(childName: "Harriet")
    }
    await store.receive(.delegate(.completed(childName: "Harriet")))
    expectNoDifference(completed.value, true)
  }

  @Test
  func staleSetupResponseCannotRestoreAnOldConnection() async {
    let keychain = KeychainStore()
    var state = MusicSetupFeature.State()
    state.generation = 2
    state.deviceId = UUID(2)
    let store = TestStore(initialState: state) { MusicSetupFeature() } withDependencies: {
      $0.keychain = keychain.client
    }
    await store.send(.response(1, .musicAppStatusLoaded(.claimed(
      token: UUID(3), childId: UUID(5), childName: "Harriet", entitlement: .active,
    ))))
    expectNoDifference(keychain.client.loadConnection(), nil)
  }
}

@MainActor
private final class MusicIdentityFixture {
  let keychain = KeychainStore()
  var data: [IdentitySlot: Data] = [
    .identity: Data(UUID(2).uuidString.utf8),
    .canary: Data(UUID(2).uuidString.utf8),
    .appMemory: Data(UUID(1).uuidString.utf8),
  ]
  var requests: [ReportIdentityTransition.Input] = []
  var clearedChildren: [UUID] = []
  var reason = ReportIdentityTransition.Reason.normal
  var reportFails = false
  var returnsCredentials = true
  var clearFails = false
  var deleteReceiptFails = false

  var legacyConnection: MusicAppConnection {
    .init(token: UUID(3), childId: UUID(5), childName: "Harriet")
  }

  func id(_ slot: IdentitySlot) -> UUID? {
    self.data[slot].flatMap { String(data: $0, encoding: .utf8) }.flatMap(UUID.init(uuidString:))
  }

  func identity() -> MusicIdentity {
    withDependencies {
      $0.uuid = .constant(UUID(2))
      $0.appEvent.record = { _ in }
    } operation: {
      MusicIdentity(
        keychain: self.keychain.client,
        storage: .init(
          read: { self.data[$0].map(IdentityRead.value) ?? .absent },
          add: { slot, data in
            guard self.data[slot] == nil else { return .duplicate }
            self.data[slot] = data
            return .success
          },
          write: { self.data[$0] = $1
            return .success
          },
          delete: {
            if self.deleteReceiptFails { return .failure(errSecNotAvailable) }
            self.data[$0] = nil
            return .success
          },
        ),
        metadata: {
          .init(
            app: .music,
            modelIdentifier: "iPhone16,1",
            iosVersion: "26.6.1",
            appVersion: "1.1.0",
            liveVendorId: UUID(2),
          )
        },
        clearCaches: {
          self.clearedChildren.append($0)
          if self.clearFails { throw TestError() }
        },
        report: {
          self.requests.append($0)
          if self.reportFails { throw TestError() }
          return .init(
            deviceId: $0.newDeviceId,
            reason: self.reason,
            childId: self.returnsCredentials ? UUID(5) : nil,
            token: self.returnsCredentials ? UUID(4) : nil,
          )
        },
        telemetry: { _ in },
      )
    }
  }
}
