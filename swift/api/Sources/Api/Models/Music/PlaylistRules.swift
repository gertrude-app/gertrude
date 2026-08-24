import Foundation
import MusicRoute

extension Music {
  enum PlaylistRules {
    struct Entry: Equatable, Sendable {
      var id: UUID
      var trackId: TrackId
      var preferredAlbumId: AlbumId

      init(id: UUID, trackId: TrackId, preferredAlbumId: AlbumId) {
        self.id = id
        self.trackId = trackId
        self.preferredAlbumId = preferredAlbumId
      }
    }

    struct Playlist: Equatable, Sendable {
      var id: UUID
      var name: String
      var revision: Int64
      var createdAt: Date
      var updatedAt: Date
      var entries: [Entry]

      init(
        id: UUID,
        name: String,
        revision: Int64,
        createdAt: Date,
        updatedAt: Date,
        entries: [Entry],
      ) {
        self.id = id
        self.name = name
        self.revision = revision
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.entries = entries
      }
    }

    struct EntryAddition: Equatable, Sendable {
      var trackId: TrackId
      var preferredAlbumId: AlbumId

      init(trackId: TrackId, preferredAlbumId: AlbumId) {
        self.trackId = trackId
        self.preferredAlbumId = preferredAlbumId
      }
    }

    struct ResolvedEntry: Equatable, Sendable {
      var entry: Entry
      var track: MusicLibrarySnapshot.Track
    }

    struct Reconciliation: Equatable, Sendable {
      var entries: [ResolvedEntry]
      var removedEntryIds: [UUID]
    }

    enum AdditionPlan: Equatable, Sendable {
      case append([EntryAddition])
      case confirmationRequired(MusicPlaylistDuplicateConfirmation)
    }

    enum BatchAdditionPlan: Equatable, Sendable {
      case append([EntryAddition])
      case confirmationRequired(MusicPlaylistBatchDuplicateConfirmation)
    }

    private struct AdditionAnalysis {
      var allAdditions: [EntryAddition]
      var newAdditions: [EntryAddition]
      var duplicates: [MusicPlaylistDuplicate]
    }

    enum RuleError: Error, Equatable {
      case invalidDuplicateResolution(MusicPlaylistDuplicateResolution)
      case unauthorizedAlbum(AlbumId)
      case unauthorizedArtist(ArtistId)
      case unauthorizedPlaylist(UUID)
      case unauthorizedTrack(trackId: TrackId, albumId: AlbumId)
    }

    struct EffectiveTrackIndex: Equatable, Sendable {
      struct Candidate: Equatable, Sendable {
        var albumId: AlbumId
        var track: MusicLibrarySnapshot.Track
      }

      var albums: [MusicLibrarySnapshot.Album]
      private var candidatesByAlbumId: [AlbumId: [Candidate]]
      private var candidatesByArtistId: [ArtistId: [Candidate]]
      private var candidatesByPlaylistId: [UUID: [Candidate]]
      private var candidatesByTrackId: [TrackId: [Candidate]]

      init(
        albums: [MusicLibrarySnapshot.Album],
        artists: [MusicLibrarySnapshot.Artist] = [],
        playlists: [Playlist] = [],
      ) {
        var indexedAlbums: [MusicLibrarySnapshot.Album] = []
        var candidatesByAlbumId: [AlbumId: [Candidate]] = [:]
        var candidatesByTrackId: [TrackId: [Candidate]] = [:]
        var seenAlbumIds = Set<AlbumId>()

        for album in albums {
          let albumId = AlbumId(rawValue: album.id)
          guard !album.id.isEmpty, seenAlbumIds.insert(albumId).inserted else { continue }
          indexedAlbums.append(album)
          var candidates: [Candidate] = []
          var seenTrackIds = Set<TrackId>()
          for track in album.tracks {
            let trackId = TrackId(rawValue: track.id)
            guard !track.id.isEmpty,
                  track.albumId == album.id,
                  seenTrackIds.insert(trackId).inserted else { continue }
            let candidate = Candidate(albumId: albumId, track: track)
            candidates.append(candidate)
            candidatesByTrackId[trackId, default: []].append(candidate)
          }
          candidatesByAlbumId[albumId] = candidates
        }

        let indexedAlbumsById = Dictionary(
          uniqueKeysWithValues: indexedAlbums.map { (AlbumId(rawValue: $0.id), $0) },
        )
        var candidatesByArtistId: [ArtistId: [Candidate]] = [:]
        var seenArtistIds = Set<ArtistId>()
        for artist in artists {
          let artistId = ArtistId(rawValue: artist.id)
          guard !artist.id.isEmpty, seenArtistIds.insert(artistId).inserted else { continue }
          let releases = artist.releaseAlbumIds.enumerated().compactMap { offset, rawAlbumId in
            let albumId = AlbumId(rawValue: rawAlbumId)
            return indexedAlbumsById[albumId].map { (offset, albumId, $0) }
          }.sorted { lhs, rhs in
            let lhsDate = lhs.2.releaseDate ?? ""
            let rhsDate = rhs.2.releaseDate ?? ""
            return lhsDate == rhsDate ? lhs.0 < rhs.0 : lhsDate > rhsDate
          }
          var candidates: [Candidate] = []
          var seenTrackIds = Set<TrackId>()
          for (_, albumId, _) in releases {
            for candidate in candidatesByAlbumId[albumId] ?? [] {
              let trackId = TrackId(rawValue: candidate.track.id)
              if seenTrackIds.insert(trackId).inserted {
                candidates.append(candidate)
              }
            }
          }
          candidatesByArtistId[artistId] = candidates
        }

        var candidatesByPlaylistId: [UUID: [Candidate]] = [:]
        var seenPlaylistIds = Set<UUID>()
        for playlist in playlists {
          guard seenPlaylistIds.insert(playlist.id).inserted else { continue }
          candidatesByPlaylistId[playlist.id] = playlist.entries.compactMap { entry in
            guard let candidates = candidatesByTrackId[entry.trackId] else { return nil }
            return candidates.first(where: { $0.albumId == entry.preferredAlbumId })
              ?? candidates.first
          }
        }

        self.albums = indexedAlbums
        self.candidatesByAlbumId = candidatesByAlbumId
        self.candidatesByArtistId = candidatesByArtistId
        self.candidatesByPlaylistId = candidatesByPlaylistId
        self.candidatesByTrackId = candidatesByTrackId
      }

      func candidates(
        for selection: MusicPlaylistSourceSelection,
      ) throws -> [Candidate] {
        switch selection {
        case .track(let rawTrackId, let rawAlbumId):
          let trackId = TrackId(rawValue: rawTrackId)
          let albumId = AlbumId(rawValue: rawAlbumId)
          guard let candidate = self.candidatesByAlbumId[albumId]?
            .first(where: { $0.track.id == rawTrackId }) else {
            throw RuleError.unauthorizedTrack(trackId: trackId, albumId: albumId)
          }
          return [candidate]
        case .album(let rawAlbumId):
          let albumId = AlbumId(rawValue: rawAlbumId)
          guard let candidates = self.candidatesByAlbumId[albumId] else {
            throw RuleError.unauthorizedAlbum(albumId)
          }
          return candidates
        case .artist(let rawArtistId):
          let artistId = ArtistId(rawValue: rawArtistId)
          guard let candidates = self.candidatesByArtistId[artistId] else {
            throw RuleError.unauthorizedArtist(artistId)
          }
          return candidates
        case .playlist(let playlistId):
          guard let candidates = self.candidatesByPlaylistId[playlistId] else {
            throw RuleError.unauthorizedPlaylist(playlistId)
          }
          return candidates
        }
      }

      func candidate(for entry: Entry) -> Candidate? {
        guard let candidates = self.candidatesByTrackId[entry.trackId] else { return nil }
        return candidates.first(where: { $0.albumId == entry.preferredAlbumId })
          ?? candidates.first
      }
    }

    static func planAddition(
      selection: MusicPlaylistSourceSelection,
      duplicateResolution: MusicPlaylistDuplicateResolution,
      to playlist: Playlist,
      using index: EffectiveTrackIndex,
    ) throws -> AdditionPlan {
      try self.validate(duplicateResolution, for: selection)
      let candidates = try index.candidates(for: selection)
      let analysis = self.analyze(candidates, for: playlist, using: index)

      if duplicateResolution == .requestConfirmation, !analysis.duplicates.isEmpty {
        let confirmation: MusicPlaylistDuplicateConfirmation = switch selection {
        case .track:
          .track(playlistId: playlist.id, duplicate: analysis.duplicates[0])
        case .album(let albumId):
          .album(
            playlistId: playlist.id,
            albumId: albumId,
            duplicates: analysis.duplicates,
          )
        case .artist(let artistId):
          .artist(
            playlistId: playlist.id,
            artistId: artistId,
            duplicates: analysis.duplicates,
          )
        case .playlist(let sourcePlaylistId):
          .playlist(
            playlistId: playlist.id,
            sourcePlaylistId: sourcePlaylistId,
            duplicates: analysis.duplicates,
          )
        }
        return .confirmationRequired(confirmation)
      }

      let additions = switch duplicateResolution {
      case .addOnlyNew:
        analysis.newAdditions
      case .requestConfirmation, .addAgain, .addAll:
        analysis.allAdditions
      }
      return .append(additions)
    }

    static func planBatchAddition(
      selections: [MusicPlaylistSourceSelection],
      duplicateResolution: MusicPlaylistBatchDuplicateResolution,
      to playlist: Playlist,
      using index: EffectiveTrackIndex,
    ) throws -> BatchAdditionPlan {
      var candidates: [EffectiveTrackIndex.Candidate] = []
      var seenTrackIDs = Set<TrackId>()
      for selection in selections {
        for candidate in try index.candidates(for: selection) {
          let trackID = TrackId(rawValue: candidate.track.id)
          if seenTrackIDs.insert(trackID).inserted {
            candidates.append(candidate)
          }
        }
      }

      let analysis = self.analyze(candidates, for: playlist, using: index)

      if duplicateResolution == .requestConfirmation, !analysis.duplicates.isEmpty {
        return .confirmationRequired(.init(
          playlistId: playlist.id,
          duplicates: analysis.duplicates,
        ))
      }

      let additions = switch duplicateResolution {
      case .addOnlyNew:
        analysis.newAdditions
      case .requestConfirmation, .addAll:
        analysis.allAdditions
      }
      return .append(additions)
    }

    private static func analyze(
      _ candidates: [EffectiveTrackIndex.Candidate],
      for playlist: Playlist,
      using index: EffectiveTrackIndex,
    ) -> AdditionAnalysis {
      let reconciliation = self.reconcile(entries: playlist.entries, using: index)
      var existingCounts: [TrackId: Int] = [:]
      for resolved in reconciliation.entries {
        existingCounts[resolved.entry.trackId, default: 0] += 1
      }

      var allAdditions: [EntryAddition] = []
      var newAdditions: [EntryAddition] = []
      var duplicates: [MusicPlaylistDuplicate] = []
      for candidate in candidates {
        let trackId = TrackId(rawValue: candidate.track.id)
        let addition = EntryAddition(
          trackId: trackId,
          preferredAlbumId: candidate.albumId,
        )
        allAdditions.append(addition)
        if let existingCount = existingCounts[trackId] {
          duplicates.append(.init(
            trackId: candidate.track.id,
            title: candidate.track.title,
            existingCount: existingCount,
          ))
        } else {
          newAdditions.append(addition)
        }
      }
      return .init(
        allAdditions: allAdditions,
        newAdditions: newAdditions,
        duplicates: duplicates,
      )
    }

    static func reconcile(
      entries: [Entry],
      using index: EffectiveTrackIndex,
    ) -> Reconciliation {
      var resolvedEntries: [ResolvedEntry] = []
      var removedEntryIds: [UUID] = []
      for entry in entries {
        guard let candidate = index.candidate(for: entry) else {
          removedEntryIds.append(entry.id)
          continue
        }
        resolvedEntries.append(.init(entry: entry, track: candidate.track))
      }
      return .init(entries: resolvedEntries, removedEntryIds: removedEntryIds)
    }

    static func compile(
      playlists: [Playlist],
      using index: EffectiveTrackIndex,
    ) -> [MusicLibrarySnapshot.Playlist] {
      playlists.sorted(by: self.playlistOrder).map { playlist in
        let reconciliation = self.reconcile(entries: playlist.entries, using: index)
        return .init(
          id: playlist.id,
          name: playlist.name,
          revision: playlist.revision,
          createdAt: playlist.createdAt,
          updatedAt: playlist.updatedAt,
          entries: reconciliation.entries.map { resolved in
            .init(id: resolved.entry.id, track: resolved.track)
          },
        )
      }
    }

    private static func validate(
      _ resolution: MusicPlaylistDuplicateResolution,
      for selection: MusicPlaylistSourceSelection,
    ) throws {
      switch (selection, resolution) {
      case (_, .requestConfirmation),
           (.track, .addAgain),
           (.album, .addAll),
           (.album, .addOnlyNew),
           (.artist, .addAll),
           (.artist, .addOnlyNew),
           (.playlist, .addAll),
           (.playlist, .addOnlyNew):
        return
      case (.track, .addAll),
           (.track, .addOnlyNew),
           (.album, .addAgain),
           (.artist, .addAgain),
           (.playlist, .addAgain):
        throw RuleError.invalidDuplicateResolution(resolution)
      }
    }

    private static func playlistOrder(_ lhs: Playlist, _ rhs: Playlist) -> Bool {
      if lhs.createdAt != rhs.createdAt {
        return lhs.createdAt < rhs.createdAt
      }
      return lhs.id.uuidString < rhs.id.uuidString
    }
  }
}
