import ComposableArchitecture
import Foundation
import LibViews
import MusicRoute
import Testing

@testable import LibTCA

@MainActor
struct MusicSetupFeatureTests {
  @Test
  func newUserOnAppearShowsWelcomeAndPrefetchesStatus() async {
    let store = TestStore(initialState: .init()) {
      MusicSetupFeature()
    } withDependencies: {
      $0.keychain = KeychainStore().client
      $0.api.getMusicAppStatus = { .unclaimed(code: 123_456, expiresAt: .distantFuture) }
    }

    await store.send(.onAppear) {
      $0.screen = .welcome
    }
    await store.receive(.prefetchStatusLoaded(.unclaimed(
      code: 123_456,
      expiresAt: .distantFuture,
    ))) {
      $0.prefetch = .loaded(.unclaimed(code: 123_456, expiresAt: .distantFuture))
    }
  }

  @Test
  func getStartedWithUnclaimedStatusShowsParentQuestion() async {
    var state = MusicSetupFeature.State()
    state.screen = .welcome
    state.prefetch = .loaded(.unclaimed(code: 123_456, expiresAt: .distantFuture))
    let store = TestStore(initialState: state) {
      MusicSetupFeature()
    }

    await store.send(.getStartedButtonTapped) {
      $0.screen = .parentQuestion
    }
  }

  @Test
  func parentNoShowsNudgeThenProceedsAsSelfManagement() async {
    var state = MusicSetupFeature.State()
    state.screen = .parentQuestion
    let store = TestStore(initialState: state) {
      MusicSetupFeature()
    }

    await store.send(.parentNoButtonTapped) {
      $0.screen = .selfManagerNudge
    }
    await store.send(.nudgeContinueButtonTapped) {
      $0.claimAudience = .selfManagement
      $0.screen = .explainAccount
    }
  }

  @Test
  func claimFlowPollsToRecognizedThenAppleMusicThenReady() async {
    let clock = TestClock()
    let token = UUID(1)
    let childId = UUID(2)
    let provider = MusicAppStatusProvider(outputs: [
      .unclaimed(code: 123_456, expiresAt: .distantFuture), // explainAccount fetch
      .claimed(token: token, childId: childId, childName: "Harriet", entitlement: .active),
    ])
    var state = MusicSetupFeature.State()
    state.screen = .explainAccount
    state.claimAudience = .parentPartner
    let store = TestStore(initialState: state) {
      MusicSetupFeature()
    } withDependencies: {
      $0.keychain = KeychainStore().client
      $0.continuousClock = clock
      $0.api.getMusicAppStatus = { try await provider.next() }
      $0.musicSetup.authorizationStatus = { .authorized }
      $0.musicSetup.subscriptionStatus = { .canPlayCatalogContent }
    }

    await store.send(.explainAccountContinueButtonTapped) {
      $0.screen = .gertrudeConnection(.checking)
    }
    await store.receive(.musicAppStatusLoaded(.unclaimed(
      code: 123_456,
      expiresAt: .distantFuture,
    ))) {
      $0.screen = .gertrudeConnection(.unclaimed(code: 123_456, expiresAt: .distantFuture))
    }
    await clock.advance(by: .seconds(5)) // poll finds the completed claim
    await store.receive(.musicAppStatusLoaded(.claimed(
      token: token,
      childId: childId,
      childName: "Harriet",
      entitlement: .active,
    ))) {
      $0.screen = .deviceRecognized(childName: "Harriet")
    }
    await store.send(.deviceRecognizedContinueButtonTapped) // stays on deviceRecognized, no splash
    await store.receive(.appleMusicAuthorizationStatusLoaded(.authorized))
    await store.receive(.appleMusicSubscriptionStatusLoaded(.canPlayCatalogContent)) {
      $0.screen = .ready(childName: "Harriet")
    }
    await store.receive(.delegate(.completed(childName: "Harriet")))
  }

  @Test
  func deviceRecognizedContinueGoesStraightToPermissionWithoutSplash() async {
    var state = MusicSetupFeature.State()
    state.screen = .deviceRecognized(childName: "Harriet")
    let store = TestStore(initialState: state) {
      MusicSetupFeature()
    } withDependencies: {
      $0.musicSetup.authorizationStatus = { .notDetermined }
    }

    await store.send(.deviceRecognizedContinueButtonTapped) // no .checking splash in between
    await store.receive(.appleMusicAuthorizationStatusLoaded(.notDetermined)) {
      $0.screen = .appleMusicPermission
    }
  }

  @Test
  func recognizedEntitledDeviceSkipsQuestion() async {
    let token = UUID(1)
    let childId = UUID(2)
    var state = MusicSetupFeature.State()
    state.screen = .welcome
    state.prefetch = .loaded(.claimed(
      token: token,
      childId: childId,
      childName: "Harriet",
      entitlement: .active,
    ))
    let store = TestStore(initialState: state) {
      MusicSetupFeature()
    } withDependencies: {
      $0.keychain = KeychainStore().client
    }

    await store.send(.getStartedButtonTapped) {
      $0.screen = .deviceRecognized(childName: "Harriet")
    }
  }

  @Test
  func recognizedDeviceWithoutMusicAccessShowsUnavailableThenResolves() async {
    let clock = TestClock()
    let token = UUID(1)
    let childId = UUID(2)
    let provider = MusicAppStatusProvider(outputs: [
      .claimed(token: token, childId: childId, childName: "Harriet", entitlement: .active),
    ])
    var state = MusicSetupFeature.State()
    state.screen = .welcome
    state.prefetch = .loaded(.claimed(
      token: token,
      childId: childId,
      childName: "Harriet",
      entitlement: .unavailable,
    ))
    let store = TestStore(initialState: state) {
      MusicSetupFeature()
    } withDependencies: {
      $0.keychain = KeychainStore().client
      $0.continuousClock = clock
      $0.api.getMusicAppStatus = { try await provider.next() }
    }

    await store.send(.getStartedButtonTapped) {
      $0.screen = .musicAccessUnavailable(childName: "Harriet")
    }
    await clock.advance(by: .seconds(5)) // poll finds the account became eligible
    await store.receive(.musicAppStatusLoaded(.claimed(
      token: token,
      childId: childId,
      childName: "Harriet",
      entitlement: .active,
    ))) {
      $0.screen = .deviceRecognized(childName: "Harriet")
    }
  }

  @Test
  func claimWithoutMusicAccessSavesConnectionAndStaysUnavailable() async {
    let keychain = KeychainStore()
    let token = UUID(1)
    let childId = UUID(2)
    var state = MusicSetupFeature.State()
    state.screen = .welcome
    state.prefetch = .loaded(.claimed(
      token: token,
      childId: childId,
      childName: "Harriet",
      entitlement: .unavailable,
    ))
    let store = TestStore(initialState: state) {
      MusicSetupFeature()
    } withDependencies: {
      $0.keychain = keychain.client
      $0.continuousClock = TestClock()
    }

    await store.send(.getStartedButtonTapped) {
      $0.screen = .musicAccessUnavailable(childName: "Harriet")
    }

    #expect(keychain.connectionSaveCount == 1) // connection persists despite no entitlement
    await store.skipInFlightEffects() // polling keeps running so activation can recover
  }

  @Test
  func musicAccessUnavailablePollingDoesNotResaveConnection() async {
    let keychain = KeychainStore()
    let token = UUID(1)
    let childId = UUID(2)
    var state = MusicSetupFeature.State()
    state.screen = .musicAccessUnavailable(childName: "Harriet") // already polling
    let store = TestStore(initialState: state) {
      MusicSetupFeature()
    } withDependencies: {
      $0.keychain = keychain.client
    }

    let unavailableTick = MusicSetupFeature.Action.musicAppStatusLoaded(.claimed(
      token: token,
      childId: childId,
      childName: "Harriet",
      entitlement: .unavailable,
    ))
    await store.send(unavailableTick) // poll tick, still unavailable: no screen change
    await store.send(unavailableTick) // another tick: still no screen change

    #expect(keychain.connectionSaveCount == 0) // already on screen -> must not re-save each tick
  }

  @Test
  func returningUserSkipsOnboardingToAppleMusic() async {
    let logged = LockIsolated<[String]>([])
    let keychain = KeychainStore()
    keychain.client.save(connection: .init(token: UUID(1), childId: UUID(2), childName: "Harriet"))
    let store = TestStore(initialState: .init()) {
      MusicSetupFeature()
    } withDependencies: {
      $0.appEvent.record = { event in logged.withValue { $0.append(event.eventId) } }
      $0.keychain = keychain.client
      $0.musicSetup.authorizationStatus = { .authorized }
      $0.musicSetup.subscriptionStatus = { .canPlayCatalogContent }
    }

    await store.send(.onAppear) { // stays on .checking: no welcome, no prefetch
      $0.resumedStoredConnection = true
    }
    #expect(logged.value == ["9cfe15f7"]) // logged at launch, not at ready
    await store.receive(.appleMusicAuthorizationStatusLoaded(.authorized))
    await store.receive(.appleMusicSubscriptionStatusLoaded(.canPlayCatalogContent)) {
      $0.screen = .ready(childName: "Harriet")
    }
    await store.receive(.delegate(.completed(childName: "Harriet")))

    #expect(logged.value == ["9cfe15f7"]) // a relaunch, NOT an onboarding completion
  }

  @Test
  func firstTimeSetupCompletionLogsOnboardingComplete() async {
    let logged = LockIsolated<[String]>([])
    let keychain = KeychainStore()
    var state = MusicSetupFeature.State()
    state.screen = .welcome
    state.prefetch = .loaded(.claimed(
      token: UUID(1),
      childId: UUID(2),
      childName: "Harriet",
      entitlement: .active,
    ))
    let store = TestStore(initialState: state) {
      MusicSetupFeature()
    } withDependencies: {
      $0.appEvent.record = { event in logged.withValue { $0.append(event.eventId) } }
      $0.keychain = keychain.client
      $0.musicSetup.authorizationStatus = { .authorized }
      $0.musicSetup.subscriptionStatus = { .canPlayCatalogContent }
    }

    await store.send(.getStartedButtonTapped) {
      $0.screen = .deviceRecognized(childName: "Harriet")
    }
    await store.send(.deviceRecognizedContinueButtonTapped)
    await store.receive(.appleMusicAuthorizationStatusLoaded(.authorized))
    await store.receive(.appleMusicSubscriptionStatusLoaded(.canPlayCatalogContent)) {
      $0.screen = .ready(childName: "Harriet")
    }
    await store.receive(.delegate(.completed(childName: "Harriet")))

    #expect(logged.value.contains("8af8b414"))
    #expect(!logged.value.contains("9cfe15f7"))
  }

  @Test
  func getStartedWhilePrefetchLoadingWaitsThenForks() async {
    var state = MusicSetupFeature.State()
    state.screen = .welcome
    state.prefetch = .loading
    let store = TestStore(initialState: state) {
      MusicSetupFeature()
    }

    await store.send(.getStartedButtonTapped) {
      $0.screen = .connecting
    }
    await store.send(.prefetchStatusLoaded(.unclaimed(code: 123_456, expiresAt: .distantFuture))) {
      $0.prefetch = .loaded(.unclaimed(code: 123_456, expiresAt: .distantFuture))
      $0.screen = .parentQuestion
    }
  }

  @Test
  func settingsButtonOpensAppSettings() async {
    let recorder = SettingsRecorder()
    let store = TestStore(initialState: .init()) {
      MusicSetupFeature()
    } withDependencies: {
      $0.systemSettings.openAppSettings = {
        await recorder.recordOpenSettings()
      }
    }

    await store.send(.settingsButtonTapped)
    #expect(await recorder.openSettingsCount == 1)
  }
}

private final class KeychainStore: @unchecked Sendable {
  private let lock = NSLock()
  private var storage: [KeychainClient.Key: Data] = [:]
  private var connectionSaves = 0

  var connectionSaveCount: Int { self.lock.withLock { self.connectionSaves } }

  var client: KeychainClient {
    KeychainClient(
      _load: { key in self.lock.withLock { self.storage[key] } },
      _save: { key, data in self.lock.withLock {
        self.storage[key] = data
        if key == .connection { self.connectionSaves += 1 } // count connection re-saves
      } },
      delete: { key in self.lock.withLock { _ = self.storage.removeValue(forKey: key) } },
    )
  }
}

private actor MusicAppStatusProvider {
  var outputs: [GetMusicAppStatus_v2.Output]

  init(outputs: [GetMusicAppStatus_v2.Output]) {
    self.outputs = outputs
  }

  func next() throws -> GetMusicAppStatus_v2.Output {
    guard !self.outputs.isEmpty else { throw TestError() }
    return self.outputs.removeFirst()
  }
}

private actor SettingsRecorder {
  var openSettingsCount = 0

  func recordOpenSettings() {
    self.openSettingsCount += 1
  }
}
