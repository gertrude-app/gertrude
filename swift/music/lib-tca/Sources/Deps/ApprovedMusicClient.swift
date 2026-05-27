import Dependencies
import DependenciesMacros

@DependencyClient
struct ApprovedMusicClient: Sendable {
  var loadApprovedLibrary: @Sendable () async throws -> ApprovedMusicLibrary
}

extension ApprovedMusicClient: DependencyKey {
  static let liveValue = Self.mock
}

extension DependencyValues {
  var approvedMusic: ApprovedMusicClient {
    get { self[ApprovedMusicClient.self] }
    set { self[ApprovedMusicClient.self] = newValue }
  }
}

extension ApprovedMusicClient {
  static let mock = Self(
    loadApprovedLibrary: { .mock },
  )

  static let empty = Self(
    loadApprovedLibrary: { .empty },
  )
}
