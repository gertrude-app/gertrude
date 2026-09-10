import DuetSQL
import Foundation
import XCore

enum RepeatTrialCanary {
  static let snapshotType = "ChildTrialSnapshot"

  struct Snapshot: Codable, Sendable {
    struct Trial: Codable, Sendable {
      let deviceId: IOSDevice.Id
      let startedAt: Date
    }

    let parentId: Parent.Id
    let childId: Child.Id
    let music: [Trial]
    let podcasts: [Trial]

    func trial(for deviceId: IOSDevice.Id, intent: ClaimIntent) -> Trial? {
      switch intent {
      case .music:
        self.music.first { $0.deviceId == deviceId }
      case .podcasts:
        self.podcasts.first { $0.deviceId == deviceId }
      case .blockerConnect, .blockerSupervise:
        nil
      }
    }
  }

  struct RecentTrial {
    let snapshot: Snapshot
    let trial: Snapshot.Trial
    let deletedAt: Date
  }

  static func recordSnapshot(
    child: Child,
    devices: [IOSDevice],
    in db: any DuetSQL.Client,
  ) async {
    do {
      try await self.createSnapshot(child: child, devices: devices, in: db)
    } catch {
      with(dependency: \.logger).error("Failed child trial snapshot: \(error)")
    }
  }

  static func alertIfReclaimed(
    _ intent: ClaimIntent,
    _ device: IOSDevice,
    _ child: Child,
    in context: ParentContext,
  ) async {
    do {
      let now = get(dependency: \.date.now)
      guard let match = try await recentTrial(
        deviceId: device.id,
        intent: intent,
        since: now - .days(3),
        in: context.db,
      ) else {
        return
      }

      let trialLength: TimeInterval = switch intent {
      case .music: MusicApp.Token.trialDuration
      case .podcasts: PodcastApp.Install.trialPeriod
      case .blockerConnect, .blockerSupervise: 0
      }
      let originalTrialEnd = match.trial.startedAt + trialLength
      with(dependency: \.postmark).toSuperAdmin(
        "Possible repeated \(intent.app.marketingName) trial",
        """
        <p>A device from a recently deleted child was claimed again.</p>
        <ul>
          <li>App: <code>\(intent.app.marketingName)</code></li>
          <li>Device: <code>\(device.id.rawValue.uuidString.lowercased())</code></li>
          <li>Original parent: <code>\(match.snapshot.parentId)</code></li>
          <li>Original child: <code>\(match.snapshot.childId)</code></li>
          <li>Original trial start: <code>\(match.trial.startedAt.isoString)</code></li>
          <li>Original trial end: <code>\(originalTrialEnd.isoString)</code></li>
          <li>Deleted at: <code>\(match.deletedAt.isoString)</code></li>
          <li>New parent: <code>\(context.parent.id)</code> \(context.parent.email.rawValue)</li>
          <li>New child: <code>\(child.id)</code> \(child.name)</li>
        </ul>
        """,
      )
    } catch {
      with(dependency: \.logger).error("Failed repeat-trial canary check: \(error)")
    }
  }

  static func recentTrial(
    deviceId: IOSDevice.Id,
    intent: ClaimIntent,
    since: Date,
    in db: any DuetSQL.Client,
  ) async throws -> RecentTrial? {
    let records = try await DeletedEntity.query()
      .where(.type == Self.snapshotType)
      .where(.createdAt >= since)
      .all(in: db)
      .sorted { $0.createdAt > $1.createdAt }

    for record in records {
      guard let snapshot = try? JSON.decode(record.data, as: Snapshot.self, [.isoDates]),
            let trial = snapshot.trial(for: deviceId, intent: intent) else {
        continue
      }
      return .init(snapshot: snapshot, trial: trial, deletedAt: record.createdAt)
    }
    return nil
  }

  private static func createSnapshot(
    child: Child,
    devices: [IOSDevice],
    in db: any DuetSQL.Client,
  ) async throws {
    let deviceIds = devices.map(\.id)
    guard !deviceIds.isEmpty else { return }

    let musicInstalls = try await MusicApp.Install.query()
      .where(.deviceId |=| deviceIds)
      .all(in: db)
    let musicInstallById = Dictionary(uniqueKeysWithValues: musicInstalls.map { ($0.id, $0) })
    let musicTokens = if musicInstalls.isEmpty {
      [MusicApp.Token]()
    } else {
      try await MusicApp.Token.query()
        .where(.installId |=| musicInstalls.map(\.id))
        .all(in: db)
    }
    let musicTrials = musicTokens.compactMap { token -> Snapshot.Trial? in
      guard let install = musicInstallById[token.installId] else { return nil }
      return .init(deviceId: install.deviceId, startedAt: token.createdAt)
    }

    let podcastTrials = try await PodcastApp.Install.query()
      .where(.deviceId |=| deviceIds)
      .all(in: db)
      .map { Snapshot.Trial(deviceId: $0.deviceId, startedAt: $0.createdAt) }

    guard !musicTrials.isEmpty || !podcastTrials.isEmpty else { return }

    let snapshot = Snapshot(
      parentId: child.parentId,
      childId: child.id,
      music: musicTrials,
      podcasts: podcastTrials,
    )
    try await db.create(DeletedEntity(
      type: Self.snapshotType,
      reason: "parent deleted child",
      data: JSON.encode(snapshot, [.isoDates]),
    ))
  }
}
