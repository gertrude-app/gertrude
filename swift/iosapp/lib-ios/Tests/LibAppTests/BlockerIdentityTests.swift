import BlockerRoute
import ComposableArchitecture
import DeviceIdentity
import IOSAppsRoute
import Testing

@testable import LibApp
@testable import LibClients

@MainActor
struct BlockerIdentityTests {
  @Test func migrationClearsConnectionBeforeWritesAndRetainsProofAcrossOfflineRestart(
  ) async throws {
    let fixture = IdentityFixture(migrating: true)
    let identity = fixture.makeIdentity()
    #expect(identity.resolve() == .init(
      available: false,
      migrationPending: true,
      needsReport: true,
    ))
    #expect(fixture.state.value.connection == nil)
    #expect(fixture.state.value.mirror == nil)
    #expect(fixture.state.value.apiCleared)
    #expect(fixture.wroteBeforeCleanup == false)
    #expect(await identity.report() == .init(available: false, migrationPending: true))

    let restarted = fixture.makeIdentity()
    #expect(restarted.resolve().available == false)
    fixture.offline = false
    #expect(await restarted.report() == .init(migrationPending: true))
    #expect(fixture.reports.last?.proofToken == UUID(2))
    #expect(fixture.state.value.connection?.deviceId == UUID(4))
    #expect(fixture.state.value.connection?.token == UUID(5))
    #expect(fixture.state.value.connection?.supervised == nil)
    #expect(fixture.state.value.mirror == UUID(4))
    #expect(fixture.state.value.migrationPending)
  }

  @Test func sameDeviceIdentityWorksOfflineWithoutClearingConnection() async {
    let fixture = IdentityFixture(migrating: false)
    for _ in 0 ..< 3 {
      let identity = fixture.makeIdentity()
      #expect(identity.resolve() == .init(needsReport: true))
      #expect(identity.resolver.deviceId == UUID(1))
      #expect(fixture.state.value.mirror == fixture.state.value.connection?.deviceId)
      #expect(await identity.report() == .init())
      #expect(fixture.state.value.mirror == fixture.state.value.connection?.deviceId)
      #expect(fixture.state.value.migrationPending == false)
      #expect(fixture.state.value.apiCleared == false)
    }
  }

  @Test(arguments: [
    ReportIdentityTransition.Reason.normal, .supervisionCanonical, .childConflictPin,
  ])
  func sameDeviceOnlySwitchesIdentityWithAcknowledgedCredentials(
    reason: ReportIdentityTransition.Reason,
  ) async {
    let fixture = IdentityFixture(migrating: false)
    fixture.offline = false
    fixture.reason = reason
    let expected = reason == .normal ? UUID(4) : UUID(1)
    let identity = fixture.makeIdentity()
    _ = identity.resolve()
    #expect(fixture.state.value.mirror == UUID(1))
    #expect(await identity.report() == .init(identityChanged: reason == .normal))
    #expect(identity.resolver.deviceId == expected)
    #expect(fixture.state.value.mirror == expected)
    #expect(fixture.state.value.connection?.deviceId == expected)
    if reason == .childConflictPin {
      fixture.offline = true
      let restarted = fixture.makeIdentity()
      #expect(restarted.resolve() == .init(needsReport: true))
      #expect(await restarted.report() == .init())
      #expect(fixture.state.value.mirror == UUID(1))
      #expect(fixture.state.value.connection?.deviceId == UUID(1))
    }
  }

  @Test func siblingFirstMigrationClearsStateAndPersistsWalkthrough() async {
    let fixture = IdentityFixture(migrating: false)
    fixture.offline = false
    fixture.reason = .resolvedAsMigration
    let identity = fixture.makeIdentity()
    _ = identity.resolve()
    #expect(await identity.report() == .init(migrationPending: true, identityChanged: true))
    #expect(fixture.state.value.apiCleared)
    #expect(fixture.state.value.connection?.supervised == nil)
    #expect(fixture.makeIdentity().resolve() == .init(migrationPending: true))
  }

  @Test func unknownReadDoesNotPublishOrClearExistingMirror() {
    let fixture = IdentityFixture(migrating: false)
    fixture.unknownRead = true
    let identity = fixture.makeIdentity()
    #expect(identity.resolve() == .init(available: false))
    #expect(fixture.state.value.mirror == UUID(1))
    #expect(fixture.state.value.apiCleared == false)
  }

  @Test(arguments: [false, true])
  func unavailableIdentityStopsStartupUntilRetry(migrationPending: Bool) async {
    let resolution = BlockerIdentityClient.Resolution(
      available: false,
      migrationPending: migrationPending,
    )
    let store = TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.blockerIdentity.resolve = { resolution }
    }
    await store.send(.programmatic(.appDidLaunch))
    await store.receive(.programmatic(.identityResolved(resolution, launching: true))) {
      $0.screen = .identityUnavailable(migrationPending: migrationPending)
    }
    await store.send(.interactive(.onboardingBtnTapped(.primary, "Try again")))
    await store.receive(.programmatic(.identityResolved(resolution, launching: true)))
    await store.send(.programmatic(.identityReported(resolution, restart: true)))
  }

  @Test func migrationWalkthroughRemainsUntilFilterIsEnabled() async {
    await withDependencies {
      $0.systemExtension.filterRunning = { false }
      $0.sharedStorage.loadPendingSupervisionCode = { nil }
      $0.sharedStorage.migrationPending = { true }
    } operation: {
      let result = await IOSReducer.Deps().launchState()
      guard case .migratedHardware = result else {
        Issue.record("Expected migration walkthrough")
        return
      }
    }
  }

  @Test(arguments: [false, true])
  func migrationWithEnabledFilterResumesNormalLaunchAcrossRestarts(connected: Bool) async {
    let pending = LockIsolated(true)
    let connection = connected ? IdentityFixture.State().connection : nil
    await withDependencies {
      $0.systemExtension.filterRunning = { true }
      $0.sharedStorage.loadPendingSupervisionCode = { nil }
      $0.sharedStorage.migrationPending = { pending.value }
      $0.sharedStorage.setMigrationPending = { pending.setValue($0) }
      $0.sharedStorage.loadAccountConnection = { connection }
      $0.sharedStorage.loadDisabledBlockGroupIds = { [] }
    } operation: {
      for _ in 0 ..< 2 {
        switch await IOSReducer.Deps().launchState() {
        case .running(.connected(let received)):
          #expect(connected)
          #expect(received == connection)
        case .running(.unconnected):
          #expect(!connected)
        default:
          Issue.record("Expected normal launch after enabling the filter")
        }
        #expect(pending.value == false)
      }
    }
  }

  @Test(arguments: [false, true])
  func migrationResumesNewSupervisionCodeAcrossReboot(complete: Bool) async {
    let connection = IdentityFixture.State().connection!
    let cleared = LockIsolated(false)
    await withDependencies {
      $0.systemExtension.filterRunning = { complete }
      $0.sharedStorage.migrationPending = { true }
      $0.sharedStorage.setMigrationPending = { cleared.setValue(!$0) }
      $0.sharedStorage.loadPendingSupervisionCode = {
        .init(code: 654_321, expiresAt: .distantFuture)
      }
      $0.api.checkSupervisionFlowStatus = { code in
        #expect(code == 654_321)
        return complete ? .complete(connection) : .missingProfile(connection)
      }
    } operation: {
      switch await IOSReducer.Deps().launchState() {
      case .running(.connected(let received)):
        #expect(complete)
        #expect(received == connection)
      case .gertrudeSupervisionReboot(.supervisedButNeedsProfile(let received)):
        #expect(!complete)
        #expect(received == connection)
      default:
        Issue.record("Expected to resume the new device’s supervision")
      }
      #expect(cleared.value == complete)
    }
  }

  @Test func finishingSetupClearsDurableMigrationMarker() async {
    let pending = LockIsolated(true)
    let store = TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.happyPath(.requestAppStoreRating)),
    )) {
      IOSReducer()
    } withDependencies: {
      $0.sharedStorage.migrationPending = { pending.value }
      $0.sharedStorage.setMigrationPending = { pending.setValue($0) }
    }
    await store.send(.interactive(.onboardingBtnTapped(.tertiary, "Skip"))) {
      $0.screen = .onboarding(.happyPath(.doneQuit))
    }
    #expect(pending.value == false)
  }
}

@MainActor
private final class IdentityFixture {
  struct State {
    var connection: ChildIOSDeviceData_v2? = .init(
      childId: UUID(3), token: UUID(2), deviceId: UUID(1), childName: "Child",
      supervised: .byGertrude(claimCode: 123_456),
    )
    var mirror: UUID? = UUID(1)
    var migrationPending = false
    var apiCleared = false
  }

  let state = LockIsolated(State())
  var items: [IdentitySlot: Data]
  var offline = true
  var unknownRead = false
  var wroteBeforeCleanup = false
  var reports: [ReportIdentityTransition.Input] = []
  var reason = ReportIdentityTransition.Reason.normal
  let migrating: Bool

  init(migrating: Bool) {
    self.migrating = migrating
    self.items = [
      .identity: Data(UUID(migrating ? 1 : 4).uuidString.utf8),
      .appMemory: Data(UUID(1).uuidString.utf8),
    ]
    if !migrating { self.items[.canary] = Data(UUID(4).uuidString.utf8) }
  }

  func makeIdentity() -> BlockerIdentity {
    withDependencies {
      $0.uuid = .constant(UUID(4))
      $0.appEvent.record = { _ in }
      $0.device.deviceId = { nil }
      $0.api.clearAccountConnection = { [state] in state.withValue { $0.apiCleared = true } }
      $0.api.setAccountConnection = { _ in }
      $0.sharedStorage.loadAccountConnection = { [state] in state.value.connection }
      $0.sharedStorage.saveAccountConnection = { [state] conn in
        state.withValue { $0.connection = conn }
      }
      $0.sharedStorage.clearAccountConnection = { [state] in
        state.withValue { $0.connection = nil }
      }
      $0.sharedStorage.saveDeviceIdentity = { [state] id in state.withValue { $0.mirror = id } }
      $0.sharedStorage.migrationPending = { [state] in state.value.migrationPending }
      $0.sharedStorage.setMigrationPending = { [state] value in
        state.withValue { $0.migrationPending = value }
      }
      $0.sharedStorage.clearDeviceBoundState = { [state] in
        state.withValue { $0.connection = nil
          $0.migrationPending = true
        }
      }
    } operation: {
      BlockerIdentity(
        storage: .init(
          read: { slot in
            self.unknownRead ? .unknown(-25308) : self.items[slot]
              .map(IdentityRead.value) ?? .absent
          },
          add: { slot, data in self.items[slot] = data
            return .success
          },
          write: { slot, data in
            if self.migrating, self.state.value.connection != nil { self.wroteBeforeCleanup = true }
            self.items[slot] = data
            return .success
          },
          delete: { slot in self.items[slot] = nil
            return .success
          },
        ),
        metadata: { .init(
          app: .blocker, modelIdentifier: "iPhone16,1", iosVersion: "26.6.1",
          appVersion: "1.10.0", liveVendorId: UUID(6),
        ) },
        report: { input in
          self.reports.append(input)
          if self.offline { throw URLError(.notConnectedToInternet) }
          let id = self.reason == .supervisionCanonical || self.reason == .childConflictPin
            ? UUID(1) : UUID(4)
          return .init(deviceId: id, reason: self.reason, childId: UUID(3), token: UUID(5))
        },
        telemetry: { _ in },
      )
    }
  }
}
