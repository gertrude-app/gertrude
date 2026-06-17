import DuetSQL
import Gertie
import MacAppRoute
import PostgresKit

extension LogFilterEvents: Resolver {
  static func resolve(with input: Input, in context: MacApp.ChildContext) async throws -> Output {
    let computerUser = try await context.computerUser()
    let version = Semver(computerUser.appVersion) ?? .zero
    let kept = input.events.filter { event, _ in
      if droppedEventIds.contains(event.id) { return false }
      if version < firstCleanedVersion, droppedPre292EventIds.contains(event.id) {
        return false
      }
      return true
    }

    let events = try await context.db.create(kept.map { event, count in
      InterestingEvent(
        eventId: event.id,
        kind: "event",
        context: "macapp-filter",
        computerUserId: computerUser.id,
        parentId: nil,
        detail: [event.detail, count > 1 ? "(\(count)x)" : nil]
          .compactMap(\.self)
          .joined(separator: " "),
      )
    })

    let bgTask = Task {
      await logEventsToSlack(events, context: context, computerUser: computerUser)
      if input.events.contains(where: { $0.0.id == "933aa385" }) {
        await notifyScreenTimeConflict(computerUser: computerUser, in: context)
      }
      try await storeUnidentifiedApps(input.bundleIds, in: context)
    }

    if context.env.mode == .test {
      try await bgTask.value
    }

    return .success
  }
}

// helpers

struct UpsertAppBundleIdCounts: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let tableName = AppBundleId.qualifiedTableName
    let count = AppBundleId.columnName(.count)
    let bundleId = AppBundleId.columnName(.bundleId)
    var stmt = SQL.Statement("""
    UPDATE \(tableName) SET \(count) = \(tableName).\(count) + CASE \(bundleId)
    """)
    for i in (0 ..< bindings.count).striding(by: 2) {
      stmt.components.append(.sql("\nWHEN "))
      stmt.components.append(.binding(bindings[i]))
      stmt.components.append(.sql(" THEN "))
      stmt.components.append(.binding(bindings[i + 1]))
    }
    stmt.components.append(.sql("\nEND\nWHERE \(bundleId) IN ("))
    for i in (0 ..< bindings.count).striding(by: 2) {
      if i > 0 { stmt.components.append(.sql(", ")) }
      stmt.components.append(.binding(bindings[i]))
    }
    stmt.components.append(.sql(")"))
    return stmt
  }
}

struct IdentifiedBundleIds: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    .init("""
    SELECT \(AppBundleId.columnName(.bundleId)) FROM \(table: AppBundleId.self)
    """)
  }

  var bundleId: String
}

private let firstCleanedVersion: Semver = "2.9.2"

private let droppedEventIds: Set<String> = [
  "outboundDeferredStateMissing",
  "sawEncryptedClientHello_x100",
]

private let droppedPre292EventIds: Set<String> = [
  "outboundBytesGapDetected",
]

private func logEventsToSlack(
  _ events: [InterestingEvent],
  context: MacApp.ChildContext,
  computerUser: ComputerUser,
) async {
  let slack = get(dependency: \.slack)
  let contextInfo = await filterEventContext(context, computerUser)
  for event in events {
    await slack.internal(
      .info,
      "Macapp *filter* event: \(githubSearch(event.eventId)) \(event.detail ?? "")\(contextInfo)",
    )
  }
}

func notifyScreenTimeConflict(
  computerUser: ComputerUser,
  in context: MacApp.ChildContext,
) async {
  do {
    guard context.child.filteringDisabled == false else { return }

    let existing = try await InterestingEvent.query()
      .where(.eventId == "screentime-email-sent")
      .where(.computerUserId == computerUser.id)
      .all(in: context.db)

    guard existing.isEmpty,
          let computer = try? await computerUser.computer(in: context.db),
          let parent = try? await context.child.parent(in: context.db) else {
      return
    }

    let computerName = computer.customName ?? computer.modelIdentifier
    try await get(dependency: \.postmark).send(template: .screenTimeWarning(
      to: parent.email.rawValue,
      model: .init(childName: context.child.name, computerName: computerName),
    ))

    try await context.db.create(InterestingEvent(
      eventId: "screentime-email-sent",
      kind: "event",
      context: "api",
      computerUserId: computerUser.id,
      detail: "Screen Time warning email sent",
    ))

    let existingAnnouncement = try? await DashAnnouncement.query()
      .where(.parentId == parent.id)
      .where(.kind == "warning")
      .first(in: context.db)

    if existingAnnouncement == nil {
      try await context.db.create(DashAnnouncement(
        parentId: parent.id,
        kind: .warning,
        icon: "fa-solid fa-triangle-exclamation",
        html: """
        <b>Action needed:</b> We detected that Screen Time web filtering is enabled \
        on <b>\(context.child.name)’s</b> mac computer, which can interfere with \
        Gertrude’s ability to protect your child. \
        Disable Screen Time’s “Restrictions” &rarr; “Content &amp; Privacy” section to fix.
        """,
        learnMoreUrl: "https://gertrude.app/blog/screen-time-web-filter-conflict",
      ))
    }

    let parentLink = AdminLink().slack(
      to: .parent(parent.id),
      text: parent.email.rawValue,
    )
    await get(dependency: \.slack).internal(
      .info,
      "Sent Screen Time warning email to \(parentLink) for computer `\(computerName)`",
    )
  } catch {
    await get(dependency: \.slack).error(
      "Failed to send Screen Time warning email: \(error)",
    )
  }
}

private func storeUnidentifiedApps(
  _ bundleIds: [String: Int],
  in context: MacApp.ChildContext,
) async throws {
  guard !bundleIds.isEmpty else { return }

  let rows = try await context.db.customQuery(IdentifiedBundleIds.self)
  let identifiedBundleIds = Set(rows.map(\.bundleId))
  var unidentifiedApps: [UnidentifiedApp] = []
  var identifiedBindings: [Postgres.Data] = []

  for (bundleId, count) in bundleIds {
    if identifiedBundleIds.contains(bundleId) {
      identifiedBindings.append(.string(bundleId))
      identifiedBindings.append(.int(count))
    } else {
      unidentifiedApps.append(UnidentifiedApp(bundleId: bundleId, count: count))
    }
  }

  if !unidentifiedApps.isEmpty {
    try await context.db.upsert(
      unidentifiedApps,
      conflictOn: [.bundleId],
      do: .updateRaw { c in
        "\(c.col(.count)) = \(c.target(.count)) + \(c.excluded(.count))"
      },
    )
  }

  if !identifiedBindings.isEmpty {
    _ = try await context.db.customQuery(
      UpsertAppBundleIdCounts.self,
      withBindings: identifiedBindings,
    )
  }
}

private func filterEventContext(
  _ context: MacApp.ChildContext,
  _ computerUser: ComputerUser,
) async -> String {
  guard let computer = try? await computerUser.computer(in: context.db),
        let parent = try? await context.child.parent(in: context.db) else {
    return ""
  }
  let computerName = computer.customName ?? computer.modelIdentifier
  let text = "\(parent.email), \(context.child.name), \(computerName)"
  return "\n  -> " + AdminLink().slack(to: .parent(parent.id), text: text)
}
