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
    .live(directory: ApprovedMusicLibraryDiskCache.defaultDirectory)
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
    let diskCache = ApprovedMusicLibraryDiskCache(directory: directory)
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

struct ApprovedMusicLibraryDiskCache: Sendable {
  static let version = 1

  static var defaultDirectory: URL {
    let applicationSupportDirectory = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
    ).first ?? FileManager.default.temporaryDirectory

    return applicationSupportDirectory
      .appendingPathComponent("GertrudeMusic", isDirectory: true)
      .appendingPathComponent("ApprovedMusicLibraryCache", isDirectory: true)
  }

  let directory: URL

  func load(childId: UUID) throws -> ApprovedMusicLibrary? {
    let fileURL = self.fileURL(childId: childId)
    guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
    let data = try Data(contentsOf: fileURL)
    guard let envelope = try? JSONDecoder().decode(
      ApprovedMusicLibraryCacheEnvelope.self,
      from: data,
    ), envelope.version == Self.version else {
      return nil
    }
    return envelope.library
  }

  func save(_ library: ApprovedMusicLibrary, childId: UUID) throws {
    try FileManager.default.createDirectory(
      at: self.directory,
      withIntermediateDirectories: true,
    )
    let envelope = ApprovedMusicLibraryCacheEnvelope(version: Self.version, library: library)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(envelope)
    try data.write(to: self.fileURL(childId: childId), options: [.atomic])
  }

  func delete(childId: UUID) throws {
    let fileURL = self.fileURL(childId: childId)
    guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
    try FileManager.default.removeItem(at: fileURL)
  }

  func fileURL(childId: UUID) -> URL {
    self.directory.appendingPathComponent(
      "\(childId.uuidString.lowercased()).json",
      isDirectory: false,
    )
  }
}

private struct ApprovedMusicLibraryCacheEnvelope: Codable {
  var version: Int
  var library: ApprovedMusicLibrary
}
