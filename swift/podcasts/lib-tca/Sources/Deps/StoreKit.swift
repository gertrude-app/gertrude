import Dependencies
import DependenciesMacros
import Foundation
import LibCore
import StoreKit

@DependencyClient
struct StoreKitClient: Sendable {
  var requestRating: @Sendable () async -> Void
  var requestReview: @Sendable () async -> Void
}

extension StoreKitClient: DependencyKey {
  static var liveValue: StoreKitClient {
    .init(
      requestRating: {
        if let scene = await UIApplication.shared.connectedScenes.first as? UIWindowScene {
          #if os(iOS)
            await SKStoreReviewController.requestReview(in: scene)
          #endif
        }
      },
      requestReview: {
        let url = "https://apps.apple.com/app/id6753187429?action=write-review"
        if let writeReviewURL = URL(string: url) {
          Task { @MainActor in
            await UIApplication.shared.open(writeReviewURL)
          }
        }
      },
    )
  }
}

extension DependencyValues {
  var storekit: StoreKitClient {
    get { self[StoreKitClient.self] }
    set { self[StoreKitClient.self] = newValue }
  }
}
