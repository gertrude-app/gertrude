import ClientInterfaces
import Dependencies
import Foundation

public struct UpdaterClient: Sendable {
  public var triggerUpdate: @Sendable (String) async throws -> Void

  public init(triggerUpdate: @escaping @Sendable (String) async throws -> Void) {
    self.triggerUpdate = triggerUpdate
  }
}

extension UpdaterClient: TestDependencyKey {
  public static let testValue = Self(
    triggerUpdate: unimplemented("UpdaterClient.triggerUpdate"),
  )
  public static let mock = Self(
    triggerUpdate: { _ in },
  )
}

public extension DependencyValues {
  var updater: UpdaterClient {
    get { self[UpdaterClient.self] }
    set { self[UpdaterClient.self] = newValue }
  }
}

extension UpdaterClient: EndpointOverridable {
  public static let endpointDefault = AppConfiguration.appcastURL

  public static let endpointOverride = LockIsolated<URL?>(nil)
}
