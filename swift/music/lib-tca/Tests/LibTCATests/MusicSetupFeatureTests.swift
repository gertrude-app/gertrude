import ComposableArchitecture
import Foundation
import MusicRoute
import Testing

@testable import LibTCA

@MainActor
struct MusicSetupFeatureTests {
  @Test
  func onAppearShowsWelcomeWhenAppleMusicPermissionHasNotBeenRequested() async {
    let store = TestStore(initialState: .init()) {
      MusicSetupFeature()
    } withDependencies: {
      $0.musicSetup.authorizationStatus = { .notDetermined }
    }

    await store.send(.onAppear)
    await store.receive(.appleMusicAuthorizationStatusLoaded(
      .notDetermined,
      showWelcomeIfNeeded: true,
    )) {
      $0.screen = .welcome
    }
  }

  @Test
  func getStartedShowsAppleMusicPermissionScreen() async {
    var state = MusicSetupFeature.State()
    state.screen = .welcome
    let store = TestStore(initialState: state) {
      MusicSetupFeature()
    }

    await store.send(.getStartedButtonTapped) {
      $0.screen = .appleMusicPermission
    }
  }

  @Test
  func authorizedSubscribedAndClaimedCompletesSetup() async {
    let token = UUID(1)
    let childId = UUID(2)
    let store = TestStore(initialState: .init()) {
      MusicSetupFeature()
    } withDependencies: {
      $0.api.getMusicAppStatus = {
        .claimed(
          token: token,
          childId: childId,
          childName: "Harriet",
        )
      }
      $0.keychain._load = { _ in nil }
      $0.keychain._save = { _, _ in }
      $0.keychain.delete = { _ in }
      $0.musicSetup.authorizationStatus = { .authorized }
      $0.musicSetup.subscriptionStatus = { .canPlayCatalogContent }
    }

    await store.send(.onAppear)
    await store.receive(.appleMusicAuthorizationStatusLoaded(
      .authorized,
      showWelcomeIfNeeded: true,
    ))
    await store.receive(.appleMusicSubscriptionStatusLoaded(.canPlayCatalogContent)) {
      $0.screen = .gertrudeConnection(.checking)
    }
    await store.receive(.musicAppStatusLoaded(.claimed(
      token: token,
      childId: childId,
      childName: "Harriet",
    ))) {
      $0.screen = .ready(childName: "Harriet")
    }
    await store.receive(.delegate(.completed(childName: "Harriet")))
  }

  @Test
  func subscriptionRequiredCanPresentAppleMusicOffer() async {
    let store = TestStore(initialState: .init()) {
      MusicSetupFeature()
    } withDependencies: {
      $0.musicSetup.subscriptionStatus = {
        .subscriptionRequired(canBecomeSubscriber: true)
      }
    }

    await store.send(.appleMusicAuthorizationStatusLoaded(.authorized, showWelcomeIfNeeded: false))
    await store.receive(.appleMusicSubscriptionStatusLoaded(.subscriptionRequired(
      canBecomeSubscriber: true,
    ))) {
      $0.screen = .appleMusicSubscriptionRequired(canShowOffer: true)
    }
  }

  @Test
  func dismissingSubscriptionOfferRechecksAppleMusicAndGertrudeConnection() async {
    let token = UUID(1)
    let childId = UUID(2)
    var state = MusicSetupFeature.State()
    state.isSubscriptionOfferPresented = true
    state.screen = .appleMusicSubscriptionRequired(canShowOffer: true)
    let store = TestStore(initialState: state) {
      MusicSetupFeature()
    } withDependencies: {
      $0.api.getMusicAppStatus = {
        .claimed(
          token: token,
          childId: childId,
          childName: "Harriet",
        )
      }
      $0.keychain._load = { _ in nil }
      $0.keychain._save = { _, _ in }
      $0.keychain.delete = { _ in }
      $0.musicSetup.subscriptionStatus = { .canPlayCatalogContent }
    }

    await store.send(.appleMusicSubscriptionOfferPresentationChanged(false)) {
      $0.isSubscriptionOfferPresented = false
      $0.screen = .checking
    }
    await store.receive(.appleMusicSubscriptionStatusLoaded(.canPlayCatalogContent)) {
      $0.screen = .gertrudeConnection(.checking)
    }
    await store.receive(.musicAppStatusLoaded(.claimed(
      token: token,
      childId: childId,
      childName: "Harriet",
    ))) {
      $0.screen = .ready(childName: "Harriet")
    }
    await store.receive(.delegate(.completed(childName: "Harriet")))
  }

  @Test
  func unclaimedConnectionPollsUntilClaimed() async {
    let clock = TestClock()
    let expiresAt = Date(timeIntervalSince1970: 123)
    let token = UUID(1)
    let childId = UUID(2)
    let statusProvider = MusicAppStatusProvider(outputs: [
      .unclaimed(code: 123_456, expiresAt: expiresAt),
      .claimed(token: token, childId: childId, childName: "Harriet"),
    ])
    let store = TestStore(initialState: .init()) {
      MusicSetupFeature()
    } withDependencies: {
      $0.api.getMusicAppStatus = { try await statusProvider.next() }
      $0.continuousClock = clock
      $0.keychain._load = { _ in nil }
      $0.keychain._save = { _, _ in }
      $0.keychain.delete = { _ in }
    }

    await store.send(.appleMusicSubscriptionStatusLoaded(.canPlayCatalogContent)) {
      $0.screen = .gertrudeConnection(.checking)
    }
    await store.receive(.musicAppStatusLoaded(.unclaimed(
      code: 123_456,
      expiresAt: expiresAt,
    ))) {
      $0.screen = .gertrudeConnection(.unclaimed(code: 123_456, expiresAt: expiresAt))
    }
    await clock.advance(by: .seconds(5))
    await store.receive(.musicAppStatusLoaded(.claimed(
      token: token,
      childId: childId,
      childName: "Harriet",
    ))) {
      $0.screen = .ready(childName: "Harriet")
    }
    await store.receive(.delegate(.completed(childName: "Harriet")))
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

private actor MusicAppStatusProvider {
  var outputs: [GetMusicAppStatus.Output]

  init(outputs: [GetMusicAppStatus.Output]) {
    self.outputs = outputs
  }

  func next() throws -> GetMusicAppStatus.Output {
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
