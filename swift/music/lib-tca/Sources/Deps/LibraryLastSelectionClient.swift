import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct LibraryLastSelectionClient: Sendable {
  var load: @Sendable () async -> LibraryCollectionIdentity?
  var save: @Sendable (_ selection: LibraryCollectionIdentity?) async -> Void
}

extension LibraryLastSelectionClient: DependencyKey {
  private static let key = "gertrude.music.library-last-selection.v1"

  static let liveValue = Self(
    load: {
      UserDefaults.standard.data(forKey: Self.key)
        .flatMap { try? JSONDecoder().decode(LibraryCollectionIdentity.self, from: $0) }
    },
    save: { selection in
      guard let data = selection.flatMap({ try? JSONEncoder().encode($0) }) else {
        return UserDefaults.standard.removeObject(forKey: Self.key)
      }
      UserDefaults.standard.set(data, forKey: Self.key)
    },
  )

  static let testValue = Self(
    load: { nil },
    save: { _ in },
  )
}

extension DependencyValues {
  var libraryLastSelection: LibraryLastSelectionClient {
    get { self[LibraryLastSelectionClient.self] }
    set { self[LibraryLastSelectionClient.self] = newValue }
  }
}
