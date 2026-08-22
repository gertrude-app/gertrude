import Dependencies
import DuetSQL
import MusicRoute
import PairQL

private func validatedPlaylistName(
  _ rawName: String,
  in ctx: MusicApp.InstallContext,
) throws -> String {
  guard let name = Music.PlaylistRepository.validatedName(rawName) else {
    throw ctx.error(
      "08530a94",
      .badRequest,
      "Music playlist name must be one line containing 1 through 100 characters",
    )
  }
  return name
}

private func playlistRuleError(
  _ error: Music.PlaylistRules.RuleError,
  in ctx: MusicApp.InstallContext,
) -> PqlError {
  switch error {
  case .invalidDuplicateResolution(let resolution):
    ctx.error(
      "f8e8fa4c",
      .badRequest,
      "Duplicate resolution `\(resolution.rawValue)` does not match the playlist source",
    )
  case .unauthorizedAlbum(let albumId):
    ctx.error(
      "36642b7a",
      .unauthorized,
      "Music album `\(albumId.rawValue)` is not approved for this child",
    )
  case .unauthorizedArtist(let artistId):
    ctx.error(
      "36642b7a",
      .unauthorized,
      "Music artist `\(artistId.rawValue)` is not approved for this child",
    )
  case .unauthorizedPlaylist(let playlistId):
    ctx.error(
      "36642b7a",
      .unauthorized,
      "Music playlist `\(playlistId)` is not available for this child",
    )
  case .unauthorizedTrack(let trackId, let albumId):
    ctx.error(
      "165a701e",
      .unauthorized,
      "Music track `\(trackId.rawValue)` is not approved from album `\(albumId.rawValue)`",
    )
  }
}

private func publishPlaylistSnapshot(
  childId: Child.Id,
  at date: Date,
  in db: any DuetSQL.Client,
) async throws -> MusicLibrarySnapshot {
  try await Music.LibrarySnapshotRepository.publish(
    childId: childId,
    generatedAt: date,
    in: db,
  ).payload
}

private func playlistIndex(
  childId: Child.Id,
  in db: any DuetSQL.Client,
) async throws -> Music.PlaylistRules.EffectiveTrackIndex {
  let content = try await Music.LibrarySnapshotRepository.catalogContent(
    for: childId,
    in: db,
  )
  let playlists = try await Music.PlaylistRepository.rulesPlaylists(
    for: childId,
    in: db,
  )
  return .init(
    albums: content.albums,
    artists: content.artists,
    playlists: playlists,
  )
}

private func additions(
  for source: MusicPlaylistSourceSelection,
  duplicateResolution: MusicPlaylistDuplicateResolution,
  playlist: Music.Playlist,
  entries: [Music.PlaylistEntry],
  using index: Music.PlaylistRules.EffectiveTrackIndex,
  in ctx: MusicApp.InstallContext,
) throws -> Music.PlaylistRules.AdditionPlan {
  do {
    return try Music.PlaylistRules.planAddition(
      selection: source,
      duplicateResolution: duplicateResolution,
      to: Music.PlaylistRepository.rulesPlaylist(playlist, entries: entries),
      using: index,
    )
  } catch let error as Music.PlaylistRules.RuleError {
    throw playlistRuleError(error, in: ctx)
  }
}

private func batchAdditions(
  for sources: [MusicPlaylistSourceSelection],
  duplicateResolution: MusicPlaylistBatchDuplicateResolution,
  playlist: Music.Playlist,
  entries: [Music.PlaylistEntry],
  using index: Music.PlaylistRules.EffectiveTrackIndex,
  in ctx: MusicApp.InstallContext,
) throws -> Music.PlaylistRules.BatchAdditionPlan {
  do {
    return try Music.PlaylistRules.planBatchAddition(
      selections: sources,
      duplicateResolution: duplicateResolution,
      to: Music.PlaylistRepository.rulesPlaylist(playlist, entries: entries),
      using: index,
    )
  } catch let error as Music.PlaylistRules.RuleError {
    throw playlistRuleError(error, in: ctx)
  }
}

private func createEntries(
  _ additions: [Music.PlaylistRules.EntryAddition],
  playlistId: Music.Playlist.Id,
  startingAt position: Int,
  createdAt: Date,
) -> [Music.PlaylistEntry] {
  additions.enumerated().map { offset, addition in
    Music.PlaylistEntry(
      playlistId: playlistId,
      position: position + offset,
      appleMusicTrackId: addition.trackId,
      preferredAlbumId: addition.preferredAlbumId,
      createdAt: createdAt,
    )
  }
}

extension CreateMusicPlaylist: Resolver {
  static func resolve(
    with input: Input,
    in ctx: MusicApp.InstallContext,
  ) async throws -> Output {
    try await requireMusicAccess(in: ctx)
    let name = try validatedPlaylistName(input.name, in: ctx)
    let now = get(dependency: \.date.now)
    return try await ctx.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: ctx.child.id, in: db)
      let playlist = Music.Playlist(
        childId: ctx.child.id,
        name: name,
        createdAt: now,
        updatedAt: now,
      )
      var plannedAdditions: [Music.PlaylistRules.EntryAddition] = []
      if let source = input.source {
        let index = try await playlistIndex(childId: ctx.child.id, in: db)
        let plan = try additions(
          for: source,
          duplicateResolution: .requestConfirmation,
          playlist: playlist,
          entries: [],
          using: index,
          in: ctx,
        )
        switch plan {
        case .append(let additions):
          plannedAdditions = additions
        case .confirmationRequired:
          throw ctx.error(
            "bce7f22d",
            .serverError,
            "An empty music playlist unexpectedly required duplicate confirmation",
          )
        }
      }
      try await db.create(playlist)
      let entries = createEntries(
        plannedAdditions,
        playlistId: playlist.id,
        startingAt: 0,
        createdAt: now,
      )
      if !entries.isEmpty {
        try await db.create(entries)
      }
      return try await .updated(publishPlaylistSnapshot(
        childId: ctx.child.id,
        at: now,
        in: db,
      ))
    }
  }
}

extension RenameMusicPlaylist: Resolver {
  static func resolve(
    with input: Input,
    in ctx: MusicApp.InstallContext,
  ) async throws -> Output {
    try await requireMusicAccess(in: ctx)
    let name = try validatedPlaylistName(input.name, in: ctx)
    let now = get(dependency: \.date.now)
    return try await ctx.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: ctx.child.id, in: db)
      guard var playlist = try await Music.PlaylistRepository.playlist(
        id: .init(rawValue: input.playlistId),
        childId: ctx.child.id,
        in: db,
      ), playlist.revision == input.expectedRevision else {
        return try await .conflict(publishPlaylistSnapshot(
          childId: ctx.child.id,
          at: now,
          in: db,
        ))
      }
      if playlist.name != name {
        playlist.name = name
        playlist.revision += 1
        playlist.updatedAt = now
        try await db.update(playlist)
      }
      return try await .updated(publishPlaylistSnapshot(
        childId: ctx.child.id,
        at: now,
        in: db,
      ))
    }
  }
}

extension DeleteMusicPlaylist: Resolver {
  static func resolve(
    with input: Input,
    in ctx: MusicApp.InstallContext,
  ) async throws -> Output {
    try await requireMusicAccess(in: ctx)
    let now = get(dependency: \.date.now)
    return try await ctx.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: ctx.child.id, in: db)
      guard let playlist = try await Music.PlaylistRepository.playlist(
        id: .init(rawValue: input.playlistId),
        childId: ctx.child.id,
        in: db,
      ), playlist.revision == input.expectedRevision else {
        return try await .conflict(publishPlaylistSnapshot(
          childId: ctx.child.id,
          at: now,
          in: db,
        ))
      }
      try await db.delete(playlist)
      return try await .updated(publishPlaylistSnapshot(
        childId: ctx.child.id,
        at: now,
        in: db,
      ))
    }
  }
}

extension AddToMusicPlaylist: Resolver {
  static func resolve(
    with input: Input,
    in ctx: MusicApp.InstallContext,
  ) async throws -> Output {
    try await requireMusicAccess(in: ctx)
    let now = get(dependency: \.date.now)
    return try await ctx.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: ctx.child.id, in: db)
      guard var playlist = try await Music.PlaylistRepository.playlist(
        id: .init(rawValue: input.playlistId),
        childId: ctx.child.id,
        in: db,
      ) else {
        return try await .conflict(publishPlaylistSnapshot(
          childId: ctx.child.id,
          at: now,
          in: db,
        ))
      }
      let entries = try await Music.PlaylistRepository.entries(for: playlist.id, in: db)
      let index = try await playlistIndex(childId: ctx.child.id, in: db)
      let plan = try additions(
        for: input.source,
        duplicateResolution: input.duplicateResolution,
        playlist: playlist,
        entries: entries,
        using: index,
        in: ctx,
      )
      switch plan {
      case .confirmationRequired(let confirmation):
        return try await .duplicateConfirmationRequired(
          snapshot: publishPlaylistSnapshot(
            childId: ctx.child.id,
            at: now,
            in: db,
          ),
          confirmation: confirmation,
        )
      case .append(let additions):
        let newEntries = createEntries(
          additions,
          playlistId: playlist.id,
          startingAt: entries.count,
          createdAt: now,
        )
        if !newEntries.isEmpty {
          try await db.create(newEntries)
          playlist.revision += 1
          playlist.updatedAt = now
          try await db.update(playlist)
        }
        return try await .updated(publishPlaylistSnapshot(
          childId: ctx.child.id,
          at: now,
          in: db,
        ))
      }
    }
  }
}

extension AddMusicToPlaylist: Resolver {
  static func resolve(
    with input: Input,
    in ctx: MusicApp.InstallContext,
  ) async throws -> Output {
    try await requireMusicAccess(in: ctx)
    let now = get(dependency: \.date.now)
    return try await ctx.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: ctx.child.id, in: db)
      guard var playlist = try await Music.PlaylistRepository.playlist(
        id: .init(rawValue: input.playlistId),
        childId: ctx.child.id,
        in: db,
      ) else {
        return try await .conflict(publishPlaylistSnapshot(
          childId: ctx.child.id,
          at: now,
          in: db,
        ))
      }
      let entries = try await Music.PlaylistRepository.entries(for: playlist.id, in: db)
      let index = try await playlistIndex(childId: ctx.child.id, in: db)
      let plan = try batchAdditions(
        for: input.sources,
        duplicateResolution: input.duplicateResolution,
        playlist: playlist,
        entries: entries,
        using: index,
        in: ctx,
      )
      switch plan {
      case .confirmationRequired(let confirmation):
        return try await .batchDuplicateConfirmationRequired(
          snapshot: publishPlaylistSnapshot(
            childId: ctx.child.id,
            at: now,
            in: db,
          ),
          confirmation: confirmation,
        )
      case .append(let additions):
        let newEntries = createEntries(
          additions,
          playlistId: playlist.id,
          startingAt: entries.count,
          createdAt: now,
        )
        if !newEntries.isEmpty {
          try await db.create(newEntries)
          playlist.revision += 1
          playlist.updatedAt = now
          try await db.update(playlist)
        }
        return try await .updated(publishPlaylistSnapshot(
          childId: ctx.child.id,
          at: now,
          in: db,
        ))
      }
    }
  }
}

extension RemoveMusicPlaylistEntry: Resolver {
  static func resolve(
    with input: Input,
    in ctx: MusicApp.InstallContext,
  ) async throws -> Output {
    try await requireMusicAccess(in: ctx)
    let now = get(dependency: \.date.now)
    return try await ctx.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: ctx.child.id, in: db)
      guard var playlist = try await Music.PlaylistRepository.playlist(
        id: .init(rawValue: input.playlistId),
        childId: ctx.child.id,
        in: db,
      ), playlist.revision == input.expectedRevision else {
        return try await .conflict(publishPlaylistSnapshot(
          childId: ctx.child.id,
          at: now,
          in: db,
        ))
      }
      let entries = try await Music.PlaylistRepository.entries(for: playlist.id, in: db)
      guard let removed = entries.first(where: { $0.id.rawValue == input.entryId }) else {
        return try await .conflict(publishPlaylistSnapshot(
          childId: ctx.child.id,
          at: now,
          in: db,
        ))
      }
      try await db.delete(removed)
      _ = try await Music.PlaylistRepository.setOrder(
        entries.filter { $0.id != removed.id },
        in: db,
      )
      playlist.revision += 1
      playlist.updatedAt = now
      try await db.update(playlist)
      return try await .updated(publishPlaylistSnapshot(
        childId: ctx.child.id,
        at: now,
        in: db,
      ))
    }
  }
}

extension ReorderMusicPlaylistEntries: Resolver {
  static func resolve(
    with input: Input,
    in ctx: MusicApp.InstallContext,
  ) async throws -> Output {
    try await requireMusicAccess(in: ctx)
    let now = get(dependency: \.date.now)
    return try await ctx.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: ctx.child.id, in: db)
      guard var playlist = try await Music.PlaylistRepository.playlist(
        id: .init(rawValue: input.playlistId),
        childId: ctx.child.id,
        in: db,
      ), playlist.revision == input.expectedRevision else {
        return try await .conflict(publishPlaylistSnapshot(
          childId: ctx.child.id,
          at: now,
          in: db,
        ))
      }
      let entries = try await Music.PlaylistRepository.entries(for: playlist.id, in: db)
      let entriesById = Dictionary(uniqueKeysWithValues: entries.map { ($0.id.rawValue, $0) })
      guard input.entryIds.count == entries.count,
            Set(input.entryIds).count == input.entryIds.count,
            input.entryIds.allSatisfy({ entriesById[$0] != nil }) else {
        return try await .conflict(publishPlaylistSnapshot(
          childId: ctx.child.id,
          at: now,
          in: db,
        ))
      }
      let reordered = input.entryIds.compactMap { entriesById[$0] }
      if reordered.map(\.id) != entries.map(\.id) {
        _ = try await Music.PlaylistRepository.setOrder(reordered, in: db)
        playlist.revision += 1
        playlist.updatedAt = now
        try await db.update(playlist)
      }
      return try await .updated(publishPlaylistSnapshot(
        childId: ctx.child.id,
        at: now,
        in: db,
      ))
    }
  }
}
