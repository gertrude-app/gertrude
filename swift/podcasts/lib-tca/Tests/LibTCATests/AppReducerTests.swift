import Combine
import ComposableArchitecture
import Dependencies
import Foundation
import PodcastRoute
import SQLiteData
import Testing

@testable import LibTCA

@MainActor struct AppReducerTests {
  @Test func `reinstall with preserved db does not false onboard`() async {
    await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.getTrialStatus = { .legacyGrandfathered(paidAt: .reference, expiresAt: .reference) }
      $0.date = .constant(.reference)
      $0.locale = Locale(identifier: "en_US")
      $0.defaultDatabase = try! appDatabase {
        // vvv --- prior install's db survived (e.g. device restore)
        try Record.insert { [Record(id: .onboardingFinished)] }.execute($0)
      }
      $0.device.vendorId = { nil }
      $0.keychain._load = { _ in nil } // <- but keychain was wiped, no pincode
      $0.keychain._save = { _, _ in }
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
    } operation: {
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)

      await store.send(.appDidLaunch) {
        $0.mode = .onboarding(.init())
      }

      await store.send(.mode(.presented(.onboarding(.primaryBtnTapped)))) {
        // vvv --- advances normally, no crash
        $0.mode = .onboarding(.init(screen: .areYouTheParent))
      }

      await store.finish()
    }
  }

  @Test func `first launch sends 27c4f26a event after device id is established`() async {
    let loggedEventIds = LockIsolated<[String]>([])
    let keychainStore = LockIsolated<[String: Data]>([:])
    await withDependencies {
      $0.api.logEvent = { id, _, _, _ in loggedEventIds.withValue { $0.append(id) } }
      $0.api.getTrialStatus = { .legacyGrandfathered(paidAt: .reference, expiresAt: .reference) }
      $0.date = .constant(.reference)
      $0.locale = Locale(identifier: "en_US")
      $0.defaultDatabase = try! appDatabase()
      $0.device.vendorId = { UUID() }
      $0.keychain = dictKeychain(keychainStore)
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
    } operation: {
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)

      await store.send(.appDidLaunch) {
        $0.mode = .onboarding(.init())
      }

      await store.finish()

      #expect(keychainStore.value[KeychainClient.Key.deviceId.rawValue] != nil)
      await Task.yield()
      #expect(loggedEventIds.value.contains("27c4f26a"))
    }
  }

  @Test func `claimed device without a pincode resumes at the passcode step`() async {
    await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.getAccountStatus = {
        .init(childId: UUID(), childName: "Sally", subscription: .active(
          expiresAt: .reference + .days(300),
        ))
      }
      $0.date = .constant(.reference)
      $0.locale = Locale(identifier: "en_US")
      $0.defaultDatabase = try! appDatabase()
      $0.device.vendorId = { UUID() }
      $0.keychain = dictKeychain(
        LockIsolated([:]),
        installDate: .reference,
        deviceId: UUID(),
        amToken: UUID(),
      )
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
    } operation: {
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.appDidLaunch)
      #expect(store.state.mode == .onboarding(.init(
        screen: .explainSetPasscode,
        resumedAfterClaim: true,
      )))

      await store.finish()
    }
  }

  @Test func `pin set after a mid-claim relaunch logs the detection event`() async {
    let loggedEventIds = LockIsolated<[String]>([])
    await withDependencies {
      $0.api.logEvent = { id, _, _, _ in loggedEventIds.withValue { $0.append(id) } }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]), installDate: .reference, deviceId: UUID())
    } operation: {
      let store = TestStore(
        initialState: .init(mode: .onboarding(.init(
          screen: .explainSetPasscode,
          resumedAfterClaim: true,
        ))),
        reducer: AppReducer.init,
      )
      store.exhaustivity = .off

      await store.send(.mode(.presented(.onboarding(.finished(123_456)))))
      #expect(store.state.mode == .podcasts(.init()))

      await store.finish()
      await Task.yield()
      #expect(loggedEventIds.value.contains("ba182b20"))
      #expect(loggedEventIds.value.contains("c3e9a1f4"))
    }
  }

  @Test func `normal onboarding finish does not log the detection event`() async {
    let loggedEventIds = LockIsolated<[String]>([])
    await withDependencies {
      $0.api.logEvent = { id, _, _, _ in loggedEventIds.withValue { $0.append(id) } }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(LockIsolated([:]), installDate: .reference, deviceId: UUID())
    } operation: {
      let store = TestStore(
        initialState: .init(mode: .onboarding(.init(screen: .strongPasscode))),
        reducer: AppReducer.init,
      )
      store.exhaustivity = .off

      await store.send(.mode(.presented(.onboarding(.finished(123_456)))))
      await store.finish()
      await Task.yield()
      #expect(loggedEventIds.value.contains("ba182b20"))
      #expect(!loggedEventIds.value.contains("c3e9a1f4"))
    }
  }

  @Test func `foregrounding silently flips a skip user to active once claimed`() async {
    let keychainStore = LockIsolated<[String: Data]>([:])
    await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.api.getTrialStatus = {
        .claimed(
          token: UUID(),
          childId: UUID(),
          childName: "Sally",
          subscription: .active(expiresAt: .reference + .days(300)),
        )
      }
      $0.date = .constant(.reference)
      $0.defaultDatabase = try! appDatabase()
      $0.keychain = dictKeychain(
        keychainStore,
        pincode: 111_111, // ← has a PIN (went through PIN setup)
        installDate: .reference,
        deviceId: UUID(),
        // ← no amToken passed → NOT claimed (they skipped connecting an account)
      )
    } operation: {
      _ = try? CurrentSubscription.set(status: .trialing, expiringAt: .reference + .days(20))
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)
      store.exhaustivity = .off

      await store.send(.appInForegroundChanged(true))
      await store.finish()

      #expect(dep(\.db).subscription().status == .active)
      #expect(keychainStore.value[KeychainClient.Key.amToken.rawValue] != nil)
      #expect(store.state.alert == nil)
    }
  }
}
