import Dependencies
import DependenciesMacros
import Foundation
import MusicRoute
import PairQL

@DependencyClient
struct ApprovedMusicClient: Sendable {
  var addToPlaylist:
    @Sendable (_ input: AddToMusicPlaylist.Input) async throws -> MusicPlaylistMutationResult
  var createPlaylist:
    @Sendable (_ input: CreateMusicPlaylist.Input) async throws -> MusicPlaylistMutationResult
  var deletePlaylist:
    @Sendable (_ input: DeleteMusicPlaylist.Input) async throws -> MusicPlaylistMutationResult
  var loadCachedApprovedLibrary: @Sendable () async -> ApprovedMusicLibrary?
  var loadRemoteApprovedLibrary: @Sendable () async throws -> ApprovedMusicLibrary
  var removePlaylistEntry:
    @Sendable (_ input: RemoveMusicPlaylistEntry.Input) async throws -> MusicPlaylistMutationResult
  var renamePlaylist:
    @Sendable (_ input: RenameMusicPlaylist.Input) async throws -> MusicPlaylistMutationResult
  var reorderPlaylistEntries:
    @Sendable (_ input: ReorderMusicPlaylistEntries.Input) async throws
    -> MusicPlaylistMutationResult
}

extension ApprovedMusicClient: DependencyKey {
  static var liveValue: Self {
    Self(
      addToPlaylist: { input in
        try await performPlaylistMutation { api, token in
          try await api.addToMusicPlaylist(token, input)
        }
      },
      createPlaylist: { input in
        try await performPlaylistMutation { api, token in
          try await api.createMusicPlaylist(token, input)
        }
      },
      deletePlaylist: { input in
        try await performPlaylistMutation { api, token in
          try await api.deleteMusicPlaylist(token, input)
        }
      },
      loadCachedApprovedLibrary: {
        @Dependency(\.approvedMusicLibraryCache) var cache
        @Dependency(\.keychain) var keychain
        guard let connection = keychain.loadConnection() else { return nil }
        return try? await cache.load(childId: connection.childId)
      },
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
            return try await receiveSnapshot(
              snapshot,
              cached: cached,
              childId: connection.childId,
              cache: cache,
            )
          }
        } catch let error as PqlError where error.type == .paymentRequired {
          throw ApprovedMusicClientError.musicAccessUnavailable
        }
      },
      removePlaylistEntry: { input in
        try await performPlaylistMutation { api, token in
          try await api.removeMusicPlaylistEntry(token, input)
        }
      },
      renamePlaylist: { input in
        try await performPlaylistMutation { api, token in
          try await api.renameMusicPlaylist(token, input)
        }
      },
      reorderPlaylistEntries: { input in
        try await performPlaylistMutation { api, token in
          try await api.reorderMusicPlaylistEntries(token, input)
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
      addToPlaylist: { _ in .updated(.mock) },
      createPlaylist: { _ in .updated(.mock) },
      deletePlaylist: { _ in .updated(.mock) },
      loadCachedApprovedLibrary: { .mock },
      loadRemoteApprovedLibrary: { .mock },
      removePlaylistEntry: { _ in .updated(.mock) },
      renamePlaylist: { _ in .updated(.mock) },
      reorderPlaylistEntries: { _ in .updated(.mock) },
    )
  #endif

  static let empty = Self(
    addToPlaylist: { _ in .updated(.empty) },
    createPlaylist: { _ in .updated(.empty) },
    deletePlaylist: { _ in .updated(.empty) },
    loadCachedApprovedLibrary: { .empty },
    loadRemoteApprovedLibrary: { .empty },
    removePlaylistEntry: { _ in .updated(.empty) },
    renamePlaylist: { _ in .updated(.empty) },
    reorderPlaylistEntries: { _ in .updated(.empty) },
  )
}

enum MusicPlaylistMutationResult: Equatable, Sendable {
  case updated(ApprovedMusicLibrary)
  case duplicateConfirmationRequired(
    library: ApprovedMusicLibrary,
    confirmation: MusicPlaylistDuplicateConfirmation,
  )
  case conflict(ApprovedMusicLibrary)
}

private func performPlaylistMutation(
  _ operation: @escaping @Sendable (ApiClient, UUID) async throws -> MusicPlaylistMutationOutput,
) async throws -> MusicPlaylistMutationResult {
  @Dependency(\.api) var api
  @Dependency(\.approvedMusicLibraryCache) var cache
  @Dependency(\.keychain) var keychain
  guard let connection = keychain.loadConnection() else {
    throw ApprovedMusicClientError.missingConnection
  }
  do {
    let output = try await operation(api, connection.token)
    let cached = try? await cache.load(childId: connection.childId)
    switch output {
    case .updated(let snapshot):
      let library = try await receiveSnapshot(
        snapshot,
        cached: cached,
        childId: connection.childId,
        cache: cache,
      )
      return .updated(library)
    case .duplicateConfirmationRequired(let snapshot, let confirmation):
      let library = try await receiveSnapshot(
        snapshot,
        cached: cached,
        childId: connection.childId,
        cache: cache,
      )
      return .duplicateConfirmationRequired(
        library: library,
        confirmation: confirmation,
      )
    case .conflict(let snapshot):
      let library = try await receiveSnapshot(
        snapshot,
        cached: cached,
        childId: connection.childId,
        cache: cache,
      )
      return .conflict(library)
    }
  } catch let error as PqlError where error.type == .paymentRequired {
    throw ApprovedMusicClientError.musicAccessUnavailable
  }
}

private func receiveSnapshot(
  _ snapshot: MusicLibrarySnapshot,
  cached: ApprovedMusicLibrary?,
  childId: UUID,
  cache: ApprovedMusicLibraryCacheClient,
) async throws -> ApprovedMusicLibrary {
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
  if let cached {
    guard snapshot.revision >= cached.revision else {
      throw ApprovedMusicClientError.staleSnapshot
    }
    if snapshot.revision == cached.revision {
      guard library == cached else {
        throw ApprovedMusicClientError.inconsistentSnapshot
      }
      return cached
    }
  }
  try? await cache.save(library, childId: childId)
  return library
}

private extension ApprovedMusicLibrary {
  init(remote snapshot: MusicLibrarySnapshot) {
    self.init(
      schemaVersion: snapshot.schemaVersion,
      revision: snapshot.revision,
      generatedAt: snapshot.generatedAt,
      albums: snapshot.albums.map(ApprovedAlbum.init),
      artists: snapshot.artists.map(ApprovedArtist.init),
      playlists: snapshot.playlists.map(MusicPlaylist.init),
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

private extension MusicPlaylist {
  init(remote playlist: MusicLibrarySnapshot.Playlist) {
    self.init(
      id: .init(rawValue: playlist.id),
      name: playlist.name,
      revision: playlist.revision,
      createdAt: playlist.createdAt,
      updatedAt: playlist.updatedAt,
      entries: playlist.entries.map(MusicPlaylistEntry.init),
    )
  }
}

private extension MusicPlaylistEntry {
  init(remote entry: MusicLibrarySnapshot.Playlist.Entry) {
    self.init(
      id: .init(rawValue: entry.id),
      track: .init(remote: entry.track),
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
      discNumber: track.discNumber,
      trackNumber: track.trackNumber,
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
  case inconsistentSnapshot
  case invalidRevision
  case invalidUnchangedRevision
  case missingConnection
  case staleSnapshot
  case musicAccessUnavailable
  case unsupportedSchema(Int)
}
