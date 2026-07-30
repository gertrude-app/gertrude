import Foundation
import MusicRoute
import PairQL

extension Music {
  enum ContentRating: String, PairNestable {
    case clean
    case explicit
  }

  struct ResolvedTrack: Codable, Equatable, Sendable {
    var id: TrackId
    var title: String
    var artistName: String
    var artistIds: [ArtistId]
    var albumId: AlbumId
    var albumTitle: String
    var artworkUrl: String?
    var durationInMillis: Int?
    var discNumber: Int?
    var trackNumber: Int?
    var contentRating: ContentRating?
    var appleMusicUrl: String?

    init(
      id: TrackId,
      title: String,
      artistName: String,
      artistIds: [ArtistId],
      albumId: AlbumId,
      albumTitle: String,
      artworkUrl: String? = nil,
      durationInMillis: Int? = nil,
      discNumber: Int? = nil,
      trackNumber: Int? = nil,
      contentRating: ContentRating? = nil,
      appleMusicUrl: String? = nil,
    ) {
      self.id = id
      self.title = title
      self.artistName = artistName
      self.artistIds = artistIds
      self.albumId = albumId
      self.albumTitle = albumTitle
      self.artworkUrl = artworkUrl
      self.durationInMillis = durationInMillis
      self.discNumber = discNumber
      self.trackNumber = trackNumber
      self.contentRating = contentRating
      self.appleMusicUrl = appleMusicUrl
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
    var appleMusicUrl: String?
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
      appleMusicUrl: String? = nil,
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
      self.appleMusicUrl = appleMusicUrl
      self.tracks = tracks
    }
  }

  struct ResolvedAlbumSummary: Codable, Equatable, Sendable {
    var id: AlbumId
    var title: String
    var artistName: String
    var artistIds: [ArtistId]
    var artworkUrl: String?
    var artwork: Artwork?
    var trackCount: Int
    var releaseDate: String?
    var releaseType: String?
    var appleMusicUrl: String?

    init(
      id: AlbumId,
      title: String,
      artistName: String,
      artistIds: [ArtistId],
      artworkUrl: String? = nil,
      artwork: Artwork? = nil,
      trackCount: Int,
      releaseDate: String? = nil,
      releaseType: String? = nil,
      appleMusicUrl: String? = nil,
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
      self.appleMusicUrl = appleMusicUrl
    }
  }

  struct ResolvedTrackGrant: Codable, Equatable, Sendable {
    enum ValidationError: Error, Equatable, Sendable {
      case trackIdMismatch(expected: TrackId, actual: TrackId)
      case preferredAlbumIdMismatch(expected: AlbumId, actual: AlbumId)
      case trackAlbumIdMismatch(track: TrackId, expected: AlbumId, actual: AlbumId)
      case invalidCatalogPosition(Int)
    }

    var track: ResolvedTrack
    var preferredAlbum: ResolvedAlbumSummary
    var catalogPosition: Int

    init(
      track: ResolvedTrack,
      preferredAlbum: ResolvedAlbumSummary,
      catalogPosition: Int,
    ) {
      self.track = track
      self.preferredAlbum = preferredAlbum
      self.catalogPosition = catalogPosition
    }

    func validate(
      appleMusicTrackId: TrackId,
      preferredAlbumId: AlbumId,
    ) throws {
      guard self.track.id == appleMusicTrackId else {
        throw ValidationError.trackIdMismatch(
          expected: appleMusicTrackId,
          actual: self.track.id,
        )
      }
      guard self.preferredAlbum.id == preferredAlbumId else {
        throw ValidationError.preferredAlbumIdMismatch(
          expected: preferredAlbumId,
          actual: self.preferredAlbum.id,
        )
      }
      guard self.track.albumId == self.preferredAlbum.id else {
        throw ValidationError.trackAlbumIdMismatch(
          track: self.track.id,
          expected: self.preferredAlbum.id,
          actual: self.track.albumId,
        )
      }
      guard self.catalogPosition >= 0 else {
        throw ValidationError.invalidCatalogPosition(self.catalogPosition)
      }
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

    struct TrackGrant: Equatable, Sendable {
      var appleMusicTrackId: TrackId
      var preferredAlbumId: AlbumId
      var createdAt: Date
      var showsArtwork: Bool
      var resolution: ResolvedTrackGrant

      init(
        appleMusicTrackId: TrackId,
        preferredAlbumId: AlbumId,
        createdAt: Date,
        showsArtwork: Bool,
        resolution: ResolvedTrackGrant,
      ) {
        self.appleMusicTrackId = appleMusicTrackId
        self.preferredAlbumId = preferredAlbumId
        self.createdAt = createdAt
        self.showsArtwork = showsArtwork
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
      case invalidTrackResolution(ResolvedTrackGrant.ValidationError)
    }

    static func compile(
      albumGrants: [AlbumGrant],
      artistGrants: [ArtistGrant],
      trackGrants: [TrackGrant] = [],
      playlists: [PlaylistRules.Playlist] = [],
    ) throws -> Content {
      let sortedAlbumGrants = albumGrants.sorted(by: self.albumGrantOrder)
      let sortedArtistGrants = artistGrants.sorted(by: self.artistGrantOrder)
      let sortedTrackGrants = trackGrants.sorted(by: self.trackGrantOrder)
      try self.validate(
        albumGrants: sortedAlbumGrants,
        artistGrants: sortedArtistGrants,
        trackGrants: sortedTrackGrants,
      )
      let albumGrants = self.deduplicatedAlbumGrants(sortedAlbumGrants)
      let artistGrants = self.deduplicatedArtistGrants(sortedArtistGrants)
      let trackGrants = self.deduplicatedTrackGrants(sortedTrackGrants)
      let coverage = try CatalogPolicy.CoverageIndex(
        artistGrants: artistGrants.map {
          .init(
            appleMusicArtistId: $0.appleMusicArtistId,
            resolution: $0.resolution,
          )
        },
        albumGrants: albumGrants.map {
          .init(
            appleMusicAlbumId: $0.appleMusicAlbumId,
            resolution: $0.resolution,
          )
        },
        trackGrants: trackGrants.map {
          .init(
            appleMusicTrackId: $0.appleMusicTrackId,
            preferredAlbumId: $0.preferredAlbumId,
            resolution: $0.resolution,
          )
        },
      )

      var albumsById: [AlbumId: ResolvedAlbum] = [:]
      var albumOrder: [AlbumId] = []
      var albumAddedAt: [AlbumId: Date] = [:]
      var showsArtwork: [AlbumId: Bool] = [:]
      var trackPositionsByAlbumId: [AlbumId: [TrackId: Int]] = [:]

      for grant in albumGrants {
        if case .artist? = coverage.governingGrant(forAlbum: grant.appleMusicAlbumId) {
          continue
        }
        let album = grant.resolution!
        if albumsById[album.id] == nil {
          albumOrder.append(album.id)
          albumsById[album.id] = album
        }
        albumAddedAt[album.id] = max(albumAddedAt[album.id] ?? grant.createdAt, grant.createdAt)
        showsArtwork[album.id] = grant.showsArtwork
        var positions = trackPositionsByAlbumId[album.id] ?? [:]
        for (position, track) in album.tracks.enumerated() where positions[track.id] == nil {
          positions[track.id] = position
        }
        trackPositionsByAlbumId[album.id] = positions
      }

      var trackGrantsByAlbumId: [AlbumId: [TrackGrant]] = [:]
      for grant in trackGrants {
        guard case .track? = coverage.governingGrant(
          forTrack: grant.appleMusicTrackId,
          preferredAlbumId: grant.preferredAlbumId,
        ) else {
          continue
        }
        trackGrantsByAlbumId[grant.preferredAlbumId, default: []].append(grant)
      }
      let trackAlbumIds = trackGrantsByAlbumId.keys.sorted { lhs, rhs in
        let lhsDate = trackGrantsByAlbumId[lhs]!.map(\.createdAt).min()!
        let rhsDate = trackGrantsByAlbumId[rhs]!.map(\.createdAt).min()!
        return lhsDate == rhsDate ? lhs.rawValue < rhs.rawValue : lhsDate < rhsDate
      }
      for albumId in trackAlbumIds {
        let grants = trackGrantsByAlbumId[albumId]!
        let metadataGrant = grants.min(by: self.trackMetadataOrder)!
        let summary = metadataGrant.resolution.preferredAlbum
        let orderedGrants = grants.sorted(by: self.trackOutputOrder)
        let partialAlbum = ResolvedAlbum(
          id: summary.id,
          title: summary.title,
          artistName: summary.artistName,
          artistIds: summary.artistIds,
          artworkUrl: summary.artworkUrl,
          artwork: summary.artwork,
          trackCount: summary.trackCount,
          releaseDate: summary.releaseDate,
          releaseType: summary.releaseType,
          appleMusicUrl: summary.appleMusicUrl,
          tracks: orderedGrants.map(\.resolution.track),
        )
        var positions = trackPositionsByAlbumId[albumId] ?? [:]
        for grant in orderedGrants {
          positions[grant.appleMusicTrackId] = grant.resolution.catalogPosition
        }
        trackPositionsByAlbumId[albumId] = positions
        if let existing = albumsById[albumId] {
          albumsById[albumId] = self.mergingTracks(
            metadata: existing,
            supplemental: partialAlbum,
            positions: positions,
          )
        } else {
          albumOrder.append(albumId)
          albumsById[albumId] = partialAlbum
          showsArtwork[albumId] = metadataGrant.showsArtwork
        }
        let firstAddedAt = grants.map(\.createdAt).min()!
        albumAddedAt[albumId] = max(albumAddedAt[albumId] ?? firstAddedAt, firstAddedAt)
      }

      for grant in artistGrants {
        for album in grant.resolution!.albums {
          let governsMetadata: Bool = if case .artist(let governing)? = coverage
            .governingGrant(forAlbum: album.id) {
            governing.appleMusicArtistId == grant.appleMusicArtistId
          } else {
            false
          }
          var positions = trackPositionsByAlbumId[album.id] ?? [:]
          for (position, track) in album.tracks.enumerated()
            where governsMetadata || positions[track.id] == nil {
            positions[track.id] = position
          }
          trackPositionsByAlbumId[album.id] = positions
          if let existing = albumsById[album.id] {
            albumsById[album.id] = governsMetadata
              ? self.mergingTracks(
                metadata: album,
                supplemental: existing,
                positions: positions,
              )
              : self.mergingTracks(
                metadata: existing,
                supplemental: album,
                positions: positions,
              )
          } else {
            albumOrder.append(album.id)
            albumsById[album.id] = album
          }
          if governsMetadata {
            showsArtwork.removeValue(forKey: album.id)
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

    private static func deduplicatedTrackGrants(
      _ grants: [TrackGrant],
    ) -> [TrackGrant] {
      var deduplicated: [TrackGrant] = []
      var indexById: [TrackId: Int] = [:]
      for grant in grants {
        if let index = indexById[grant.appleMusicTrackId] {
          deduplicated[index] = grant
        } else {
          indexById[grant.appleMusicTrackId] = deduplicated.count
          deduplicated.append(grant)
        }
      }
      return deduplicated
    }

    private static func validate(
      albumGrants: [AlbumGrant],
      artistGrants: [ArtistGrant],
      trackGrants: [TrackGrant],
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
      for grant in trackGrants {
        do {
          try grant.resolution.validate(
            appleMusicTrackId: grant.appleMusicTrackId,
            preferredAlbumId: grant.preferredAlbumId,
          )
        } catch let error as ResolvedTrackGrant.ValidationError {
          throw CompilerError.invalidTrackResolution(error)
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

    private static func mergingTracks(
      metadata album: ResolvedAlbum,
      supplemental: ResolvedAlbum,
      positions: [TrackId: Int],
    ) -> ResolvedAlbum {
      var album = album
      var seenTrackIds = Set<TrackId>()
      album.tracks = (album.tracks + supplemental.tracks).filter {
        seenTrackIds.insert($0.id).inserted
      }.sorted { lhs, rhs in
        self.resolvedTrackOrder(lhs, rhs, positions: positions)
      }
      return album
    }

    private static func resolvedTrackOrder(
      _ lhs: ResolvedTrack,
      _ rhs: ResolvedTrack,
      positions: [TrackId: Int],
    ) -> Bool {
      let lhsPosition = positions[lhs.id] ?? .max
      let rhsPosition = positions[rhs.id] ?? .max
      if lhsPosition != rhsPosition {
        return lhsPosition < rhsPosition
      }
      let lhsDisc = lhs.discNumber ?? .max
      let rhsDisc = rhs.discNumber ?? .max
      if lhsDisc != rhsDisc {
        return lhsDisc < rhsDisc
      }
      let lhsTrack = lhs.trackNumber ?? .max
      let rhsTrack = rhs.trackNumber ?? .max
      if lhsTrack != rhsTrack {
        return lhsTrack < rhsTrack
      }
      return lhs.id.rawValue < rhs.id.rawValue
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
        discNumber: track.discNumber,
        trackNumber: track.trackNumber,
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

    private static func trackGrantOrder(_ lhs: TrackGrant, _ rhs: TrackGrant) -> Bool {
      if lhs.createdAt != rhs.createdAt {
        return lhs.createdAt < rhs.createdAt
      }
      if lhs.appleMusicTrackId != rhs.appleMusicTrackId {
        return lhs.appleMusicTrackId.rawValue < rhs.appleMusicTrackId.rawValue
      }
      if lhs.preferredAlbumId != rhs.preferredAlbumId {
        return lhs.preferredAlbumId.rawValue < rhs.preferredAlbumId.rawValue
      }
      return lhs.resolution.catalogPosition < rhs.resolution.catalogPosition
    }

    private static func trackMetadataOrder(_ lhs: TrackGrant, _ rhs: TrackGrant) -> Bool {
      if lhs.createdAt != rhs.createdAt {
        return lhs.createdAt < rhs.createdAt
      }
      return lhs.appleMusicTrackId.rawValue < rhs.appleMusicTrackId.rawValue
    }

    private static func trackOutputOrder(_ lhs: TrackGrant, _ rhs: TrackGrant) -> Bool {
      if lhs.resolution.catalogPosition != rhs.resolution.catalogPosition {
        return lhs.resolution.catalogPosition < rhs.resolution.catalogPosition
      }
      let lhsDisc = lhs.resolution.track.discNumber ?? .max
      let rhsDisc = rhs.resolution.track.discNumber ?? .max
      if lhsDisc != rhsDisc {
        return lhsDisc < rhsDisc
      }
      let lhsTrack = lhs.resolution.track.trackNumber ?? .max
      let rhsTrack = rhs.resolution.track.trackNumber ?? .max
      if lhsTrack != rhsTrack {
        return lhsTrack < rhsTrack
      }
      return lhs.appleMusicTrackId.rawValue < rhs.appleMusicTrackId.rawValue
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
