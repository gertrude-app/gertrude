import Dependencies
import DependenciesMacros
import Foundation
import MusicRoute
import PairQL

@DependencyClient
struct ApprovedMusicClient: Sendable {
  var loadRemoteApprovedLibrary: @Sendable () async throws -> ApprovedMusicLibrary
  var loadCachedApprovedLibrary: @Sendable () async -> ApprovedMusicLibrary?
}

extension ApprovedMusicClient: DependencyKey {
  static var liveValue: Self {
    Self(
      loadRemoteApprovedLibrary: {
        @Dependency(\.api) var api
        @Dependency(\.approvedMusicLibraryCache) var cache
        @Dependency(\.keychain) var keychain
        guard let connection = keychain.loadConnection() else {
          throw ApprovedMusicClientError.missingConnection
        }
        do {
          let output = try await api.getApprovedMusicLibrary(connection.token)
          let library = ApprovedMusicLibrary(remote: output)
          try? await cache.save(library, childId: connection.childId)
          return library
        } catch let error as PqlError where error.type == .paymentRequired {
          throw ApprovedMusicClientError.subscriptionRequired
        }
      },
      loadCachedApprovedLibrary: {
        @Dependency(\.approvedMusicLibraryCache) var cache
        @Dependency(\.keychain) var keychain
        guard let connection = keychain.loadConnection() else { return nil }
        return try? await cache.load(childId: connection.childId)
      },
    )
  }
}

extension DependencyValues {
  var approvedMusic: ApprovedMusicClient {
    get { self[ApprovedMusicClient.self] }
    set { self[ApprovedMusicClient.self] = newValue }
  }
}

extension ApprovedMusicClient {
  #if DEBUG
    static let mock = Self(
      loadRemoteApprovedLibrary: { .mock },
      loadCachedApprovedLibrary: { .mock },
    )
  #endif

  static let empty = Self(
    loadRemoteApprovedLibrary: { .empty },
    loadCachedApprovedLibrary: { .empty },
  )
}

private extension ApprovedMusicLibrary {
  init(remote output: GetApprovedMusicLibrary.Output) {
    self.init(albums: output.albums.map(ApprovedAlbum.init))
  }
}

private extension ApprovedAlbum {
  init(remote album: GetApprovedMusicLibrary.Output.Album) {
    self.init(
      id: .init(rawValue: album.id),
      title: album.title,
      artistName: album.artistName,
      artworkURL: album.artworkURL,
      tracks: album.tracks.map(ApprovedTrack.init),
    )
  }
}

private extension ApprovedTrack {
  init(remote track: GetApprovedMusicLibrary.Output.Track) {
    self.init(
      id: .init(rawValue: track.id),
      title: track.title,
      artistName: track.artistName,
      artworkURL: track.artworkURL,
    )
  }
}

private extension GetApprovedMusicLibrary.Output.Album {
  var artworkURL: URL? {
    guard let artworkUrl else { return nil }
    return URL(string: artworkUrl)
  }
}

private extension GetApprovedMusicLibrary.Output.Track {
  var artworkURL: URL? {
    guard let artworkUrl else { return nil }
    return URL(string: artworkUrl)
  }
}

enum ApprovedMusicClientError: Error {
  case missingConnection
  case subscriptionRequired
}
