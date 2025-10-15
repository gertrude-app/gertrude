import SQLiteData

func createDatabaseTriggers(_ db: Database) throws {
  try episodeLastPlayedAt(db)
  try episodeCompletedAt(db)
  try dispatchNowPlayingUpdates(db)
  try touchUpdatedAtCols(db)
  try subscriptionRequired(db)
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

/// observe special nowPlaying row, call swift callback
private func dispatchNowPlayingUpdates(_ db: Database) throws {
  try NowPlayingModel
    .createTemporaryTrigger(
      after: .update { ($0.episodeId, $0.isPlaying) }
        forEachRow: {
          #sql(
            "SELECT nowPlayingUpdate(\($0.episodeId), \($0.isPlaying), \($1.episodeId), \($1.isPlaying))"
          )
        }
    )
    .execute(db)
  try NowPlayingModel
    .createTemporaryTrigger(after: .delete {
      #sql("SELECT nowPlayingUpdate(\($0.episodeId), \($0.isPlaying), NULL, NULL)")
    })
    .execute(db)
  try NowPlayingModel
    .createTemporaryTrigger(after: .insert {
      #sql("SELECT nowPlayingUpdate(NULL, NULL, \($0.episodeId), \($0.isPlaying))")
    })
    .execute(db)
}

private func subscriptionRequired(_ db: Database) throws {
  try Subscription
    .createTemporaryTrigger(after: .delete { _ in
      #sql("SELECT RAISE(ABORT, 'subscription record is required')")
    })
    .execute(db)
}

private func touchUpdatedAtCols(_ db: Database) throws {
  try NowPlayingModel
    .createTemporaryTrigger(afterUpdateTouch: \.updatedAt)
    .execute(db)
  try Episode
    .createTemporaryTrigger(afterUpdateTouch: \.updatedAt)
    .execute(db)
  try Show
    .createTemporaryTrigger(afterUpdateTouch: \.updatedAt)
    .execute(db)
  try Record
    .createTemporaryTrigger(afterUpdateTouch: \.updatedAt)
    .execute(db)
  try Subscription
    .createTemporaryTrigger(afterUpdateTouch: \.updatedAt)
    .execute(db)
}
