import Dependencies
import DependenciesMacros
import Foundation

#if os(iOS)
  import StoreKit
  import UIKit
#endif

@DependencyClient
public struct AppStoreClient: Sendable {
  public var requestRating: @Sendable () async -> Void
  public var requestReview: @Sendable (_ appStoreID: String) async -> Void
}

extension AppStoreClient: TestDependencyKey {
  public static var testValue: Self { .init() }
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
