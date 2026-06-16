import Dependencies
import DependenciesMacros
import Foundation

#if os(iOS)
  import UIKit
#endif

@DependencyClient
struct SystemSettingsClient: Sendable {
  var openAppSettings: @Sendable () async -> Void = {}
}

extension SystemSettingsClient: DependencyKey {
  static var liveValue: Self {
    Self(
      openAppSettings: {
        #if os(iOS)
          guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
          await MainActor.run {
            UIApplication.shared.open(url)
          }
        #endif
      },
    )
  }

  static var testValue: Self { Self() }
}

extension DependencyValues {
  var systemSettings: SystemSettingsClient {
    get { self[SystemSettingsClient.self] }
    set { self[SystemSettingsClient.self] = newValue }
  }
}
