import Dependencies
import DependenciesMacros
import Foundation
import MusicRoute
import PairQL

@DependencyClient
struct ApprovedMusicClient: Sendable {
  var loadRemoteApprovedLibrary: @Sendable () async throws -> ApprovedMusicLibrary
  var loadCachedApprovedLibrary: @Sendable () async -> ApprovedMusicLibrary?
  var loadAlbumTracks: @Sendable (_ albumID: ApprovedAlbum.ID) async throws -> [ApprovedTrack]
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
      loadAlbumTracks: { albumID in
        @Dependency(\.api) var api
        @Dependency(\.keychain) var keychain
        guard let connection = keychain.loadConnection() else {
          throw ApprovedMusicClientError.missingConnection
        }
        do {
          return try await api.getApprovedMusicAlbumTracks(
            connection.token,
            albumID.rawValue,
          ).map(ApprovedTrack.init)
        } catch let error as PqlError where error.type == .paymentRequired {
          throw ApprovedMusicClientError.subscriptionRequired
        }
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
      loadAlbumTracks: { albumID in ApprovedMusicLibrary.mock.album(id: albumID)?.tracks ?? [] },
    )
  #endif

  static let empty = Self(
    loadRemoteApprovedLibrary: { .empty },
    loadCachedApprovedLibrary: { .empty },
    loadAlbumTracks: { _ in [] },
  )
}

private extension ApprovedMusicLibrary {
  init(remote output: GetApprovedMusicLibrary_v2.Output) {
    self.init(
      albums: output.albums.map(ApprovedAlbum.init),
      artists: output.artists.map(ApprovedArtist.init),
    )
  }
}

private extension ApprovedAlbum {
  init(remote album: GetApprovedMusicLibrary_v2.Output.Album) {
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
    )
  }
}

private extension ApprovedArtist {
  init(remote artist: GetApprovedMusicLibrary_v2.Output.Artist) {
    self.init(
      id: .init(rawValue: artist.id),
      name: artist.name,
      catalogMetadata: artist.catalogMetadata.map(ApprovedMusicCatalogMetadata.init),
      releaseAlbumIds: artist.releaseAlbumIds?.map(ApprovedAlbum.ID.init(rawValue:)),
      topSongs: artist.topSongs?.map(ApprovedTrack.init),
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
  init(remote track: GetApprovedMusicLibrary.Output.Track) {
    self.init(
      id: .init(rawValue: track.id),
      title: track.title,
      artistName: track.artistName,
      artworkURL: track.artworkURL,
    )
  }

  init(remote song: GetApprovedMusicLibrary_v2.Output.Artist.TopSong) {
    self.init(
      id: .init(rawValue: song.id),
      title: song.title,
      artistName: song.artistName,
      albumTitle: song.albumTitle,
      artworkURL: song.artworkURL,
      durationInMillis: song.durationInMillis,
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

private extension GetApprovedMusicLibrary_v2.Output.Album {
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

private extension GetApprovedMusicLibrary_v2.Output.Artist.TopSong {
  var artworkURL: URL? {
    guard let artworkUrl else { return nil }
    return URL(string: artworkUrl)
  }
}

enum ApprovedMusicClientError: Error {
  case missingConnection
  case subscriptionRequired
}
