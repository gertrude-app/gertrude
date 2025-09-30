import SharingGRDB

func createDatabaseTriggers(_ db: Database) throws {
  try episodeLastPlayedAt(db)
  try episodeCompletedAt(db)
  try dispatchNowPlayingUpdates(db)
  try touchUpdatedAtCols(db)
}

/// mark episode complete when progress within 45 sec of duration
private func episodeCompletedAt(_ db: Database) throws {
  try Episode
    .createTemporaryTrigger(after: .update {
      $0.progress
    } forEachRow: { _, new in
      Episode
        .find(new.id)
        .update { $0.completedAt = #sql("datetime('subsec')") }
    } when: { _, new in
      new.completedAt == nil
        && new.duration != nil
        && #sql("\(new.duration) - \(new.progress) <= 45")
    })
    .execute(db)
}

/// every time we touch episode.progress, set lastPlayedAt to now
private func episodeLastPlayedAt(_ db: Database) throws {
  try Episode
    .createTemporaryTrigger(after: .update {
      $0.progress
    } forEachRow: { _, new in
      Episode
        .find(new.id)
        .update { $0.lastPlayedAt = #sql("datetime('subsec')") }
    })
    .execute(db)
}

/// observe special nowPlaying misc row, call swift callback
private func dispatchNowPlayingUpdates(_ db: Database) throws {
  try Misc
    .createTemporaryTrigger(after: .update {
      ($0.value, $0.rowId)
    } forEachRow: {
      #sql("SELECT nowPlayingUpdate(\($0.rowId), \($0.value), \($1.rowId), \($1.value))")
    } when: { old, _ in
      old.id == Misc.ID.nowPlaying
    })
    .execute(db)
  try Misc
    .createTemporaryTrigger(after: .delete {
      #sql("SELECT nowPlayingUpdate(\($0.rowId), \($0.value), NULL, NULL)")
    } when: {
      $0.id == Misc.ID.nowPlaying
    })
    .execute(db)
  try Misc
    .createTemporaryTrigger(after: .insert {
      #sql("SELECT nowPlayingUpdate(NULL, NULL, \($0.rowId), \($0.value))")
    } when: {
      $0.id == Misc.ID.nowPlaying
    })
    .execute(db)
}

private func touchUpdatedAtCols(_ db: Database) throws {
  try Misc
    .createTemporaryTrigger(afterUpdateTouch: \.updatedAt)
    .execute(db)
  try Episode
    .createTemporaryTrigger(afterUpdateTouch: \.updatedAt)
    .execute(db)
  try Show
    .createTemporaryTrigger(afterUpdateTouch: \.updatedAt)
    .execute(db)
}
