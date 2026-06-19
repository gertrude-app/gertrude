import Dependencies
import DuetSQL
import Foundation
import Queues
import Vapor

struct DailyReviewEmailJob: AsyncScheduledJob {
  @Dependency(\.db) var db
  @Dependency(\.env) var env
  @Dependency(\.date.now) var now
  @Dependency(\.postmark) var postmark

  static let sendHour = 8
  static let defaultTimeZone = "America/New_York"

  func run(context: QueueContext) async throws {
    guard self.env.mode == .prod else { return }
    let sent = try await self.tick()
    if sent > 0 {
      context.logger.info("DailyReviewEmailJob: sent \(sent) digest email(s)")
    }
  }

  func tick() async throws -> Int {
    let parents = try await Parent.query()
      .where(.dailyReviewEmail == true)
      .where(.emailVerifiedAt != nil)
      .all(in: self.db)

    var sent = 0
    for var parent in parents {
      guard shouldSendDailyReview(
        now: self.now,
        timeZoneId: parent.timeZone,
        lastSentAt: parent.lastReviewEmailAt,
        sendHour: Self.sendHour,
      ) else { continue }

      guard let model = try await self.buildDigest(for: parent) else { continue }

      try await self.postmark.send(
        template: .dailyReviewDigest(to: parent.email.rawValue, model: model),
      )
      parent.lastReviewEmailAt = self.now
      try await self.db.update(parent)
      sent += 1
    }
    return sent
  }

  func buildDigest(for parent: Parent) async throws -> DailyReviewDigest? {
    let children = try await parent.children(in: self.db)
    guard !children.isEmpty else { return nil }

    let computerUsers = try await ComputerUser.query()
      .where(.childId |=| children.map(\.id))
      .all(in: self.db)
    guard !computerUsers.isEmpty else { return nil }

    let screenshots = try await Screenshot.query()
      .where(.computerUserId |=| computerUsers.map(\.id))
      .where(.createdAt >= self.now.addingTimeInterval(-14 * 24 * 60 * 60))
      .withSoftDeleted()
      .all(in: self.db)

    let userToChild: [ComputerUser.Id: Child.Id] = computerUsers
      .reduce(into: [:]) { $0[$1.id] = $1.childId }
    let newSince = self.now.addingTimeInterval(-26 * 60 * 60)
    let dashboardUrl = self.env.dashboardUrl.withoutTrailingSlashes

    var rows: [ChildRow] = []
    for child in children {
      let childShots = screenshots.filter { userToChild[$0.computerUserId] == child.id }
      let backlog = childShots.filter(\.notDeleted).count
      let newCount = childShots.count(where: { $0.createdAt >= newSince && $0.notDeleted })
      if newCount > 0 || backlog > 0 {
        rows.append(ChildRow(
          name: child.name,
          activityUrl: "\(dashboardUrl)/children/\(child.id.lowercased)/activity",
          newCount: newCount,
          backlog: backlog,
        ))
      }
    }

    let totalNew = rows.reduce(0) { $0 + $1.newCount }
    guard totalNew > 0 else { return nil } // activity gate: don't nag on quiet days

    let activeNames = rows.filter { $0.newCount > 0 }.map(\.name)
    return DailyReviewDigest(
      subjectSummary: "\(totalNew) new screenshot\(totalNew == 1 ? "" : "s")",
      intro: "Gertrude has new screenshots of \(joinChildNames(activeNames))’s "
        + "activity, ready for your review:",
      childRows: rows.map(\.html).joined(separator: "\n"),
      reviewUrl: "\(dashboardUrl)/children/activity",
      manageUrl: "\(dashboardUrl)/settings",
    )
  }
}

// helpers

struct ChildRow {
  let name: String
  let activityUrl: String
  let newCount: Int
  let backlog: Int

  var html: String {
    var parts: [String] = []
    if self.newCount > 0 {
      parts.append("\(self.newCount) new screenshot\(self.newCount == 1 ? "" : "s")")
    }
    parts.append("\(self.backlog) awaiting review")
    let detail = parts.joined(separator: " · ")
    return "<p class=\"centered\"><strong>\(htmlEscape(self.name))</strong>: "
      + "\(detail) · <a href=\"\(self.activityUrl)\">review →</a></p>"
  }
}

func shouldSendDailyReview(
  now: Date,
  timeZoneId: String?,
  lastSentAt: Date?,
  sendHour: Int,
) -> Bool {
  let zone = timeZoneId.flatMap(TimeZone.init(identifier:))
    ?? TimeZone(identifier: DailyReviewEmailJob.defaultTimeZone)!
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = zone
  guard calendar.component(.hour, from: now) == sendHour else { return false }
  if let lastSentAt, calendar.isDate(lastSentAt, inSameDayAs: now) { return false }
  return true
}

func joinChildNames(_ names: [String]) -> String {
  switch names.count {
  case 0: ""
  case 1: names[0]
  case 2: "\(names[0]) and \(names[1])"
  default: "\(names.dropLast().joined(separator: ", ")), and \(names.last ?? "")"
  }
}

private func htmlEscape(_ string: String) -> String {
  string
    .replacingOccurrences(of: "&", with: "&amp;")
    .replacingOccurrences(of: "<", with: "&lt;")
    .replacingOccurrences(of: ">", with: "&gt;")
}
