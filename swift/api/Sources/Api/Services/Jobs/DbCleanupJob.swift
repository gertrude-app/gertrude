import Dependencies
import DuetSQL
import Foundation
import Gertie
import Queues
import Vapor

struct CleanupJob: AsyncScheduledJob {
  @Dependency(\.env) var env
  @Dependency(\.db) var db

  func run(context: QueueContext) async throws {
    guard self.env.mode == .prod else {
      return
    }

    let logs = try await cleanupDb()
    for log in logs {
      context.logger.info("DbCleanupJob: \(log)")
    }
  }

  func cleanupDb() async throws -> [String] {
    let now = Date()
    var logs: [String] = []

    // NB: we deliberately do not cleanup dash_anouncements for audit trail

    let deletedScreenshots = try await Screenshot.query()
      .where(.and(
        .or(
          .not(.isNull(.deletedAt)) .&& .deletedAt <= 14.daysAgo,
          .createdAt <= 21.daysAgo,
        ),
        .or(.isNull(.flagged), .flagged <= 60.daysAgo),
      ))
      .delete(in: self.db, force: true)

    logs.append("Deleted \(deletedScreenshots) screenshots")

    let deletedKeystrokes = try await KeystrokeLine.query()
      .where(.and(
        .or(
          .not(.isNull(.deletedAt)) .&& .deletedAt <= 14.daysAgo,
          .createdAt <= 21.daysAgo,
        ),
        .or(.isNull(.flagged), .flagged <= 60.daysAgo),
      ))
      .delete(in: self.db, force: true)

    logs.append("Deleted \(deletedKeystrokes) keystroke lines")

    let deletedNonPendingUnlockRequests = try await UnlockRequest.query()
      .where(.status != RequestStatus.pending)
      .where(.updatedAt < 3.daysAgo)
      .delete(in: self.db)

    logs.append("Deleted \(deletedNonPendingUnlockRequests) non-pending unlock requests")

    let deletedPendingUnlockRequests = try await UnlockRequest.query()
      .where(.status == RequestStatus.pending)
      .where(.updatedAt < 7.daysAgo)
      .delete(in: self.db)

    logs.append("Deleted \(deletedPendingUnlockRequests) pending unlock requests")

    let deletedShortUrls = try await ShortUrl.query()
      .where(.deletedAt < now)
      .delete(in: self.db, force: true)

    logs.append("Deleted \(deletedShortUrls) short urls")

    let deletedDashTokens = try await Parent.DashToken.query()
      .where(.deletedAt < now .&& .not(.isNull(.deletedAt)))
      .delete(in: self.db, force: true)

    logs.append("Deleted \(deletedDashTokens) parent dash tokens")

    let deletedSuperAdminTokens = try await SuperAdminToken.query()
      .where(.deletedAt < now)
      .delete(in: self.db, force: true)

    logs.append("Deleted \(deletedSuperAdminTokens) super admin tokens")

    let suspendFilterRequests = try await MacApp.SuspendFilterRequest.query()
      .where(.createdAt < 3.daysAgo)
      .delete(in: self.db)

    logs.append("Deleted \(suspendFilterRequests) suspend filter requests")

    let smokeAdmins = try await Parent.query()
      .where(.like(.email, "%.smoke-test-%"))
      .delete(in: self.db)

    logs.append("Deleted \(smokeAdmins) smoke test admin accounts")

    // cleanup keeping at least the single most recent check-in per ios device
    let eventId = IOSEvent.columnName(.id)
    let eventDomain = IOSEvent.columnName(.domain)
    let eventDeviceId = IOSEvent.columnName(.deviceId)
    let checkinEvents = try await self.db.execute(raw: """
    DELETE FROM \(table: IOSEvent.self) e
    WHERE e.\(col: eventDomain) = 'checkin'
      AND e.created_at < now() - interval '14 days'
      AND (e.\(col: eventDeviceId) IS NULL
           OR EXISTS (SELECT 1 FROM \(table: IOSEvent.self) n
                      WHERE n.\(col: eventDeviceId) = e.\(col: eventDeviceId)
                        AND n.\(col: eventDomain) = 'checkin'
                        AND n.created_at > e.created_at))
    RETURNING e.\(col: eventId)
    """).count

    logs.append("Deleted \(checkinEvents) iOS check-in events")

    let blockerDebugEvents = try await IOSEvent.query()
      .where(.level == "debug")
      .where(.createdAt < 7.daysAgo)
      .delete(in: self.db)

    logs.append("Deleted \(blockerDebugEvents) blocker debug events")

    let musicDebugEvents = try await MusicApp.Event.query()
      .where(.level == "debug")
      .where(.createdAt < 7.daysAgo)
      .delete(in: self.db)

    logs.append("Deleted \(musicDebugEvents) music debug events")

    let podcastDebugEvents = try await PodcastEvent.query()
      .where(.level == "debug")
      .where(.createdAt < 7.daysAgo)
      .delete(in: self.db)

    logs.append("Deleted \(podcastDebugEvents) podcast debug events")

    let deletedTelemetry = try await RouteTelemetry.query()
      .where(.createdAt < 30.daysAgo)
      .delete(in: self.db, force: true)

    logs.append("Deleted \(deletedTelemetry) route telemetry rows")

    await self.db.notifyCompletedDeprecations(noRequestsWithinLast: .days(120))

    return logs
  }
}

// helpers

private extension Array {
  func chunked(into size: Int) -> [[Element]] {
    stride(from: 0, to: count, by: size).map {
      Array(self[$0 ..< Swift.min($0 + size, count)])
    }
  }
}
