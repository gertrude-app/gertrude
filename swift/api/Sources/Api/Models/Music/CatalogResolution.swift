import Foundation
import MusicRoute

extension Music {
  struct ResolvedTrack: Codable, Equatable, Sendable {
    var id: TrackId
    var title: String
    var artistName: String
    var artistIds: [ArtistId]
    var albumId: AlbumId
    var albumTitle: String
    var artworkUrl: String?
    var durationInMillis: Int?

    init(
      id: TrackId,
      title: String,
      artistName: String,
      artistIds: [ArtistId],
      albumId: AlbumId,
      albumTitle: String,
      artworkUrl: String? = nil,
      durationInMillis: Int? = nil,
    ) {
      self.id = id
      self.title = title
      self.artistName = artistName
      self.artistIds = artistIds
      self.albumId = albumId
      self.albumTitle = albumTitle
      self.artworkUrl = artworkUrl
      self.durationInMillis = durationInMillis
    }
  }

  struct ResolvedAlbum: Codable, Equatable, Sendable {
    var id: AlbumId
    var title: String
    var artistName: String
    var artistIds: [ArtistId]
    var artworkUrl: String?
    var artwork: Artwork?
    var trackCount: Int?
    var releaseDate: String?
    var releaseType: String?
    var tracks: [ResolvedTrack]

    init(
      id: AlbumId,
      title: String,
      artistName: String,
      artistIds: [ArtistId],
      artworkUrl: String? = nil,
      artwork: Artwork? = nil,
      trackCount: Int? = nil,
      releaseDate: String? = nil,
      releaseType: String? = nil,
      tracks: [ResolvedTrack],
    ) {
      self.id = id
      self.title = title
      self.artistName = artistName
      self.artistIds = artistIds
      self.artworkUrl = artworkUrl
      self.artwork = artwork
      self.trackCount = trackCount
      self.releaseDate = releaseDate
      self.releaseType = releaseType
      self.tracks = tracks
    }
  }

  struct ResolvedArtist: Codable, Equatable, Sendable {
    var id: ArtistId
    var name: String
    var catalogMetadata: CatalogMetadata?
    var topSongs: [ResolvedTrack]
    var albums: [ResolvedAlbum]

    init(
      id: ArtistId,
      name: String,
      catalogMetadata: CatalogMetadata? = nil,
      topSongs: [ResolvedTrack],
      albums: [ResolvedAlbum],
    ) {
      self.id = id
      self.name = name
      self.catalogMetadata = catalogMetadata
      self.topSongs = topSongs
      self.albums = albums
    }
  }

  enum LibrarySnapshotCompiler {
    struct AlbumGrant: Equatable, Sendable {
      var appleMusicAlbumId: AlbumId
      var createdAt: Date
      var showsArtwork: Bool
      var resolution: ResolvedAlbum?

      init(
        appleMusicAlbumId: AlbumId,
        createdAt: Date,
        showsArtwork: Bool,
        resolution: ResolvedAlbum?,
      ) {
        self.appleMusicAlbumId = appleMusicAlbumId
        self.createdAt = createdAt
        self.showsArtwork = showsArtwork
        self.resolution = resolution
      }
    }

    struct ArtistGrant: Equatable, Sendable {
      var appleMusicArtistId: ArtistId
      var createdAt: Date
      var resolution: ResolvedArtist?

      init(
        appleMusicArtistId: ArtistId,
        createdAt: Date,
        resolution: ResolvedArtist?,
      ) {
        self.appleMusicArtistId = appleMusicArtistId
        self.createdAt = createdAt
        self.resolution = resolution
      }
    }

    struct Content: Equatable, Sendable {
      var albums: [MusicLibrarySnapshot.Album]
      var artists: [MusicLibrarySnapshot.Artist]
      var playlists: [MusicLibrarySnapshot.Playlist] = []

      func snapshot(revision: Int64, generatedAt: Date) -> MusicLibrarySnapshot {
        .init(
          revision: revision,
          generatedAt: generatedAt,
          albums: self.albums,
          artists: self.artists,
          playlists: self.playlists,
        )
      }
    }

    enum CompilerError: Error, Equatable {
      case missingAlbumResolution(AlbumId)
      case missingArtistResolution(ArtistId)
      case albumResolutionIdMismatch(expected: AlbumId, actual: AlbumId)
      case artistResolutionIdMismatch(expected: ArtistId, actual: ArtistId)
      case trackAlbumIdMismatch(track: TrackId, expected: AlbumId, actual: AlbumId)
    }

    static func compile(
      albumGrants: [AlbumGrant],
      artistGrants: [ArtistGrant],
      playlists: [PlaylistRules.Playlist] = [],
    ) throws -> Content {
      let sortedAlbumGrants = albumGrants.sorted(by: self.albumGrantOrder)
      let sortedArtistGrants = artistGrants.sorted(by: self.artistGrantOrder)
      try self.validate(albumGrants: sortedAlbumGrants, artistGrants: sortedArtistGrants)
      let albumGrants = self.deduplicatedAlbumGrants(sortedAlbumGrants)
      let artistGrants = self.deduplicatedArtistGrants(sortedArtistGrants)

      var albumsById: [AlbumId: ResolvedAlbum] = [:]
      var albumOrder: [AlbumId] = []
      var seenAlbumIds = Set<AlbumId>()
      var albumAddedAt: [AlbumId: Date] = [:]
      var showsArtwork: [AlbumId: Bool] = [:]

      for grant in albumGrants {
        let album = grant.resolution!
        if seenAlbumIds.insert(album.id).inserted {
          albumOrder.append(album.id)
          albumsById[album.id] = album
        }
        albumAddedAt[album.id] = max(albumAddedAt[album.id] ?? grant.createdAt, grant.createdAt)
        showsArtwork[album.id] = grant.showsArtwork
      }

      for grant in artistGrants {
        for album in grant.resolution!.albums {
          if seenAlbumIds.insert(album.id).inserted {
            albumOrder.append(album.id)
            albumsById[album.id] = album
          }
          albumAddedAt[album.id] = max(albumAddedAt[album.id] ?? grant.createdAt, grant.createdAt)
        }
      }

      let albums = albumOrder.map { albumId in
        let album = albumsById[albumId]!
        return MusicLibrarySnapshot.Album(
          id: album.id.rawValue,
          title: album.title,
          artistName: album.artistName,
          artworkUrl: album.artworkUrl,
          artwork: album.artwork.map(MusicArtwork.init),
          trackCount: album.trackCount,
          releaseDate: album.releaseDate,
          releaseType: album.releaseType,
          showsArtwork: showsArtwork[albumId] ?? true,
          addedAt: albumAddedAt[albumId]!,
          tracks: self.outputTracks(album.tracks, album: album),
        )
      }

      let artists = artistGrants.map { grant in
        let artist = grant.resolution!
        var seenReleaseIds = Set<AlbumId>()
        let releaseAlbumIds = artist.albums.compactMap { album in
          seenReleaseIds.insert(album.id).inserted ? album.id.rawValue : nil
        }
        let qualifyingAlbumIds = Set(artist.albums.map(\.id))
        var seenTopSongIds = Set<TrackId>()
        let topSongs = artist.topSongs.compactMap { track -> MusicLibrarySnapshot.Track? in
          guard qualifyingAlbumIds.contains(track.albumId) else { return nil }
          guard seenTopSongIds.insert(track.id).inserted else { return nil }
          guard let album = artist.albums.first(where: { $0.id == track.albumId }) else {
            return nil
          }
          guard album.tracks.contains(where: { $0.id == track.id }) else { return nil }
          return self.outputTrack(track, fallbackArtworkUrl: album.artworkUrl)
        }
        return MusicLibrarySnapshot.Artist(
          id: artist.id.rawValue,
          name: artist.name,
          catalogMetadata: artist.catalogMetadata.map(MusicCatalogMetadata.init),
          releaseAlbumIds: releaseAlbumIds,
          topSongs: topSongs,
          addedAt: grant.createdAt,
        )
      }

      return .init(
        albums: albums,
        artists: artists,
        playlists: PlaylistRules.compile(
          playlists: playlists,
          using: .init(albums: albums),
        ),
      )
    }

    private static func deduplicatedAlbumGrants(
      _ grants: [AlbumGrant],
    ) -> [AlbumGrant] {
      var deduplicated: [AlbumGrant] = []
      var indexById: [AlbumId: Int] = [:]
      for grant in grants {
        if let index = indexById[grant.appleMusicAlbumId] {
          deduplicated[index].createdAt = max(deduplicated[index].createdAt, grant.createdAt)
          deduplicated[index].showsArtwork = grant.showsArtwork
        } else {
          indexById[grant.appleMusicAlbumId] = deduplicated.count
          deduplicated.append(grant)
        }
      }
      return deduplicated
    }

    private static func deduplicatedArtistGrants(
      _ grants: [ArtistGrant],
    ) -> [ArtistGrant] {
      var deduplicated: [ArtistGrant] = []
      var indexById: [ArtistId: Int] = [:]
      for grant in grants {
        if let index = indexById[grant.appleMusicArtistId] {
          deduplicated[index].createdAt = max(deduplicated[index].createdAt, grant.createdAt)
        } else {
          indexById[grant.appleMusicArtistId] = deduplicated.count
          deduplicated.append(grant)
        }
      }
      return deduplicated
    }

    private static func validate(
      albumGrants: [AlbumGrant],
      artistGrants: [ArtistGrant],
    ) throws {
      for grant in albumGrants {
        guard let resolution = grant.resolution else {
          throw CompilerError.missingAlbumResolution(grant.appleMusicAlbumId)
        }
        guard resolution.id == grant.appleMusicAlbumId else {
          throw CompilerError.albumResolutionIdMismatch(
            expected: grant.appleMusicAlbumId,
            actual: resolution.id,
          )
        }
        try self.validateTracks(in: resolution)
      }
      for grant in artistGrants {
        guard let resolution = grant.resolution else {
          throw CompilerError.missingArtistResolution(grant.appleMusicArtistId)
        }
        guard resolution.id == grant.appleMusicArtistId else {
          throw CompilerError.artistResolutionIdMismatch(
            expected: grant.appleMusicArtistId,
            actual: resolution.id,
          )
        }
        for album in resolution.albums {
          try self.validateTracks(in: album)
        }
      }
    }

    private static func validateTracks(in album: ResolvedAlbum) throws {
      for track in album.tracks where track.albumId != album.id {
        throw CompilerError.trackAlbumIdMismatch(
          track: track.id,
          expected: album.id,
          actual: track.albumId,
        )
      }
    }

    private static func outputTracks(
      _ tracks: [ResolvedTrack],
      album: ResolvedAlbum,
    ) -> [MusicLibrarySnapshot.Track] {
      var seenTrackIds = Set<TrackId>()
      return tracks.compactMap { track in
        guard seenTrackIds.insert(track.id).inserted else { return nil }
        return self.outputTrack(track, fallbackArtworkUrl: album.artworkUrl)
      }
    }

    private static func outputTrack(
      _ track: ResolvedTrack,
      fallbackArtworkUrl: String?,
    ) -> MusicLibrarySnapshot.Track {
      .init(
        id: track.id.rawValue,
        title: track.title,
        artistName: track.artistName,
        albumId: track.albumId.rawValue,
        albumTitle: track.albumTitle,
        artworkUrl: track.artworkUrl ?? fallbackArtworkUrl,
        durationInMillis: track.durationInMillis,
      )
    }

    private static func albumGrantOrder(_ lhs: AlbumGrant, _ rhs: AlbumGrant) -> Bool {
      if lhs.createdAt != rhs.createdAt {
        return lhs.createdAt < rhs.createdAt
      }
      return lhs.appleMusicAlbumId.rawValue < rhs.appleMusicAlbumId.rawValue
    }

    private static func artistGrantOrder(_ lhs: ArtistGrant, _ rhs: ArtistGrant) -> Bool {
      if lhs.createdAt != rhs.createdAt {
        return lhs.createdAt < rhs.createdAt
      }
      return lhs.appleMusicArtistId.rawValue < rhs.appleMusicArtistId.rawValue
    }
  }
}

extension MusicArtwork {
  init(_ artwork: Music.Artwork) {
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

extension MusicEditorialNotes {
  init(_ notes: Music.EditorialNotes) {
    self.init(
      tagline: notes.tagline,
      short: notes.short,
      standard: notes.standard,
      name: notes.name,
    )
  }
}

extension MusicCatalogMetadata {
  init(_ metadata: Music.CatalogMetadata) {
    self.init(
      artwork: metadata.artwork.map(MusicArtwork.init),
      editorialNotes: metadata.editorialNotes.map(MusicEditorialNotes.init),
      appleMusicUrl: metadata.appleMusicUrl,
      genreNames: metadata.genreNames,
    )
  }
}

extension MusicLibrarySnapshot {
  func hasSameContent(as content: Music.LibrarySnapshotCompiler.Content) -> Bool {
    self.schemaVersion == Self.currentSchemaVersion
      && self.albums == content.albums
      && self.artists == content.artists
      && self.playlists == content.playlists
  }
}
