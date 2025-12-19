import Combine
import Dependencies
import DependenciesMacros
import Foundation
import LibCore

@DependencyClient
struct NotificationsClient: Sendable {
  var appForegroundingEvents: @Sendable () -> AnyPublisher<Bool, Never> = {
    Empty().eraseToAnyPublisher()
  }
}

extension NotificationsClient: DependencyKey {
  static var liveValue: NotificationsClient {
    NotificationsClient(
      appForegroundingEvents: {
        NotificationCenter.default
          .publisher(for: UIApplication.willResignActiveNotification)
          .map { _ in false }
          .merge(
            with: NotificationCenter.default
              .publisher(for: UIApplication.didBecomeActiveNotification)
              .map { _ in true },
          )
          .eraseToAnyPublisher()
      },
    )
  }
}

extension DependencyValues {
  var notificationCenter: NotificationsClient {
    get { self[NotificationsClient.self] }
    set { self[NotificationsClient.self] = newValue }
  }
}
