import ComposableArchitecture
import LibViews
import SwiftUI

@Reducer
struct RequestReviewFeature {
  @ObservableState
  struct State: Equatable {}

  enum Action: Equatable {
    case leaveReview
    case leaveRating
    case noThanks
  }

  @Dependency(\.storekit) var storekit
  @Dependency(\.dismiss) var dismiss
  @Dependency(\.continuousClock) var clock

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .leaveRating:
        .run { _ in
          log(.info, .review, "71393f94")
          await self.storekit.requestRating()
          try? await self.clock.sleep(for: .seconds(5))
          await self.dismiss()
        }
      case .leaveReview:
        .run { _ in
          log(.info, .review, "b96de934")
          await self.storekit.requestReview()
          try? await self.clock.sleep(for: .seconds(5))
          await self.dismiss()
        }
      case .noThanks:
        .run { _ in
          log(.info, .review, "ecef1f7f")
          await self.dismiss()
        }
      }
    }
  }
}
