import DuetSQL
import Foundation

func musicCurationRevision(
  childId: Child.Id,
  policy: Music.CatalogPolicy.StoredPolicy,
  in db: any DuetSQL.Client,
  context: ParentContext,
) async throws -> Int64 {
  guard let snapshot = try await Music.LibrarySnapshotRepository.snapshot(
    for: childId,
    in: db,
  ) else {
    guard policy.albums.isEmpty, policy.artists.isEmpty, policy.tracks.isEmpty else {
      throw context.error(
        "c56ee45b",
        .serverError,
        "Music grants exist without a published snapshot for child `\(childId)`",
      )
    }
    return 0
  }
  guard snapshot.revision == snapshot.payload.revision else {
    throw context.error(
      "31f9c801",
      .serverError,
      "Music snapshot revision mismatch for child `\(childId)`",
    )
  }
  return snapshot.revision
}

func currentMusicCuration(
  childId: Child.Id,
  in db: any DuetSQL.Client,
  context: ParentContext,
) async throws -> MusicCurationOutput {
  let policy = try await Music.CatalogPolicy.load(childId: childId, in: db)
  let revision = try await musicCurationRevision(
    childId: childId,
    policy: policy,
    in: db,
    context: context,
  )
  return policy.curation(revision: revision)
}

@discardableResult
func publishMusicPolicy(
  childId: Child.Id,
  changed: Bool,
  generatedAt: Date,
  in db: any DuetSQL.Client,
) async throws -> Music.LibrarySnapshot {
  if changed {
    return try await Music.LibrarySnapshotRepository.publishAfterPolicyChange(
      childId: childId,
      generatedAt: generatedAt,
      in: db,
    )
  }
  return try await Music.LibrarySnapshotRepository.publish(
    childId: childId,
    generatedAt: generatedAt,
    in: db,
  )
}
