import DuetSQL
import PairQL

struct ApproveMusicAlbum: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
    var appleMusicAlbumId: Music.AlbumId
    var title: String
    var artistName: String
    var artworkUrl: String?
    var trackCount: Int?
    var showsArtwork = true
  }
}

extension ApproveMusicAlbum: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChildWithConnectedMusicApp(from: input.childId)
    let existingAlbums = try await Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .where(.appleMusicAlbumId == input.appleMusicAlbumId.rawValue)
      .all(in: context.db)

    if var existing = existingAlbums.first {
      existing.title = input.title
      existing.artistName = input.artistName
      existing.artworkUrl = input.artworkUrl
      existing.trackCount = input.trackCount
      existing.showsArtwork = input.showsArtwork
      try await context.db.update(existing)
    } else {
      try await context.db.create(Music.ApprovedAlbum(
        childId: child.id,
        appleMusicAlbumId: input.appleMusicAlbumId,
        title: input.title,
        artistName: input.artistName,
        artworkUrl: input.artworkUrl,
        trackCount: input.trackCount,
        showsArtwork: input.showsArtwork,
      ))
    }

    return .success
  }
}
