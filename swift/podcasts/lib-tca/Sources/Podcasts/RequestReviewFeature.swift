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
          log(.info("71393f94"), "chose to leave rating")
          await self.storekit.requestRating()
          try? await self.clock.sleep(for: .seconds(5))
          await self.dismiss()
        }
      case .leaveReview:
        .run { _ in
          log(.info("b96de934"), "chose to leave review")
          await self.storekit.requestReview()
          try? await self.clock.sleep(for: .seconds(5))
          await self.dismiss()
        }
      case .noThanks:
        .run { _ in
          log(.info("ecef1f7f"), "dismissed review prompt")
          await self.dismiss()
        }
      }
    }
  }
}
