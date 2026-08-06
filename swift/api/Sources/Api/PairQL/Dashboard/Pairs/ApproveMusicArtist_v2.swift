import Crypto
import Dependencies
import DuetSQL
import Foundation
import PairQL

struct ApproveMusicArtist_v2: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
    var appleMusicArtistId: Music.ArtistId
    var confirmationToken: String?
  }

  typealias Output = MusicArtistApprovalOutput
}

extension ApproveMusicArtist_v2: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChildWithConnectedMusicApp(from: input.childId)
    let resolution = try await get(dependency: \.appleMusic).resolveArtist(
      input.appleMusicArtistId,
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
      let covered = try policy.coverage.directGrantsCovered(by: resolution)
      if !covered.albumIds.isEmpty || !covered.trackIds.isEmpty {
        let token = artistConfirmationToken(
          revision: revision,
          artistId: resolution.id,
          covered: covered,
        )
        guard input.confirmationToken == token else {
          return .init(
            status: .confirmationRequired,
            curation: policy.curation(revision: revision),
            confirmation: .init(
              revision: revision,
              token: token,
              albumCount: covered.albumIds.count,
              trackCount: covered.trackIds.count,
            ),
          )
        }
      }

      let changed = try await Music.CatalogPolicy.addArtist(
        childId: child.id,
        resolution: resolution,
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
        confirmation: nil,
      )
    }
  }
}

func artistConfirmationToken(
  revision: Int64,
  artistId: Music.ArtistId,
  covered: Music.CatalogPolicy.CoveredDirectGrants,
) -> String {
  let albumIds = covered.albumIds.map(\.rawValue).sorted().joined(separator: ",")
  let trackIds = covered.trackIds.map(\.rawValue).sorted().joined(separator: ",")
  let value = "\(revision)|\(artistId.rawValue)|\(albumIds)|\(trackIds)"
  return SHA256.hash(data: Data(value.utf8))
    .prefix(16)
    .map { String(format: "%02x", $0) }
    .joined()
}

struct MusicArtistApprovalOutput: PairOutput {
  enum Status: String, PairNestable {
    case updated
    case confirmationRequired
  }

  struct Confirmation: PairNestable {
    var revision: Int64
    var token: String
    var albumCount: Int
    var trackCount: Int
  }

  var status: Status
  var curation: MusicCurationOutput
  var confirmation: Confirmation?
}
