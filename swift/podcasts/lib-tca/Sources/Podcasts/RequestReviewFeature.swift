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
          await self.storekit.requestRating()
          try? await self.clock.sleep(for: .seconds(5))
          await self.dismiss()
        }
      case .leaveReview:
        .run { _ in
          await self.storekit.requestReview()
          try? await self.clock.sleep(for: .seconds(5))
          await self.dismiss()
        }
      case .noThanks:
        .run { _ in
          await self.dismiss()
        }
      }
    }
  }
}
