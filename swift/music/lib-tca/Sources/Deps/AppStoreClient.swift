import Dependencies
import DependenciesMacros
import Foundation
import StoreKit

#if os(iOS)
  import UIKit
#endif

@DependencyClient
struct AppStoreClient: Sendable {
  var requestRating: @Sendable () async -> Void
  var requestReview: @Sendable () async -> Void
}

extension AppStoreClient: DependencyKey {
  static var liveValue: Self {
    Self(
      requestRating: {
        #if os(iOS)
          if let scene = await UIApplication.shared.connectedScenes.first as? UIWindowScene {
            await SKStoreReviewController.requestReview(in: scene)
          }
        #endif
      },
      requestReview: {
        #if os(iOS)
          guard let url = URL(
            string: "https://apps.apple.com/app/id6782194077?action=write-review",
          ) else { return }
          await MainActor.run {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
          }
        #endif
      },
    )
  }

  static let testValue = Self(
    requestRating: {},
    requestReview: {},
  )
}

extension DependencyValues {
  var appStore: AppStoreClient {
    get { self[AppStoreClient.self] }
    set { self[AppStoreClient.self] = newValue }
  }
}
