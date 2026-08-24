import Dependencies
import Foundation

#if os(iOS)
  import StoreKit
  import UIKit
#endif

public struct AppStoreClient: Sendable {
  public var requestRating: @Sendable () async -> Void
  public var requestReview: @Sendable (_ appStoreID: String) async -> Void

  public init(
    requestRating: @escaping @Sendable () async -> Void,
    requestReview: @escaping @Sendable (_ appStoreID: String) async -> Void,
  ) {
    self.requestRating = requestRating
    self.requestReview = requestReview
  }
}

extension AppStoreClient: TestDependencyKey {
  public static var testValue: Self {
    .init(
      requestRating: {},
      requestReview: { _ in },
    )
  }
}

extension AppStoreClient: DependencyKey {
  public static var liveValue: Self {
    .init(
      requestRating: {
        #if os(iOS)
          guard let scene = await UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
          else { return }
          await SKStoreReviewController.requestReview(in: scene)
        #endif
      },
      requestReview: { appStoreID in
        #if os(iOS)
          guard let url = URL(
            string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review",
          ) else { return }
          await MainActor.run {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
          }
        #endif
      },
    )
  }
}

public extension DependencyValues {
  var appStore: AppStoreClient {
    get { self[AppStoreClient.self] }
    set { self[AppStoreClient.self] = newValue }
  }
}
