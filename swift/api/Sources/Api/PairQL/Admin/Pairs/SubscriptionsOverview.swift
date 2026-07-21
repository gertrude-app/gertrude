import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL
import TaggedMoney

struct SubscriptionsOverview: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var monthlyRevenue: Int
    var annualRevenue: Int
    var monthlySubscriptionRevenue: [MonthlySubscriptionRevenueOutput]
    var fullPlanCount: Int
    var fullPlanAnnualRevenue: Int
    var mediumPlanCount: Int
    var mediumPlanAnnualRevenue: Int
    var lightPlanCount: Int
    var lightPlanAnnualRevenue: Int
    var trialingCount: Int
    var protectedChildren: Int
    var totalAccounts: Int
    var recentSignups: [RecentSignupOutput]
  }

  struct RecentSignupOutput: PairNestable {
    var date: Date
    var email: String
    var engagement: String
  }

  struct MonthlySubscriptionRevenueOutput: PairNestable {
    var month: String
    var centsCollected: Int
    var fullPlanCents: Int
    var mediumPlanCents: Int
    var lightPlanCents: Int
    var otherCents: Int
    var paidInvoices: Int
  }
}

extension SubscriptionsOverview: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    @Dependency(\.env) var env
    let data = try await AnalyticsQuery.shared.data()

    var fullPlanCount = 0
    var fullPlanAnnualCents = 0
    var mediumPlanCount = 0
    var mediumPlanAnnualCents = 0
    var lightPlanCount = 0
    var lightPlanAnnualCents = 0
    var trialingCount = 0

    var signups: [RecentSignupOutput] = []

    for parent in data.parents.values {
      if let sub = parent.subscription, sub.stripeStatus.isLive {
        switch sub.tier {
        case .light:
          lightPlanCount += 1
          lightPlanAnnualCents += 1000
        case .medium:
          if sub.stripeStatus == .trialing {
            trialingCount += 1
          } else if sub.stripeStatus.isPaying {
            mediumPlanCount += 1
            mediumPlanAnnualCents += 500 * 12
          }
        case .full:
          if sub.stripeStatus == .trialing {
            trialingCount += 1
          } else if sub.stripeStatus.isPaying {
            fullPlanCount += 1
            fullPlanAnnualCents += (sub.isLegacyPrice ? 500 : 1000) * 12
          }
        }
      }

      let engagement =
        if parent.isActive
          || parent.hasCompletedSupervision
          || parent.hasConnectedFreeIOSDevice
          || parent.hasConnectedPodcastApp
          || parent.hasConnectedMusicApp {
          "engaged"
        } else if parent.numComputerUsers > 0 || parent.hasIncompleteSupervision {
          "partial"
        } else {
          "none"
        }

      signups.append(
        .init(
          date: parent.createdAt,
          email: parent.email.rawValue,
          engagement: engagement,
        ))
    }

    let monthlySubscriptionRevenue = try await context.db
      .customQuery(
        MonthlySubscriptionRevenue.self,
        withBindings: [.string(env.stripe.priceIdMedium)],
      )
      .map { row in
        MonthlySubscriptionRevenueOutput(
          month: row.month,
          centsCollected: row.centsCollected,
          fullPlanCents: row.fullPlanCents,
          mediumPlanCents: row.mediumPlanCents,
          lightPlanCents: row.lightPlanCents,
          otherCents: row.otherCents,
          paidInvoices: row.paidInvoices,
        )
      }

    let totalAnnualCents = fullPlanAnnualCents + mediumPlanAnnualCents + lightPlanAnnualCents
    return try await .init(
      monthlyRevenue: totalAnnualCents / 100 / 12,
      annualRevenue: totalAnnualCents / 100,
      monthlySubscriptionRevenue: monthlySubscriptionRevenue,
      fullPlanCount: fullPlanCount,
      fullPlanAnnualRevenue: fullPlanAnnualCents / 100,
      mediumPlanCount: mediumPlanCount,
      mediumPlanAnnualRevenue: mediumPlanAnnualCents / 100,
      lightPlanCount: lightPlanCount,
      lightPlanAnnualRevenue: lightPlanAnnualCents / 100,
      trialingCount: trialingCount,
      protectedChildren: self.protectedChildren(in: context),
      totalAccounts: data.overview.allTimeSignups,
      recentSignups: signups,
    )
  }

  static func protectedChildren(in context: Context) async throws -> Int {
    try await context.db.count(ProtectedChildrenCount.self)
  }
}

private struct ProtectedChildrenCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let parentId = Parent.columnName(.id)
    let parentEmail = Parent.columnName(.email)
    let parentEmailVerifiedAt = Parent.columnName(.emailVerifiedAt)
    let childId = Child.columnName(.id)
    let childParentId = Child.columnName(.parentId)
    let childFilteringDisabled = Child.columnName(.filteringDisabled)
    let computerId = Computer.columnName(.id)
    let computerParentId = Computer.columnName(.parentId)
    let computerUserId = ComputerUser.columnName(.id)
    let computerUserChildId = ComputerUser.columnName(.childId)
    let computerUserComputerId = ComputerUser.columnName(.computerId)
    let notificationParentId = Parent.Notification.columnName(.parentId)
    let keychainId = Keychain.columnName(.id)
    let keychainParentId = Keychain.columnName(.parentId)
    let keychainIsPublic = Keychain.columnName(.isPublic)
    let keyKeychainId = Key.columnName(.keychainId)
    let screenshotComputerUserId = Screenshot.columnName(.computerUserId)
    let keystrokeComputerUserId = KeystrokeLine.columnName(.computerUserId)
    let iosDeviceId = IOSDevice.columnName(.id)
    let iosDeviceChildId = IOSDevice.columnName(.childId)
    let iosEventDeviceId = IOSEvent.columnName(.deviceId)
    let iosEventEventId = IOSEvent.columnName(.eventId)
    let supervisionDeviceId = BlockerApp.Supervision.columnName(.deviceId)
    let supervisionProfileInstalledAt = BlockerApp.Supervision.columnName(.profileInstalledAt)
    let blockerInstallId = BlockerApp.Install.columnName(.id)
    let blockerInstallDeviceId = BlockerApp.Install.columnName(.deviceId)
    let blockerTokenInstallId = BlockerApp.Token.columnName(.installId)
    let podcastDeviceId = PodcastEvent.columnName(.deviceId)
    let podcastEventId = PodcastEvent.columnName(.eventId)
    let podcastCreatedAt = PodcastEvent.columnName(.createdAt)
    let musicInstallId = MusicApp.Install.columnName(.id)
    let musicInstallDeviceId = MusicApp.Install.columnName(.deviceId)
    let musicTokenInstallId = MusicApp.Token.columnName(.installId)
    return SQL.Statement("""
    WITH verified_parents AS (
      SELECT \(parentId) AS parent_id
      FROM \(table: Parent.self)
      WHERE \(parentEmailVerifiedAt) IS NOT NULL
        AND \(parentEmail) NOT LIKE '%.smoke-test-%'
        AND \(parentEmail) NOT LIKE 'e2e-user-%'
    ),
    active_mac_parents AS (
      SELECT vp.parent_id
      FROM verified_parents vp
      WHERE EXISTS (
          SELECT 1
          FROM \(table: Computer.self) pc
          JOIN \(table: ComputerUser.self) cu
            ON cu.\(computerUserComputerId) = pc.\(computerId)
          WHERE pc.\(computerParentId) = vp.parent_id
        )
        AND EXISTS (
          SELECT 1
          FROM \(table: Parent.Notification.self) n
          WHERE n.\(notificationParentId) = vp.parent_id
        )
        AND (
          EXISTS (
            SELECT 1
            FROM \(table: Keychain.self) kc
            JOIN \(table: Key.self) k
              ON k.\(keyKeychainId) = kc.\(keychainId)
            WHERE kc.\(keychainParentId) = vp.parent_id
              AND kc.\(keychainIsPublic) = false
          )
          OR EXISTS (
            SELECT 1
            FROM \(table: Computer.self) pc
            JOIN \(table: ComputerUser.self) cu
              ON cu.\(computerUserComputerId) = pc.\(computerId)
            LEFT JOIN \(table: Screenshot.self) ss
              ON ss.\(screenshotComputerUserId) = cu.\(computerUserId)
            LEFT JOIN \(table: KeystrokeLine.self) kl
              ON kl.\(keystrokeComputerUserId) = cu.\(computerUserId)
            WHERE pc.\(computerParentId) = vp.parent_id
              AND (ss.id IS NOT NULL OR kl.id IS NOT NULL)
          )
          OR EXISTS (
            SELECT 1
            FROM \(table: Child.self) c
            JOIN \(table: ComputerUser.self) cu
              ON cu.\(computerUserChildId) = c.\(childId)
            WHERE c.\(childParentId) = vp.parent_id
              AND c.\(childFilteringDisabled) = true
          )
        )
    ),
    mac_subjects AS (
      SELECT 'child:' || c.\(childId)::text AS subject_key
      FROM \(table: Child.self) c
      JOIN active_mac_parents amp ON amp.parent_id = c.\(childParentId)
    ),
    screen_time_success_devices AS (
      SELECT DISTINCT e.\(iosEventDeviceId) AS device_id
      FROM \(table: IOSEvent.self) e
      WHERE e.\(iosEventDeviceId) IS NOT NULL
        AND e.\(iosEventEventId) = 'cdb31095'
        AND e.\(iosEventDeviceId) IN (
          SELECT \(iosEventDeviceId) FROM \(table: IOSEvent
      .self) WHERE \(iosEventEventId) = '4a0c585f'
        )
        AND e.\(iosEventDeviceId) NOT IN (
          SELECT \(iosEventDeviceId) FROM \(table: IOSEvent
      .self) WHERE \(iosEventEventId) = 'bad8adcc'
        )
        AND e.\(iosEventDeviceId) NOT IN (
          SELECT \(supervisionDeviceId) FROM \(table: BlockerApp.Supervision.self)
          WHERE \(supervisionProfileInstalledAt) IS NOT NULL
        )
    ),
    configurator_success_devices AS (
      SELECT DISTINCT e.\(iosEventDeviceId) AS device_id
      FROM \(table: IOSEvent.self) e
      WHERE e.\(iosEventDeviceId) IS NOT NULL
        AND e.\(iosEventEventId) = '8d35f043'
        AND e.\(iosEventDeviceId) IN (
          SELECT \(iosEventDeviceId) FROM \(table: IOSEvent
      .self) WHERE \(iosEventEventId) = 'bad8adcc'
        )
    ),
    gertrude_supervision_success_devices AS (
      SELECT DISTINCT e.\(iosEventDeviceId) AS device_id
      FROM \(table: IOSEvent.self) e
      WHERE e.\(iosEventDeviceId) IS NOT NULL
        AND e.\(iosEventEventId) = '8d35f043'
        AND e.\(iosEventDeviceId) IN (
          SELECT \(supervisionDeviceId) FROM \(table: BlockerApp.Supervision.self)
          WHERE \(supervisionProfileInstalledAt) IS NOT NULL
        )
        AND e.\(iosEventDeviceId) NOT IN (
          SELECT \(iosEventDeviceId) FROM \(table: IOSEvent
      .self) WHERE \(iosEventEventId) = 'bad8adcc'
        )
    ),
    non_supervised_connection_success_devices AS (
      SELECT DISTINCT e.\(iosEventDeviceId) AS device_id
      FROM \(table: IOSEvent.self) e
      JOIN \(table: BlockerApp.Install.self) i
        ON i.\(blockerInstallDeviceId) = e.\(iosEventDeviceId)
      JOIN \(table: BlockerApp.Token.self) t
        ON t.\(blockerTokenInstallId) = i.\(blockerInstallId)
      WHERE e.\(iosEventDeviceId) IS NOT NULL
        AND e.\(iosEventEventId) = '8d35f043'
        AND e.\(iosEventDeviceId) NOT IN (
          SELECT \(supervisionDeviceId) FROM \(table: BlockerApp.Supervision.self)
          WHERE \(supervisionProfileInstalledAt) IS NOT NULL
        )
        AND e.\(iosEventDeviceId) NOT IN (
          SELECT \(iosEventDeviceId) FROM \(table: IOSEvent
      .self) WHERE \(iosEventEventId) = 'bad8adcc'
        )
    ),
    ios_success_devices AS (
      SELECT device_id FROM screen_time_success_devices
      UNION
      SELECT device_id FROM configurator_success_devices
      UNION
      SELECT device_id FROM gertrude_supervision_success_devices
      UNION
      SELECT device_id FROM non_supervised_connection_success_devices
    ),
    ios_subjects AS (
      SELECT DISTINCT COALESCE(
        'child:' || d.\(iosDeviceChildId)::text,
        'ios-device:' || d.\(iosDeviceId)::text
      ) AS subject_key
      FROM \(table: IOSDevice.self) d
      JOIN ios_success_devices s ON s.device_id = d.\(iosDeviceId)
    ),
    podcast_active_devices AS (
      SELECT DISTINCT \(podcastDeviceId) AS device_id
      FROM \(table: PodcastEvent.self)
      WHERE \(podcastDeviceId) IS NOT NULL
        AND (
          (\(podcastEventId) = '27c4f26a' AND \(podcastCreatedAt) >= NOW() - INTERVAL '30 days')
          OR (\(hostPurchasePodcastEventPredicateSQL))
        )
    ),
    podcast_subjects AS (
      SELECT DISTINCT COALESCE(
        'child:' || d.\(iosDeviceChildId)::text,
        'ios-device:' || d.\(iosDeviceId)::text
      ) AS subject_key
      FROM \(table: IOSDevice.self) d
      JOIN podcast_active_devices p ON p.device_id = d.\(iosDeviceId)
    ),
    music_connected_devices AS (
      SELECT DISTINCT i.\(musicInstallDeviceId) AS device_id
      FROM \(table: MusicApp.Install.self) i
      JOIN \(table: MusicApp.Token.self) t
        ON t.\(musicTokenInstallId) = i.\(musicInstallId)
    ),
    music_subjects AS (
      SELECT DISTINCT COALESCE(
        'child:' || d.\(iosDeviceChildId)::text,
        'ios-device:' || d.\(iosDeviceId)::text
      ) AS subject_key
      FROM \(table: IOSDevice.self) d
      JOIN music_connected_devices m ON m.device_id = d.\(iosDeviceId)
    ),
    protected_subjects AS (
      SELECT subject_key FROM mac_subjects
      UNION
      SELECT subject_key FROM ios_subjects
      UNION
      SELECT subject_key FROM podcast_subjects
      UNION
      SELECT subject_key FROM music_subjects
    )
    SELECT COUNT(DISTINCT subject_key) AS count
    FROM protected_subjects
    """)
  }

  var count: Int
}

private struct MonthlySubscriptionRevenue: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    guard bindings.count == 1 else {
      return SQL.Statement("SELECT NULL WHERE FALSE")
    }
    var stmt = SQL.Statement(
      """
      WITH raw_events AS MATERIALIZED (
        SELECT
          \(StripeEvent.columnName(.json))::jsonb AS raw_json,
          \(StripeEvent.columnName(.createdAt)) AS received_at
        FROM \(table: StripeEvent.self)
      ),
      normalized_events AS MATERIALIZED (
        SELECT
          CASE
            WHEN raw_json ? 'json'
              AND LEFT(LTRIM(raw_json->>'json'), 1) = '{'
            THEN (raw_json->>'json')::jsonb
            ELSE raw_json
          END AS event_json,
          received_at
        FROM raw_events
      ),
      invoice_events AS MATERIALIZED (
        SELECT
          COALESCE(
            to_timestamp(NULLIF(event_json->>'created', '')::bigint),
            received_at
          ) AS event_time,
          event_json #>> '{data,object,id}' AS invoice_id,
          COALESCE((event_json #>> '{data,object,amount_paid}')::int, 0) AS cents_collected,
          event_json #>> '{data,object,lines,data,0,price,recurring,interval}' AS interval,
          COALESCE(
            (NULLIF(event_json #>> '{data,object,lines,data,0,price,unit_amount}', ''))::int,
            0
          ) AS unit_amount,
          (event_json #>> '{data,object,lines,data,0,price,id}') =
      """)
    stmt.components.append(.binding(bindings[0]))
    stmt.components.append(.sql(
      """
       AS is_medium
        FROM normalized_events
        WHERE event_json->>'type' = 'invoice.paid'
      ),
      deduped_invoice_events AS MATERIALIZED (
        SELECT DISTINCT ON (invoice_id)
          invoice_id,
          event_time,
          cents_collected,
          CASE
            WHEN interval = 'month' AND COALESCE(is_medium, false) THEN 0
            WHEN interval = 'month' AND unit_amount IN (500, 1000, 1500) THEN cents_collected
            ELSE 0
          END AS full_plan_cents,
          CASE
            WHEN interval = 'month' AND COALESCE(is_medium, false) THEN cents_collected
            ELSE 0
          END AS medium_plan_cents,
          CASE
            WHEN interval = 'year' AND unit_amount = 1000 THEN cents_collected
            ELSE 0
          END AS light_plan_cents,
          CASE
            WHEN interval = 'month' AND COALESCE(is_medium, false) THEN 0
            WHEN interval = 'month' AND unit_amount IN (500, 1000, 1500) THEN 0
            WHEN interval = 'year' AND unit_amount = 1000 THEN 0
            ELSE cents_collected
          END AS other_cents
        FROM invoice_events
        WHERE invoice_id IS NOT NULL
          AND cents_collected > 0
        ORDER BY invoice_id, event_time DESC
      ),
      monthly AS (
        SELECT
          date_trunc('month', event_time) AS month_start,
          SUM(cents_collected)::int AS cents_collected,
          SUM(full_plan_cents)::int AS full_plan_cents,
          SUM(medium_plan_cents)::int AS medium_plan_cents,
          SUM(light_plan_cents)::int AS light_plan_cents,
          SUM(other_cents)::int AS other_cents,
          COUNT(*)::int AS paid_invoices
        FROM deduped_invoice_events
        GROUP BY month_start
      ),
      bounds AS (
        SELECT
          date_trunc('month', MIN(event_time)) AS min_month,
          date_trunc('month', NOW()) AS max_month
        FROM deduped_invoice_events
      ),
      months AS (
        SELECT generate_series(min_month, max_month, interval '1 month') AS month_start
        FROM bounds
        WHERE min_month IS NOT NULL
      )
      SELECT
        TO_CHAR(months.month_start, 'YYYY-MM') AS month,
        COALESCE(monthly.cents_collected, 0)::int AS cents_collected,
        COALESCE(monthly.full_plan_cents, 0)::int AS full_plan_cents,
        COALESCE(monthly.medium_plan_cents, 0)::int AS medium_plan_cents,
        COALESCE(monthly.light_plan_cents, 0)::int AS light_plan_cents,
        COALESCE(monthly.other_cents, 0)::int AS other_cents,
        COALESCE(monthly.paid_invoices, 0)::int AS paid_invoices
      FROM months
      LEFT JOIN monthly USING (month_start)
      ORDER BY months.month_start
      """))
    return stmt
  }

  var month: String
  var centsCollected: Int
  var fullPlanCents: Int
  var mediumPlanCents: Int
  var lightPlanCents: Int
  var otherCents: Int
  var paidInvoices: Int
}
