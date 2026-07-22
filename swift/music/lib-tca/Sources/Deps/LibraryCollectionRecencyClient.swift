import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct LibraryCollectionRecencyClient: Sendable {
  var load: @Sendable () async -> LibraryCollectionRecency?
  var save: @Sendable (_ recency: LibraryCollectionRecency) async -> Void
}

extension LibraryCollectionRecencyClient: DependencyKey {
  static var liveValue: Self {
    .live(directory: ChildScopedDiskJSONCache<LibraryCollectionRecency>.directory(
      named: "LibraryCollectionRecencyCache",
    ))
  }

  static let testValue = Self(
    load: { nil },
    save: { _ in },
  )
}

extension LibraryCollectionRecencyClient {
  static func live(directory: URL) -> Self {
    let storage = LibraryCollectionRecencyStorage(
      cache: ChildScopedDiskJSONCache<LibraryCollectionRecency>(
        directory: directory,
        version: 1,
        isValid: { _ in true },
      ),
    )
    return Self(
      load: {
        @Dependency(\.keychain) var keychain
        guard let childID = keychain.loadConnection()?.childId else { return nil }
        return await storage.load(childID: childID)
      },
      save: { recency in
        @Dependency(\.keychain) var keychain
        guard let childID = keychain.loadConnection()?.childId else { return }
        await storage.save(recency, childID: childID)
      },
    )
  }
}

private actor LibraryCollectionRecencyStorage {
  let cache: ChildScopedDiskJSONCache<LibraryCollectionRecency>

  init(cache: ChildScopedDiskJSONCache<LibraryCollectionRecency>) {
    self.cache = cache
  }

  func load(childID: UUID) -> LibraryCollectionRecency? {
    try? self.cache.load(childId: childID)
  }

  func save(_ recency: LibraryCollectionRecency, childID: UUID) {
    var merged = (try? self.cache.load(childId: childID)) ?? .init()
    for (identity, record) in recency.records {
      if let existing = merged.records[identity],
         existing.lastPlayedAt > record.lastPlayedAt { continue }
      merged.records[identity] = record
    }
    try? self.cache.save(merged, childId: childID)
  }
}

extension DependencyValues {
  var libraryCollectionRecency: LibraryCollectionRecencyClient {
    get { self[LibraryCollectionRecencyClient.self] }
    set { self[LibraryCollectionRecencyClient.self] = newValue }
  }
}
