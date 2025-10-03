import SQLiteData

extension Show {
  static var orderedWithInfo: SQLQueryExpression<PodcastsFeature.ShowInfo> {
    #sql(
      """
      SELECT
        \(Show.col.id), \(Show.col.name), \(Show.col.author),
        \(Show.col.description), \(Show.col.showArtwork), \(Show.col.artworkUrl),
        COALESCE(COUNT(\(Episode.col.id)), 0) AS totalEpisodes,
        COALESCE(SUM(CASE WHEN \(Episode.col.completedAt) IS NULL
          THEN 1 ELSE 0 END), 0) AS unplayedEpisodes,
        MAX(\(Episode.col.pubDate)) AS mostRecentPubDate
      FROM \(Show.self)
      LEFT JOIN \(Episode.self) ON \(Episode.col.showId) = \(Show.col.id)
      GROUP BY
        \(Show.col.id), \(Show.col.name),
        \(Show.col.author), \(Show.col.artworkUrl)
      ORDER BY mostRecentPubDate DESC;
      """
    )
  }
}
