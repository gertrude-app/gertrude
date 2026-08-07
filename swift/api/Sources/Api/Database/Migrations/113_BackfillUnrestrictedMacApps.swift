import FluentSQL
import Foundation
import Gertie
import XCore

struct BackfillUnrestrictedMacApps: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    let existing = try await Self.loadExistingGroupKeys(sql)
    let sources = try await Self.loadPrivateSkeletonSources(sql)
    let plan = try Self.plan(sources: sources)

    for row in plan.rows where !existing.contains(row.groupKey) {
      try await sql.execute("""
        INSERT INTO child.unrestricted_mac_apps
          (id, child_id, scope, schedule, created_at, updated_at)
        VALUES (
          '\(uuid: row.id)',
          '\(uuid: row.childId)',
          '\(escaping: row.scopeJson)'::jsonb,
          \(nullable: row.scheduleJson)::jsonb,
          CURRENT_TIMESTAMP,
          CURRENT_TIMESTAMP
        )
      """)
    }

    try await sql.execute("""
      UPDATE parent.keys k
      SET deleted_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
      FROM parent.keychains kc
      WHERE kc.id = k.keychain_id
        AND kc.is_public = false
        AND k.deleted_at IS NULL
        AND k.key ->> 'type' = 'skeleton'
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DELETE FROM child.unrestricted_mac_apps
    """)
  }
}

extension BackfillUnrestrictedMacApps {
  struct GroupKey: Hashable {
    var childId: UUID
    var scope: AppScope.Single

    init(childId: UUID, scope: AppScope.Single) {
      self.childId = childId
      self.scope = scope.normalized
    }
  }

  struct Source {
    var childId: UUID
    var scope: AppScope.Single
    var schedule: RuleSchedule?
    var scheduleJson: String?

    var groupKey: GroupKey {
      GroupKey(childId: self.childId, scope: self.scope)
    }
  }

  struct NewRow {
    var id: UUID
    var childId: UUID
    var scope: AppScope.Single
    var scopeJson: String
    var schedule: RuleSchedule?
    var scheduleJson: String?

    var groupKey: GroupKey {
      GroupKey(childId: self.childId, scope: self.scope)
    }
  }

  struct Plan {
    var rows: [NewRow]
  }

  enum BackfillError: Error, CustomStringConvertible {
    case unresolvedScheduleConflict(childId: UUID, scope: AppScope.Single)
    case behavioralDivergence(childId: UUID, scope: AppScope.Single)
    case missingResolvedRow(childId: UUID, scope: AppScope.Single)

    var description: String {
      switch self {
      case .unresolvedScheduleConflict(let childId, let scope):
        "106 backfill: unresolved schedule conflict for child \(childId) scope \(scope) — differing schedules, no unscheduled source, no pre-resolved exception"
      case .behavioralDivergence(let childId, let scope):
        "106 backfill: behavioral divergence for child \(childId) scope \(scope) — pre/post app-unrestrict differs"
      case .missingResolvedRow(let childId, let scope):
        "106 backfill: missing resolved row for child \(childId) scope \(scope)"
      }
    }
  }

  struct PreResolvedConflict {
    var childIdPrefix: String
    var scope: AppScope.Single
    var resolved: RuleSchedule
  }

  static let preResolvedScheduleConflicts: [PreResolvedConflict] = [
    PreResolvedConflict(
      childIdPrefix: "37b3f2c8-690e-4ead-9d88-682db85e",
      scope: .identifiedAppSlug("chrome"),
      resolved: RuleSchedule(
        mode: .active,
        days: .all,
        window: PlainTimeWindow(
          start: PlainTime(hour: 7, minute: 0),
          end: PlainTime(hour: 17, minute: 0),
        ),
      ),
    ),
  ]

  static func preResolvedSchedule(for key: GroupKey) -> RuleSchedule? {
    let id = key.childId.uuidString.lowercased()
    return self.preResolvedScheduleConflicts.first {
      id.hasPrefix($0.childIdPrefix) && $0.scope == key.scope
    }?.resolved
  }

  static func plan(sources: [Source], makeId: () -> UUID = { UUID() }) throws -> Plan {
    var groups: [GroupKey: [Source]] = [:]
    for source in sources {
      groups[source.groupKey, default: []].append(source)
    }

    var rows: [NewRow] = []
    for (key, groupSources) in groups {
      let resolved = try self.resolveSchedule(for: key, sources: groupSources)
      try rows.append(NewRow(
        id: makeId(),
        childId: key.childId,
        scope: key.scope,
        scopeJson: JSON.encode(key.scope),
        schedule: resolved.schedule,
        scheduleJson: resolved.scheduleJson,
      ))
    }

    try self.assertBehaviorPreserved(groups: groups, rows: rows)
    return Plan(rows: rows)
  }

  static func resolveSchedule(
    for key: GroupKey,
    sources: [Source],
  ) throws -> (schedule: RuleSchedule?, scheduleJson: String?) {
    if sources.contains(where: { $0.schedule == nil }) {
      return (nil, nil)
    }
    let distinct = Set(sources.compactMap(\.schedule))
    if distinct.count <= 1 {
      let scheduled = sources.first { $0.schedule != nil }
      return (scheduled?.schedule, scheduled?.scheduleJson)
    }
    if let resolved = self.preResolvedSchedule(for: key) {
      return try (resolved, JSON.encode(resolved))
    }
    throw BackfillError.unresolvedScheduleConflict(childId: key.childId, scope: key.scope)
  }

  static func assertBehaviorPreserved(
    groups: [GroupKey: [Source]],
    rows: [NewRow],
  ) throws {
    let rowsByKey = Dictionary(uniqueKeysWithValues: rows.map { ($0.groupKey, $0) })
    let probes = self.behavioralProbeDates()

    for (key, groupSources) in groups {
      guard let row = rowsByKey[key] else {
        throw BackfillError.missingResolvedRow(childId: key.childId, scope: key.scope)
      }
      if self.preResolvedSchedule(for: key) != nil {
        continue
      }
      let sourceSchedules = groupSources.map(\.schedule)
      let anyScheduled = row.schedule != nil || sourceSchedules.contains { $0 != nil }
      if !anyScheduled {
        continue
      }
      for probe in probes {
        let preActive = sourceSchedules.contains { schedule in
          schedule == nil || schedule!.active(at: probe, in: self.utcCalendar)
        }
        let postActive = row.schedule == nil || row.schedule!.active(
          at: probe,
          in: self.utcCalendar,
        )
        if preActive != postActive {
          throw BackfillError.behavioralDivergence(childId: key.childId, scope: key.scope)
        }
      }
    }
  }

  static let utcCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }()

  static let probeWeekStart: TimeInterval = 1_704_585_600

  static func behavioralProbeDates() -> [Date] {
    (0 ..< (7 * 24 * 60)).map {
      Date(timeIntervalSince1970: self.probeWeekStart + Double($0) * 60)
    }
  }

  static func loadExistingGroupKeys(_ sql: SQLDatabase) async throws -> Set<GroupKey> {
    let rows = try await sql.execute("""
      SELECT child_id, scope::text AS scope_json
      FROM child.unrestricted_mac_apps
    """)
    return try Set(rows.map { row in
      let childId: UUID = try row.decode(column: "child_id")
      let scopeJson: String = try row.decode(column: "scope_json")
      return try GroupKey(childId: childId, scope: JSON.decode(scopeJson, as: AppScope.Single.self))
    })
  }

  static func loadPrivateSkeletonSources(_ sql: SQLDatabase) async throws -> [Source] {
    let rows = try await sql.execute("""
      SELECT ck.child_id AS child_id,
             (k.key -> 'scope')::text AS scope_json,
             COALESCE((ck.schedule)::text, '') AS schedule_json
      FROM parent.keys k
      JOIN parent.keychains kc ON kc.id = k.keychain_id
      JOIN child.keychains ck ON ck.keychain_id = kc.id
      WHERE kc.is_public = false
        AND k.deleted_at IS NULL
        AND k.key ->> 'type' = 'skeleton'
    """)
    return try rows.map { row in
      let childId: UUID = try row.decode(column: "child_id")
      let scopeJson: String = try row.decode(column: "scope_json")
      let scheduleText: String = try row.decode(column: "schedule_json")
      let schedule = scheduleText.isEmpty
        ? nil
        : try JSON.decode(scheduleText, as: RuleSchedule.self)
      return try Source(
        childId: childId,
        scope: JSON.decode(scopeJson, as: AppScope.Single.self),
        schedule: schedule,
        scheduleJson: scheduleText.isEmpty ? nil : scheduleText,
      )
    }
  }
}
