import DuetSQL
import Foundation

extension Music {
  enum PlaylistRepository {
    static func validatedName(_ rawName: String) -> String? {
      let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !name.isEmpty,
            name.count <= 100,
            name.rangeOfCharacter(from: .newlines) == nil else { return nil }
      return name
    }

    static func playlist(
      id: Playlist.Id,
      childId: Child.Id,
      in db: any DuetSQL.Client,
    ) async throws -> Playlist? {
      try await Playlist.query()
        .where(.id == id)
        .where(.childId == childId)
        .all(in: db)
        .first
    }

    static func playlists(
      for childId: Child.Id,
      in db: any DuetSQL.Client,
    ) async throws -> [Playlist] {
      try await Playlist.query()
        .where(.childId == childId)
        .orderBy(.createdAt, .asc)
        .all(in: db)
    }

    static func entries(
      for playlistId: Playlist.Id,
      in db: any DuetSQL.Client,
    ) async throws -> [PlaylistEntry] {
      try await PlaylistEntry.query()
        .where(.playlistId == playlistId)
        .orderBy(.position, .asc)
        .all(in: db)
    }

    static func rulesPlaylists(
      for childId: Child.Id,
      in db: any DuetSQL.Client,
    ) async throws -> [PlaylistRules.Playlist] {
      let playlists = try await self.playlists(for: childId, in: db)
      guard !playlists.isEmpty else { return [] }
      let entries = try await PlaylistEntry.query()
        .where(.playlistId |=| playlists.map(\.id))
        .orderBy(.position, .asc)
        .all(in: db)
      let entriesByPlaylistId = Dictionary(grouping: entries, by: \.playlistId)
      return playlists.map { playlist in
        self.rulesPlaylist(
          playlist,
          entries: entriesByPlaylistId[playlist.id] ?? [],
        )
      }
    }

    static func rulesPlaylist(
      _ playlist: Playlist,
      entries: [PlaylistEntry],
    ) -> PlaylistRules.Playlist {
      .init(
        id: playlist.id.rawValue,
        name: playlist.name,
        revision: playlist.revision,
        createdAt: playlist.createdAt,
        updatedAt: playlist.updatedAt,
        entries: entries.map { entry in
          .init(
            id: entry.id.rawValue,
            trackId: entry.appleMusicTrackId,
            preferredAlbumId: entry.preferredAlbumId,
          )
        },
      )
    }

    static func reconcileForPublication(
      childId: Child.Id,
      using index: PlaylistRules.EffectiveTrackIndex,
      at date: Date,
      in db: any DuetSQL.Client,
    ) async throws -> [PlaylistRules.Playlist] {
      var playlists = try await self.playlists(for: childId, in: db)
      guard !playlists.isEmpty else { return [] }
      let allEntries = try await PlaylistEntry.query()
        .where(.playlistId |=| playlists.map(\.id))
        .orderBy(.position, .asc)
        .all(in: db)
      var entriesByPlaylistId = Dictionary(grouping: allEntries, by: \.playlistId)

      for indexOfPlaylist in playlists.indices {
        let playlist = playlists[indexOfPlaylist]
        let entries = entriesByPlaylistId[playlist.id] ?? []
        let rulesEntries = entries.map { entry in
          PlaylistRules.Entry(
            id: entry.id.rawValue,
            trackId: entry.appleMusicTrackId,
            preferredAlbumId: entry.preferredAlbumId,
          )
        }
        let reconciliation = PlaylistRules.reconcile(entries: rulesEntries, using: index)
        guard !reconciliation.removedEntryIds.isEmpty else { continue }
        let removedIds = reconciliation.removedEntryIds.map(PlaylistEntry.Id.init(rawValue:))
        try await PlaylistEntry.query()
          .where(.id |=| removedIds)
          .delete(in: db)
        let retainedIds = Set(reconciliation.entries.map(\.entry.id))
        let retained = entries.filter { retainedIds.contains($0.id.rawValue) }
        entriesByPlaylistId[playlist.id] = try await self.setOrder(retained, in: db)
        playlists[indexOfPlaylist].revision += 1
        playlists[indexOfPlaylist].updatedAt = date
        try await db.update(playlists[indexOfPlaylist])
        playlists[indexOfPlaylist] = try await db.find(playlists[indexOfPlaylist].id)
      }

      return playlists.map { playlist in
        self.rulesPlaylist(
          playlist,
          entries: entriesByPlaylistId[playlist.id] ?? [],
        )
      }
    }

    static func setOrder(
      _ entries: [PlaylistEntry],
      in db: any DuetSQL.Client,
    ) async throws -> [PlaylistEntry] {
      guard !entries.isEmpty else { return [] }
      let offset = (entries.map(\.position).max() ?? 0) + entries.count + 1
      var shifted = entries
      for index in shifted.indices.reversed() {
        shifted[index].position += offset
        try await db.update(shifted[index])
      }
      for index in shifted.indices {
        shifted[index].position = index
        try await db.update(shifted[index])
      }
      return shifted
    }
  }
}
