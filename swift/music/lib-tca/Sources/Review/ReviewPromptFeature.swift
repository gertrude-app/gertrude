import ComposableArchitecture

@Reducer
struct ReviewPromptFeature {
  @ObservableState
  struct State: Equatable {}

  enum Action: Equatable {
    case giveRatingButtonTapped
    case leaveReviewButtonTapped
    case noThanksButtonTapped
  }

  @Dependency(\.appStore) var appStore
  @Dependency(\.continuousClock) var clock
  @Dependency(\.dismiss) var dismiss

  var body: some ReducerOf<Self> {
    Reduce { _, action in
      switch action {
      case .giveRatingButtonTapped:
        .run { _ in
          await self.appStore.requestRating()
          try? await self.clock.sleep(for: .seconds(5))
          await self.dismiss()
        }

      case .leaveReviewButtonTapped:
        .run { _ in
          await self.appStore.requestReview()
          try? await self.clock.sleep(for: .seconds(5))
          await self.dismiss()
        }

      case .noThanksButtonTapped:
        .run { _ in
          await self.dismiss()
        }
      }
    }
  }
}
