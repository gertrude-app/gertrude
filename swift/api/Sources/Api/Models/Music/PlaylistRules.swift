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

    enum RuleError: Error, Equatable {
      case unauthorizedAlbum(AlbumId)
      case unauthorizedTrack(trackId: TrackId, albumId: AlbumId)
      case invalidDuplicateResolution(MusicPlaylistDuplicateResolution)
    }

    struct EffectiveTrackIndex: Equatable, Sendable {
      struct Candidate: Equatable, Sendable {
        var albumId: AlbumId
        var track: MusicLibrarySnapshot.Track
      }

      var albums: [MusicLibrarySnapshot.Album]
      private var candidatesByAlbumId: [AlbumId: [Candidate]]
      private var candidatesByTrackId: [TrackId: [Candidate]]

      init(albums: [MusicLibrarySnapshot.Album]) {
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

        self.albums = indexedAlbums
        self.candidatesByAlbumId = candidatesByAlbumId
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
      let reconciliation = self.reconcile(entries: playlist.entries, using: index)
      var existingCounts: [TrackId: Int] = [:]
      for resolved in reconciliation.entries {
        existingCounts[resolved.entry.trackId, default: 0] += 1
      }
      let duplicates = candidates.compactMap { candidate -> MusicPlaylistDuplicate? in
        let trackId = TrackId(rawValue: candidate.track.id)
        guard let existingCount = existingCounts[trackId] else { return nil }
        return .init(
          trackId: candidate.track.id,
          title: candidate.track.title,
          existingCount: existingCount,
        )
      }

      if duplicateResolution == .requestConfirmation, !duplicates.isEmpty {
        let confirmation: MusicPlaylistDuplicateConfirmation = switch selection {
        case .track:
          .track(playlistId: playlist.id, duplicate: duplicates[0])
        case .album(let albumId):
          .album(
            playlistId: playlist.id,
            albumId: albumId,
            duplicates: duplicates,
          )
        }
        return .confirmationRequired(confirmation)
      }

      let candidatesToAppend: [EffectiveTrackIndex.Candidate] = switch duplicateResolution {
      case .addOnlyNew:
        candidates.filter {
          existingCounts[TrackId(rawValue: $0.track.id)] == nil
        }
      case .requestConfirmation, .addAgain, .addAll:
        candidates
      }
      return .append(candidatesToAppend.map { candidate in
        EntryAddition(
          trackId: TrackId(rawValue: candidate.track.id),
          preferredAlbumId: candidate.albumId,
        )
      })
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

      let reconciliation = self.reconcile(entries: playlist.entries, using: index)
      var existingCounts: [TrackId: Int] = [:]
      for resolved in reconciliation.entries {
        existingCounts[resolved.entry.trackId, default: 0] += 1
      }
      let duplicates = candidates.compactMap { candidate -> MusicPlaylistDuplicate? in
        let trackID = TrackId(rawValue: candidate.track.id)
        guard let existingCount = existingCounts[trackID] else { return nil }
        return .init(
          trackId: candidate.track.id,
          title: candidate.track.title,
          existingCount: existingCount,
        )
      }

      if duplicateResolution == .requestConfirmation, !duplicates.isEmpty {
        return .confirmationRequired(.init(
          playlistId: playlist.id,
          duplicates: duplicates,
        ))
      }

      let candidatesToAppend: [EffectiveTrackIndex.Candidate] = switch duplicateResolution {
      case .addOnlyNew:
        candidates.filter {
          existingCounts[TrackId(rawValue: $0.track.id)] == nil
        }
      case .requestConfirmation, .addAll:
        candidates
      }
      return .append(candidatesToAppend.map { candidate in
        EntryAddition(
          trackId: TrackId(rawValue: candidate.track.id),
          preferredAlbumId: candidate.albumId,
        )
      })
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
           (.album, .addOnlyNew):
        return
      case (.track, .addAll),
           (.track, .addOnlyNew),
           (.album, .addAgain):
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
