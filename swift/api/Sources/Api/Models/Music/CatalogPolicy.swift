extension Music {
  enum CatalogPolicy {
    struct ArtistGrant: Equatable, Sendable {
      var appleMusicArtistId: ArtistId
      var resolution: ResolvedArtist

      init(
        appleMusicArtistId: ArtistId,
        resolution: ResolvedArtist,
      ) {
        self.appleMusicArtistId = appleMusicArtistId
        self.resolution = resolution
      }
    }

    struct AlbumGrant: Equatable, Sendable {
      var appleMusicAlbumId: AlbumId
      var resolution: ResolvedAlbum

      init(
        appleMusicAlbumId: AlbumId,
        resolution: ResolvedAlbum,
      ) {
        self.appleMusicAlbumId = appleMusicAlbumId
        self.resolution = resolution
      }
    }

    struct TrackGrant: Equatable, Sendable {
      var appleMusicTrackId: TrackId
      var preferredAlbumId: AlbumId
      var resolution: ResolvedTrackGrant

      init(
        appleMusicTrackId: TrackId,
        preferredAlbumId: AlbumId,
        resolution: ResolvedTrackGrant,
      ) {
        self.appleMusicTrackId = appleMusicTrackId
        self.preferredAlbumId = preferredAlbumId
        self.resolution = resolution
      }
    }

    enum GoverningGrant: Equatable, Sendable {
      case artist(ArtistGrant)
      case album(AlbumGrant)
      case track(TrackGrant)
    }

    struct CoveredDirectGrants: Equatable, Sendable {
      var albumIds: Set<AlbumId>
      var trackIds: Set<TrackId>
    }

    enum AlbumSelectionPlan: Equatable, Sendable {
      case removeDirectAuthorization
      case replaceWithTrackGrants([ResolvedTrackGrant])
      case replaceWithAlbumGrant(ResolvedAlbum)
      case coveredByArtist(ArtistGrant)
    }

    enum AlbumSelectionError: Error, Equatable, Sendable {
      case unknownTrackIds([TrackId])
    }

    enum ValidationError: Error, Equatable, Sendable {
      case artistResolutionIdMismatch(expected: ArtistId, actual: ArtistId)
      case albumResolutionIdMismatch(expected: AlbumId, actual: AlbumId)
      case trackAlbumIdMismatch(track: TrackId, expected: AlbumId, actual: AlbumId)
      case invalidTrackResolution(ResolvedTrackGrant.ValidationError)
      case duplicateArtistGrant(ArtistId)
      case duplicateAlbumGrant(AlbumId)
      case duplicateTrackGrant(TrackId)
    }

    struct CoverageIndex: Sendable {
      private struct ArtistCoverage: Sendable {
        var albumIds: Set<AlbumId>
        var trackIds: Set<TrackId>
      }

      private var artistGrantsById: [ArtistId: ArtistGrant]
      private var albumGrantsById: [AlbumId: AlbumGrant]
      private var trackGrantsById: [TrackId: TrackGrant]
      private var artistCoverageById: [ArtistId: ArtistCoverage]
      private var artistIdsByAlbumId: [AlbumId: [ArtistId]]
      private var artistIdsByTrackId: [TrackId: [ArtistId]]
      private var albumIdsByTrackId: [TrackId: [AlbumId]]
      private var trackIdsByPreferredAlbumId: [AlbumId: [TrackId]]

      init(
        artistGrants: [ArtistGrant] = [],
        albumGrants: [AlbumGrant] = [],
        trackGrants: [TrackGrant] = [],
      ) throws {
        var artistGrantsById: [ArtistId: ArtistGrant] = [:]
        var albumGrantsById: [AlbumId: AlbumGrant] = [:]
        var trackGrantsById: [TrackId: TrackGrant] = [:]
        var artistCoverageById: [ArtistId: ArtistCoverage] = [:]
        var artistIdsByAlbumId: [AlbumId: [ArtistId]] = [:]
        var artistIdsByTrackId: [TrackId: [ArtistId]] = [:]
        var albumIdsByTrackId: [TrackId: [AlbumId]] = [:]
        var trackIdsByPreferredAlbumId: [AlbumId: [TrackId]] = [:]

        for grant in artistGrants.sorted(by: Self.artistGrantOrder) {
          guard artistGrantsById[grant.appleMusicArtistId] == nil else {
            throw ValidationError.duplicateArtistGrant(grant.appleMusicArtistId)
          }
          let resolution = grant.resolution
          guard resolution.id == grant.appleMusicArtistId else {
            throw ValidationError.artistResolutionIdMismatch(
              expected: grant.appleMusicArtistId,
              actual: resolution.id,
            )
          }
          let coverage = try Self.coverage(for: resolution)
          artistGrantsById[grant.appleMusicArtistId] = grant
          artistCoverageById[grant.appleMusicArtistId] = coverage
          for albumId in coverage.albumIds {
            artistIdsByAlbumId[albumId, default: []].append(grant.appleMusicArtistId)
          }
          for trackId in coverage.trackIds {
            artistIdsByTrackId[trackId, default: []].append(grant.appleMusicArtistId)
          }
        }

        for grant in albumGrants.sorted(by: Self.albumGrantOrder) {
          guard albumGrantsById[grant.appleMusicAlbumId] == nil else {
            throw ValidationError.duplicateAlbumGrant(grant.appleMusicAlbumId)
          }
          let resolution = grant.resolution
          guard resolution.id == grant.appleMusicAlbumId else {
            throw ValidationError.albumResolutionIdMismatch(
              expected: grant.appleMusicAlbumId,
              actual: resolution.id,
            )
          }
          let trackIds = try Self.trackIds(in: resolution)
          albumGrantsById[grant.appleMusicAlbumId] = grant
          for trackId in trackIds {
            albumIdsByTrackId[trackId, default: []].append(grant.appleMusicAlbumId)
          }
        }

        for grant in trackGrants.sorted(by: Self.trackGrantOrder) {
          guard trackGrantsById[grant.appleMusicTrackId] == nil else {
            throw ValidationError.duplicateTrackGrant(grant.appleMusicTrackId)
          }
          do {
            try grant.resolution.validate(
              appleMusicTrackId: grant.appleMusicTrackId,
              preferredAlbumId: grant.preferredAlbumId,
            )
          } catch let error as ResolvedTrackGrant.ValidationError {
            throw ValidationError.invalidTrackResolution(error)
          }
          trackGrantsById[grant.appleMusicTrackId] = grant
          trackIdsByPreferredAlbumId[grant.preferredAlbumId, default: []]
            .append(grant.appleMusicTrackId)
        }

        self.artistGrantsById = artistGrantsById
        self.albumGrantsById = albumGrantsById
        self.trackGrantsById = trackGrantsById
        self.artistCoverageById = artistCoverageById
        self.artistIdsByAlbumId = artistIdsByAlbumId
        self.artistIdsByTrackId = artistIdsByTrackId
        self.albumIdsByTrackId = albumIdsByTrackId
        self.trackIdsByPreferredAlbumId = trackIdsByPreferredAlbumId
      }

      func governingGrant(forAlbum albumId: AlbumId) -> GoverningGrant? {
        if
          let artistId = self.artistIdsByAlbumId[albumId]?.first,
          let grant = self.artistGrantsById[artistId] {
          return .artist(grant)
        }
        return self.albumGrantsById[albumId].map(GoverningGrant.album)
      }

      func governingGrant(
        forTrack trackId: TrackId,
        preferredAlbumId: AlbumId? = nil,
      ) -> GoverningGrant? {
        if let artistIds = self.artistIdsByTrackId[trackId] {
          if
            let preferredAlbumId,
            let artistId = artistIds.first(where: {
              self.artistCoverageById[$0]?.albumIds.contains(preferredAlbumId) == true
            }),
            let grant = self.artistGrantsById[artistId] {
            return .artist(grant)
          }
          if let artistId = artistIds.first, let grant = self.artistGrantsById[artistId] {
            return .artist(grant)
          }
        }
        if let albumIds = self.albumIdsByTrackId[trackId] {
          if
            let preferredAlbumId,
            albumIds.contains(preferredAlbumId),
            let grant = self.albumGrantsById[preferredAlbumId] {
            return .album(grant)
          }
          if let albumId = albumIds.first, let grant = self.albumGrantsById[albumId] {
            return .album(grant)
          }
        }
        return self.trackGrantsById[trackId].map(GoverningGrant.track)
      }

      func directTrackGrants(preferredAlbumId: AlbumId) -> [TrackGrant] {
        self.trackIdsByPreferredAlbumId[preferredAlbumId, default: []].compactMap {
          self.trackGrantsById[$0]
        }
      }

      func directGrantsCovered(
        by artist: ResolvedArtist,
      ) throws -> CoveredDirectGrants {
        let coverage = try Self.coverage(for: artist)
        return .init(
          albumIds: coverage.albumIds.intersection(self.albumGrantsById.keys),
          trackIds: coverage.trackIds.intersection(self.trackGrantsById.keys),
        )
      }

      func directTrackIdsCovered(
        by album: ResolvedAlbum,
      ) throws -> Set<TrackId> {
        try Self.trackIds(in: album).intersection(self.trackGrantsById.keys)
      }

      func planAlbumSelection(
        for album: ResolvedAlbum,
        selectedTrackIds: [TrackId],
      ) throws -> AlbumSelectionPlan {
        let catalogTrackIds = try Self.trackIds(in: album)
        if case .artist(let grant)? = self.governingGrant(forAlbum: album.id) {
          return .coveredByArtist(grant)
        }

        let selectedTrackIds = Set(selectedTrackIds)
        let unknownTrackIds = selectedTrackIds
          .subtracting(catalogTrackIds)
          .sorted { $0.rawValue < $1.rawValue }
        guard unknownTrackIds.isEmpty else {
          throw AlbumSelectionError.unknownTrackIds(unknownTrackIds)
        }
        guard !selectedTrackIds.isEmpty else {
          return .removeDirectAuthorization
        }
        guard selectedTrackIds != catalogTrackIds else {
          return .replaceWithAlbumGrant(album)
        }

        return .replaceWithTrackGrants(album.tracks.enumerated().compactMap { position, track in
          guard selectedTrackIds.contains(track.id) else { return nil }
          return album.trackGrant(at: position)
        })
      }

      private static func coverage(
        for artist: ResolvedArtist,
      ) throws -> ArtistCoverage {
        var albumIds = Set<AlbumId>()
        var trackIds = Set<TrackId>()
        for album in artist.albums {
          albumIds.insert(album.id)
          try trackIds.formUnion(self.trackIds(in: album))
        }
        return .init(albumIds: albumIds, trackIds: trackIds)
      }

      private static func trackIds(
        in album: ResolvedAlbum,
      ) throws -> Set<TrackId> {
        var trackIds = Set<TrackId>()
        for track in album.tracks {
          guard track.albumId == album.id else {
            throw ValidationError.trackAlbumIdMismatch(
              track: track.id,
              expected: album.id,
              actual: track.albumId,
            )
          }
          trackIds.insert(track.id)
        }
        return trackIds
      }

      private static func artistGrantOrder(_ lhs: ArtistGrant, _ rhs: ArtistGrant) -> Bool {
        lhs.appleMusicArtistId.rawValue < rhs.appleMusicArtistId.rawValue
      }

      private static func albumGrantOrder(_ lhs: AlbumGrant, _ rhs: AlbumGrant) -> Bool {
        lhs.appleMusicAlbumId.rawValue < rhs.appleMusicAlbumId.rawValue
      }

      private static func trackGrantOrder(_ lhs: TrackGrant, _ rhs: TrackGrant) -> Bool {
        if lhs.preferredAlbumId != rhs.preferredAlbumId {
          return lhs.preferredAlbumId.rawValue < rhs.preferredAlbumId.rawValue
        }
        if lhs.resolution.catalogPosition != rhs.resolution.catalogPosition {
          return lhs.resolution.catalogPosition < rhs.resolution.catalogPosition
        }
        return lhs.appleMusicTrackId.rawValue < rhs.appleMusicTrackId.rawValue
      }
    }
  }
}
