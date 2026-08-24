import ComposableArchitecture
import GertieTcaFeatures
import Testing

@MainActor
struct AppStoreReviewFeatureTests {
  @Test
  func giveRatingRequestsSystemPromptThenDismisses() async {
    let clock = TestClock()
    let dismissed = LockIsolated(false)
    let requestCount = LockIsolated(0)
    let store = TestStore(
      initialState: AppStoreReviewFeature.State(appStoreID: "app-id"),
    ) {
      AppStoreReviewFeature()
    } withDependencies: {
      $0.appStore.requestRating = { requestCount.withValue { $0 += 1 } }
      $0.continuousClock = clock
      $0.dismiss = DismissEffect { dismissed.setValue(true) }
    }

    await store.send(.giveRatingButtonTapped)
    await clock.advance(by: .seconds(5))
    await store.finish()

    #expect(requestCount.value == 1)
    #expect(dismissed.value)
  }

  @Test
  func leaveReviewOpensAppReviewPageThenDismisses() async {
    let clock = TestClock()
    let dismissed = LockIsolated(false)
    let requestedAppStoreID = LockIsolated<String?>(nil)
    let store = TestStore(
      initialState: AppStoreReviewFeature.State(appStoreID: "app-id"),
    ) {
      AppStoreReviewFeature()
    } withDependencies: {
      $0.appStore.requestReview = { requestedAppStoreID.setValue($0) }
      $0.continuousClock = clock
      $0.dismiss = DismissEffect { dismissed.setValue(true) }
    }

    await store.send(.leaveReviewButtonTapped)
    await clock.advance(by: .seconds(5))
    await store.finish()

    #expect(requestedAppStoreID.value == "app-id")
    #expect(dismissed.value)
  }

  @Test
  func noThanksDismissesPrompt() async {
    let dismissed = LockIsolated(false)
    let store = TestStore(
      initialState: AppStoreReviewFeature.State(appStoreID: "app-id"),
    ) {
      AppStoreReviewFeature()
    } withDependencies: {
      $0.dismiss = DismissEffect { dismissed.setValue(true) }
    }

    await store.send(.noThanksButtonTapped)
    await store.finish()

    #expect(dismissed.value)
  }
}
