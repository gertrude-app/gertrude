import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct ApprovedMusicLibraryCacheClient: Sendable {
  var _load: @Sendable (_ childId: UUID) async throws -> ApprovedMusicLibrary?
  var _save: @Sendable (_ library: ApprovedMusicLibrary, _ childId: UUID) async throws -> Void
  var _delete: @Sendable (_ childId: UUID) async -> Void
}

extension ApprovedMusicLibraryCacheClient {
  func load(childId: UUID) async throws -> ApprovedMusicLibrary? {
    try await self._load(childId)
  }

  func save(_ library: ApprovedMusicLibrary, childId: UUID) async throws {
    try await self._save(library, childId)
  }

  func delete(childId: UUID) async {
    await self._delete(childId)
  }
}

extension ApprovedMusicLibraryCacheClient: DependencyKey {
  static var liveValue: Self {
    .live(directory: ChildScopedDiskJSONCache<ApprovedMusicLibrary>.directory(
      named: "ApprovedMusicLibraryCache",
    ))
  }

  static let testValue = Self.noop
}

extension DependencyValues {
  var approvedMusicLibraryCache: ApprovedMusicLibraryCacheClient {
    get { self[ApprovedMusicLibraryCacheClient.self] }
    set { self[ApprovedMusicLibraryCacheClient.self] = newValue }
  }
}

extension ApprovedMusicLibraryCacheClient {
  static func live(directory: URL) -> Self {
    let diskCache = ChildScopedDiskJSONCache<ApprovedMusicLibrary>(
      directory: directory,
      version: 2,
      isValid: { $0.hasCompleteSnapshot },
    )
    return Self(
      _load: { childId in
        try await Task.detached(priority: .utility) {
          try diskCache.load(childId: childId)
        }.value
      },
      _save: { library, childId in
        try await Task.detached(priority: .utility) {
          try diskCache.save(library, childId: childId)
        }.value
      },
      _delete: { childId in
        await Task.detached(priority: .utility) {
          try? diskCache.delete(childId: childId)
        }.value
      },
    )
  }

  static let noop = Self(
    _load: { _ in nil },
    _save: { _, _ in },
    _delete: { _ in },
  )
}
