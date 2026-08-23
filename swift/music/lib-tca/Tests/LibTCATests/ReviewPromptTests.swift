import ComposableArchitecture
import CustomDump
import Foundation
import Testing

@testable import LibTCA

@MainActor
struct ReviewPromptTests {
  @Test
  func tenthIntentionalPlayPresentsPromptAfterDelay() async {
    let clock = TestClock()
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let progress = LockIsolated(ReviewPromptProgress(
      firstIntentionalPlayAt: now.addingTimeInterval(-AppFeature.reviewPromptMinimumAge),
      intentionalPlayCount: 9,
    ))
    var state = AppFeature.State()
    state.isAppActive = true
    state.setup.screen = .ready(childName: "Harriet")
    let store = TestStore(initialState: state) {
      AppFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date = .constant(now)
      $0.reviewPromptStorage = .init(
        load: { progress.value },
        save: { newProgress in progress.withValue { $0 = newProgress } },
      )
    }

    await store.send(.playback(.resumeFinished)) {
      $0.isReviewPromptPending = true
    }
    expectNoDifference(progress.value.intentionalPlayCount, 10)

    await clock.advance(by: AppFeature.reviewPromptDelay)
    await store.receive(.reviewPromptDelayFinished) {
      $0.isReviewPromptPending = false
      $0.reviewPrompt = .init()
    }
    #expect(progress.value.hasPrompted)
  }

  @Test
  func tenthIntentionalPlayBeforeMinimumAgeDoesNotPresentPrompt() async {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let progress = LockIsolated(ReviewPromptProgress(
      firstIntentionalPlayAt: now.addingTimeInterval(
        -AppFeature.reviewPromptMinimumAge + 1,
      ),
      intentionalPlayCount: 9,
    ))
    var state = AppFeature.State()
    state.isAppActive = true
    state.setup.screen = .ready(childName: "Harriet")
    let store = TestStore(initialState: state) {
      AppFeature()
    } withDependencies: {
      $0.date = .constant(now)
      $0.reviewPromptStorage = .init(
        load: { progress.value },
        save: { newProgress in progress.withValue { $0 = newProgress } },
      )
    }

    await store.send(.playback(.resumeFinished))

    expectNoDifference(progress.value.intentionalPlayCount, 10)
    #expect(!store.state.isReviewPromptPending)
    #expect(store.state.reviewPrompt == nil)
  }

  @Test
  func eligiblePromptWaitsForActiveApp() async {
    let clock = TestClock()
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let progress = LockIsolated(ReviewPromptProgress(
      firstIntentionalPlayAt: now.addingTimeInterval(-AppFeature.reviewPromptMinimumAge),
      intentionalPlayCount: 10,
    ))
    var state = AppFeature.State()
    state.setup.screen = .ready(childName: "Harriet")
    let store = TestStore(initialState: state) {
      AppFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date = .constant(now)
      $0.reviewPromptStorage = .init(
        load: { progress.value },
        save: { newProgress in progress.withValue { $0 = newProgress } },
      )
    }

    await store.send(.appEnteredForeground) {
      $0.isAppActive = true
      $0.isReviewPromptPending = true
    }

    await clock.advance(by: AppFeature.reviewPromptDelay)
    await store.receive(.reviewPromptDelayFinished) {
      $0.isReviewPromptPending = false
      $0.reviewPrompt = .init()
    }
  }

  @Test
  func promptProgressRequiresTenPlaysAndMinimumAge() {
    let firstPlayAt = Date(timeIntervalSince1970: 1_700_000_000)
    var progress = ReviewPromptProgress()

    for offset in 0 ..< 9 {
      progress.recordIntentionalPlay(at: firstPlayAt.addingTimeInterval(Double(offset)))
    }
    #expect(!progress.isEligible(
      at: firstPlayAt.addingTimeInterval(AppFeature.reviewPromptMinimumAge),
      minimumAge: AppFeature.reviewPromptMinimumAge,
    ))

    progress.recordIntentionalPlay(at: firstPlayAt.addingTimeInterval(9))
    #expect(!progress.isEligible(
      at: firstPlayAt.addingTimeInterval(AppFeature.reviewPromptMinimumAge - 1),
      minimumAge: AppFeature.reviewPromptMinimumAge,
    ))
    #expect(progress.isEligible(
      at: firstPlayAt.addingTimeInterval(AppFeature.reviewPromptMinimumAge),
      minimumAge: AppFeature.reviewPromptMinimumAge,
    ))
  }

  @Test
  func giveRatingRequestsSystemPromptThenDismisses() async {
    let clock = TestClock()
    let dismissed = LockIsolated(false)
    let requestCount = LockIsolated(0)
    let store = TestStore(initialState: ReviewPromptFeature.State()) {
      ReviewPromptFeature()
    } withDependencies: {
      $0.appStore.requestRating = { requestCount.withValue { $0 += 1 } }
      $0.continuousClock = clock
      $0.dismiss = DismissEffect { dismissed.setValue(true) }
    }

    await store.send(.giveRatingButtonTapped)
    await clock.advance(by: .seconds(5))
    await store.finish()

    expectNoDifference(requestCount.value, 1)
    #expect(dismissed.value)
  }

  @Test
  func noThanksDismissesPrompt() async {
    let dismissed = LockIsolated(false)
    let store = TestStore(initialState: ReviewPromptFeature.State()) {
      ReviewPromptFeature()
    } withDependencies: {
      $0.dismiss = DismissEffect { dismissed.setValue(true) }
    }

    await store.send(.noThanksButtonTapped)
    await store.finish()

    #expect(dismissed.value)
  }

  @Test
  func liveStoragePersistsProgress() {
    let suiteName = "gertrude.music.review-prompt-tests"
    let userDefaults = UserDefaults(suiteName: suiteName)!
    userDefaults.removePersistentDomain(forName: suiteName)
    defer { userDefaults.removePersistentDomain(forName: suiteName) }
    let progress = ReviewPromptProgress(
      firstIntentionalPlayAt: Date(timeIntervalSince1970: 1_700_000_000),
      hasPrompted: true,
      intentionalPlayCount: 10,
    )
    let storage = ReviewPromptStorageClient.live(userDefaults: userDefaults)

    storage.save(progress)

    expectNoDifference(
      ReviewPromptStorageClient.live(userDefaults: userDefaults).load(),
      progress,
    )
  }
}
