import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct AppleMusicClient: Sendable {
  var requestAuthorization: @Sendable () async throws -> Bool
  var playTestSong: @Sendable () async throws -> Void
}

extension AppleMusicClient: DependencyKey {
  static let liveValue = AppleMusicClient.mockAuthorized
}

extension DependencyValues {
  var appleMusic: AppleMusicClient {
    get { self[AppleMusicClient.self] }
    set { self[AppleMusicClient.self] = newValue }
  }
}

extension AppleMusicClient {
  static let mockAuthorized = Self(
    requestAuthorization: { true },
    playTestSong: {},
  )

  static let mockDenied = Self(
    requestAuthorization: { false },
    playTestSong: {},
  )
}
