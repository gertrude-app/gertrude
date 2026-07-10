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
    var artwork: Music.Artwork?
    var trackCount: Int?
    var showsArtwork = true
  }
}

extension ApproveMusicAlbum: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChildWithConnectedMusicApp(from: input.childId)
    try await context.db.upsert(
      Music.ApprovedAlbum(
        childId: child.id,
        appleMusicAlbumId: input.appleMusicAlbumId,
        title: input.title,
        artistName: input.artistName,
        artworkUrl: input.artworkUrl,
        artwork: input.artwork,
        trackCount: input.trackCount,
        showsArtwork: input.showsArtwork,
      ),
      conflictOn: [.childId, .appleMusicAlbumId],
      do: .update(set: [.title, .artistName, .artworkUrl, .artwork, .trackCount, .showsArtwork]),
    )
    return .success
  }
}
