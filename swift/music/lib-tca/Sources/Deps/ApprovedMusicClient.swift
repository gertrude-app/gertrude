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
          let cached = try? await cache.load(childId: connection.childId)
          let output = try await api.getApprovedMusicLibrary(
            connection.token,
            cached?.revision,
          )
          switch output {
          case .unchanged(let revision):
            guard let cached, cached.revision == revision else {
              throw ApprovedMusicClientError.invalidUnchangedRevision
            }
            return cached
          case .snapshot(let snapshot):
            guard snapshot.schemaVersion == MusicLibrarySnapshot.currentSchemaVersion else {
              throw ApprovedMusicClientError.unsupportedSchema(snapshot.schemaVersion)
            }
            guard snapshot.revision >= 0 else {
              throw ApprovedMusicClientError.invalidRevision
            }
            let library = ApprovedMusicLibrary(remote: snapshot)
            guard library.hasCompleteSnapshot else {
              throw ApprovedMusicClientError.incompleteSnapshot
            }
            if let cached, snapshot.revision <= cached.revision {
              guard snapshot.revision == cached.revision else {
                throw ApprovedMusicClientError.staleSnapshot
              }
              return cached
            }
            try? await cache.save(library, childId: connection.childId)
            return library
          }
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
  init(remote snapshot: MusicLibrarySnapshot) {
    self.init(
      schemaVersion: snapshot.schemaVersion,
      revision: snapshot.revision,
      generatedAt: snapshot.generatedAt,
      albums: snapshot.albums.map(ApprovedAlbum.init),
      artists: snapshot.artists.map(ApprovedArtist.init),
    )
  }
}

private extension ApprovedAlbum {
  init(remote album: MusicLibrarySnapshot.Album) {
    let artwork = album.artwork.map(ApprovedMusicArtwork.init)
    self.init(
      id: .init(rawValue: album.id),
      title: album.title,
      artistName: album.artistName,
      artworkURL: artwork?.artworkURL ?? album.artworkURL,
      artwork: artwork,
      trackCount: album.trackCount,
      releaseDate: album.releaseDate,
      releaseType: album.releaseType,
      addedAt: album.addedAt,
      tracks: album.tracks.map(ApprovedTrack.init),
    )
  }
}

private extension ApprovedArtist {
  init(remote artist: MusicLibrarySnapshot.Artist) {
    self.init(
      id: .init(rawValue: artist.id),
      name: artist.name,
      catalogMetadata: artist.catalogMetadata.map(ApprovedMusicCatalogMetadata.init),
      releaseAlbumIds: artist.releaseAlbumIds.map(ApprovedAlbum.ID.init(rawValue:)),
      topSongs: artist.topSongs.map(ApprovedTrack.init),
      addedAt: artist.addedAt,
    )
  }
}

private extension ApprovedMusicCatalogMetadata {
  init(remote metadata: MusicCatalogMetadata) {
    self.init(
      artwork: metadata.artwork.map(ApprovedMusicArtwork.init),
      editorialNotes: metadata.editorialNotes.map(ApprovedMusicEditorialNotes.init),
      appleMusicUrl: metadata.appleMusicUrl,
      genreNames: metadata.genreNames,
    )
  }
}

private extension ApprovedMusicArtwork {
  init(remote artwork: MusicArtwork) {
    self.init(
      url: artwork.url,
      width: artwork.width,
      height: artwork.height,
      bgColor: artwork.bgColor,
      textColor1: artwork.textColor1,
      textColor2: artwork.textColor2,
      textColor3: artwork.textColor3,
      textColor4: artwork.textColor4,
    )
  }
}

private extension ApprovedMusicEditorialNotes {
  init(remote notes: MusicEditorialNotes) {
    self.init(
      tagline: notes.tagline,
      short: notes.short,
      standard: notes.standard,
      name: notes.name,
    )
  }
}

private extension ApprovedTrack {
  init(remote track: MusicLibrarySnapshot.Track) {
    self.init(
      id: .init(rawValue: track.id),
      title: track.title,
      artistName: track.artistName,
      albumID: .init(rawValue: track.albumId),
      albumTitle: track.albumTitle,
      artworkURL: track.artworkURL,
      durationInMillis: track.durationInMillis,
    )
  }
}

private extension ApprovedMusicArtwork {
  var artworkURL: URL? {
    guard var url = self.url else { return nil }
    url = url.replacingOccurrences(of: "{w}", with: "600")
    url = url.replacingOccurrences(of: "{h}", with: "600")
    return URL(string: url)
  }
}

private extension MusicLibrarySnapshot.Album {
  var artworkURL: URL? {
    guard let artworkUrl else { return nil }
    return URL(string: artworkUrl)
  }
}

private extension MusicLibrarySnapshot.Track {
  var artworkURL: URL? {
    guard let artworkUrl else { return nil }
    return URL(string: artworkUrl)
  }
}

enum ApprovedMusicClientError: Error {
  case incompleteSnapshot
  case invalidRevision
  case invalidUnchangedRevision
  case missingConnection
  case staleSnapshot
  case subscriptionRequired
  case unsupportedSchema(Int)
}
