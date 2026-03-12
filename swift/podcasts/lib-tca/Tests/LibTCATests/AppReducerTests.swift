import Combine
import ComposableArchitecture
import Dependencies
import Foundation
import SQLiteData
import Testing

@testable import LibTCA

@MainActor struct AppReducerTests {
  @Test func `reinstall with preserved db does not false onboard`() async {
    let transactions = AsyncStream<TransactionData>.makeStream()
    await withDependencies {
      $0.api.logEvent = { _, _, _, _ in }
      $0.date = .constant(.reference)
      $0.locale = Locale(identifier: "en_US")
      $0.defaultDatabase = try! appDatabase {
        // vvv --- prior install's db survived (e.g. device restore)
        try Record.insert { [Record(id: .onboardingFinished)] }.execute($0)
      }
      $0.keychain._load = { _ in nil } // <- but keychain was wiped, no pincode
      $0.keychain._save = { _, _ in }
      $0.audio.systemEvents = { Empty().eraseToAnyPublisher() }
      $0.notificationCenter.appForegroundingEvents = { Empty().eraseToAnyPublisher() }
      $0.mainQueue = .immediate
      $0.storekit.verifiedCurrentEntitlements = { [] }
      $0.storekit.transactionUpdates = { transactions.stream }
    } operation: {
      let store = TestStore(initialState: .init(), reducer: AppReducer.init)

      await store.send(.appDidLaunch) {
        $0.mode = .onboarding(.init())
      }

      await store.send(.mode(.presented(.onboarding(.primaryBtnTapped)))) {
        // vvv --- advances normally, no crash
        $0.mode = .onboarding(.init(screen: .areYouTheParent))
      }

      transactions.continuation.finish()
      await store.finish()
    }
  }
}
