import Dependencies
import DuetSQL
import PairQL

struct SaveMusicAlbumCuration: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
    var appleMusicAlbumId: Music.AlbumId
    var expectedRevision: Int64
    var selectedTrackIds: [Music.TrackId]
  }

  typealias Output = MusicAlbumCurationMutationOutput
}

extension SaveMusicAlbumCuration: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChildWithConnectedMusicApp(from: input.childId)
    let album = try await get(dependency: \.appleMusic).resolveAlbum(
      input.appleMusicAlbumId,
    )
    let now = get(dependency: \.date.now)
    return try await context.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: child.id, in: db)
      let policy = try await Music.CatalogPolicy.load(childId: child.id, in: db)
      let revision = try await musicCurationRevision(
        childId: child.id,
        policy: policy,
        in: db,
        context: context,
      )
      guard revision == input.expectedRevision else {
        return .init(
          status: .conflict,
          curation: policy.curation(revision: revision),
          album: policy.albumCuration(album: album, revision: revision),
        )
      }

      let plan: Music.CatalogPolicy.AlbumSelectionPlan
      do {
        plan = try policy.coverage.planAlbumSelection(
          for: album,
          selectedTrackIds: input.selectedTrackIds,
        )
      } catch let error as Music.CatalogPolicy.AlbumSelectionError {
        switch error {
        case .unknownTrackIds(let trackIds):
          throw context.error(
            id: "6d8d8011",
            type: .badRequest,
            debugMessage: "Unknown Apple Music track IDs: \(trackIds.map(\.rawValue))",
            userMessage: "Some selected tracks are no longer part of this album. Reload and try again.",
          )
        }
      }

      if case .coveredByArtist = plan {
        return .init(
          status: .coveredByArtist,
          curation: policy.curation(revision: revision),
          album: policy.albumCuration(album: album, revision: revision),
        )
      }

      let changed = try await Music.CatalogPolicy.applyAlbumSelection(
        plan,
        childId: child.id,
        album: album,
        policy: policy,
        resolvedAt: now,
        in: db,
      )
      let snapshot = try await Music.LibrarySnapshotRepository.publish(
        childId: child.id,
        policyChanged: changed,
        generatedAt: now,
        in: db,
      )
      let updatedPolicy = try await Music.CatalogPolicy.load(childId: child.id, in: db)
      return .init(
        status: .updated,
        curation: updatedPolicy.curation(revision: snapshot.revision),
        album: updatedPolicy.albumCuration(
          album: album,
          revision: snapshot.revision,
        ),
      )
    }
  }
}

struct MusicAlbumCurationMutationOutput: PairOutput {
  enum Status: String, PairNestable {
    case updated
    case conflict
    case coveredByArtist
  }

  var status: Status
  var curation: MusicCurationOutput
  var album: MusicAlbumCuration
}
