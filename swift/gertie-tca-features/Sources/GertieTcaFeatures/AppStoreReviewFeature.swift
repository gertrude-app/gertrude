import ComposableArchitecture

@Reducer
public struct AppStoreReviewFeature: Sendable {
  @ObservableState
  public struct State: Equatable {
    public let appStoreID: String

    public init(appStoreID: String) {
      self.appStoreID = appStoreID
    }
  }

  public enum Action: Equatable {
    case giveRatingButtonTapped
    case leaveReviewButtonTapped
    case noThanksButtonTapped
  }

  @Dependency(\.appStore) var appStore
  @Dependency(\.continuousClock) var clock
  @Dependency(\.dismiss) var dismiss

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .giveRatingButtonTapped:
        return .run { _ in
          await self.appStore.requestRating()
          try? await self.clock.sleep(for: .seconds(5))
          await self.dismiss()
        }

      case .leaveReviewButtonTapped:
        let appStoreID = state.appStoreID
        return .run { _ in
          await self.appStore.requestReview(appStoreID)
          try? await self.clock.sleep(for: .seconds(5))
          await self.dismiss()
        }

      case .noThanksButtonTapped:
        return .run { _ in
          await self.dismiss()
        }
      }
    }
  }
}
