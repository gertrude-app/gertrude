import Dependencies
import DuetSQL
import Foundation
import PairQL

struct CohortAnalysis: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var generatedAt: Date
    var cohorts: [Cohort]
  }

  struct Cohort: PairNestable {
    var month: String
    var verifiedSignups: Int
    var paidIntentCount: Int
    var paidIntentEverPaidCount: Int
    var paidIntentPayingCount: Int
    var freeIosCount: Int
    var freeIosProtectedCount: Int
    var protectedCount: Int
    var macProtectedCount: Int
    var iosProtectedCount: Int
    var everPaidCount: Int
    var currentlyPayingCount: Int
  }
}

extension CohortAnalysis: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    @Dependency(\.date.now) var now
    let cohorts = try await context.db.customQuery(CohortRowsQuery.self)
      .map { row in
        Cohort(
          month: row.month,
          verifiedSignups: row.verifiedSignups,
          paidIntentCount: row.paidIntentCount,
          paidIntentEverPaidCount: row.paidIntentEverPaidCount,
          paidIntentPayingCount: row.paidIntentPayingCount,
          freeIosCount: row.freeIosCount,
          freeIosProtectedCount: row.freeIosProtectedCount,
          protectedCount: row.protectedCount,
          macProtectedCount: row.macProtectedCount,
          iosProtectedCount: row.iosProtectedCount,
          everPaidCount: row.everPaidCount,
          currentlyPayingCount: row.currentlyPayingCount,
        )
      }
    return .init(generatedAt: now, cohorts: cohorts)
  }
}

private enum IOSProtectionEvent {
  static let firstLaunch = "8d35f043"
  static let screenTimeAuthSuccess = "4a0c585f"
  static let blockGroupsSuccess = "cdb31095"
  static let supervisionFirstLaunch = "bad8adcc"
}

private struct CohortRowsQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let pId = Parent.columnName(.id)
    let pEmail = Parent.columnName(.email)
    let pVerified = Parent.columnName(.emailVerifiedAt)
    let pCreated = Parent.columnName(.createdAt)
    let cId = Child.columnName(.id)
    let cParent = Child.columnName(.parentId)
    let cFiltering = Child.columnName(.filteringDisabled)
    let cuId = ComputerUser.columnName(.id)
    let cuChild = ComputerUser.columnName(.childId)
    let ssUser = Screenshot.columnName(.computerUserId)
    let klUser = KeystrokeLine.columnName(.computerUserId)
    let ckChild = ChildKeychain.columnName(.childId)
    let ckKeychain = ChildKeychain.columnName(.keychainId)
    let kcId = Keychain.columnName(.id)
    let keyKeychain = Key.columnName(.keychainId)
    let keyDeleted = Key.columnName(.deletedAt)
    let dId = IOSDevice.columnName(.id)
    let dChild = IOSDevice.columnName(.childId)
    let eDevice = IOSEvent.columnName(.deviceId)
    let eEvent = IOSEvent.columnName(.eventId)
    let supDevice = BlockerApp.Supervision.columnName(.deviceId)
    let supInstalled = BlockerApp.Supervision.columnName(.profileInstalledAt)
    let iId = BlockerApp.Install.columnName(.id)
    let iDevice = BlockerApp.Install.columnName(.deviceId)
    let tInstall = BlockerApp.Token.columnName(.installId)
    let biParent = BillingIdentity.columnName(.parentId)
    let biCustomer = BillingIdentity.columnName(.stripeCustomerId)
    let subParent = StripeSubscription.columnName(.parentId)
    let subStatus = StripeSubscription.columnName(.stripeStatus)
    let seJson = StripeEvent.columnName(.json)

    let firstLaunch = IOSProtectionEvent.firstLaunch
    let screenTimeAuth = IOSProtectionEvent.screenTimeAuthSuccess
    let blockGroups = IOSProtectionEvent.blockGroupsSuccess
    let supFirstLaunch = IOSProtectionEvent.supervisionFirstLaunch

    return SQL.Statement(
      """
      WITH verified_parents AS (
        SELECT \(pId) AS parent_id,
               TO_CHAR(date_trunc('month', \(pCreated)), 'YYYY-MM') AS month
        FROM \(table: Parent.self)
        WHERE \(pVerified) IS NOT NULL
          AND \(pEmail) NOT LIKE '%.smoke-test-%'
          AND \(pEmail) NOT LIKE 'e2e-user-%'
      ),
      mac_protected_parents AS (
        SELECT DISTINCT c.\(cParent) AS parent_id
        FROM \(table: Child.self) c
        WHERE EXISTS (
          SELECT 1 FROM \(table: ComputerUser.self) cu
          WHERE cu.\(cuChild) = c.\(cId)
            AND (
              EXISTS (
                SELECT 1 FROM \(table: Screenshot.self) s
                WHERE s.\(ssUser) = cu.\(cuId)
              )
              OR EXISTS (
                SELECT 1 FROM \(table: KeystrokeLine.self) kl
                WHERE kl.\(klUser) = cu.\(cuId)
              )
            )
        )
        AND (
          c.\(cFiltering) = true
          OR EXISTS (
            SELECT 1 FROM \(table: ChildKeychain.self) ck
            JOIN \(table: Keychain.self) kc ON kc.\(kcId) = ck.\(ckKeychain)
            JOIN \(table: Key.self) k
              ON k.\(keyKeychain) = kc.\(kcId) AND k.\(keyDeleted) IS NULL
            WHERE ck.\(ckChild) = c.\(cId)
          )
        )
      ),
      ios_protected_parents AS (
        SELECT DISTINCT c.\(cParent) AS parent_id
        FROM \(table: IOSDevice.self) d
        JOIN \(table: Child.self) c ON c.\(cId) = d.\(dChild)
        WHERE d.\(dChild) IS NOT NULL
          AND (
            (
              EXISTS (SELECT 1 FROM \(table: IOSEvent.self) e
                WHERE e.\(eDevice) = d.\(dId) AND e.\(eEvent) = '\(blockGroups)')
              AND EXISTS (SELECT 1 FROM \(table: IOSEvent.self) e
                WHERE e.\(eDevice) = d.\(dId) AND e.\(eEvent) = '\(screenTimeAuth)')
              AND NOT EXISTS (SELECT 1 FROM \(table: IOSEvent.self) e
                WHERE e.\(eDevice) = d.\(dId) AND e.\(eEvent) = '\(supFirstLaunch)')
              AND NOT EXISTS (SELECT 1 FROM \(table: BlockerApp.Supervision.self) s
                WHERE s.\(supDevice) = d.\(dId) AND s.\(supInstalled) IS NOT NULL)
            )
            OR (
              EXISTS (SELECT 1 FROM \(table: IOSEvent.self) e
                WHERE e.\(eDevice) = d.\(dId) AND e.\(eEvent) = '\(firstLaunch)')
              AND EXISTS (SELECT 1 FROM \(table: IOSEvent.self) e
                WHERE e.\(eDevice) = d.\(dId) AND e.\(eEvent) = '\(supFirstLaunch)')
            )
            OR (
              EXISTS (SELECT 1 FROM \(table: IOSEvent.self) e
                WHERE e.\(eDevice) = d.\(dId) AND e.\(eEvent) = '\(firstLaunch)')
              AND EXISTS (SELECT 1 FROM \(table: BlockerApp.Supervision.self) s
                WHERE s.\(supDevice) = d.\(dId) AND s.\(supInstalled) IS NOT NULL)
              AND NOT EXISTS (SELECT 1 FROM \(table: IOSEvent.self) e
                WHERE e.\(eDevice) = d.\(dId) AND e.\(eEvent) = '\(supFirstLaunch)')
            )
            OR (
              EXISTS (SELECT 1 FROM \(table: IOSEvent.self) e
                WHERE e.\(eDevice) = d.\(dId) AND e.\(eEvent) = '\(firstLaunch)')
              AND EXISTS (SELECT 1 FROM \(table: BlockerApp.Install.self) i
                JOIN \(table: BlockerApp.Token.self) t ON t.\(tInstall) = i.\(iId)
                WHERE i.\(iDevice) = d.\(dId))
              AND NOT EXISTS (SELECT 1 FROM \(table: BlockerApp.Supervision.self) s
                WHERE s.\(supDevice) = d.\(dId) AND s.\(supInstalled) IS NOT NULL)
              AND NOT EXISTS (SELECT 1 FROM \(table: IOSEvent.self) e
                WHERE e.\(eDevice) = d.\(dId) AND e.\(eEvent) = '\(supFirstLaunch)')
            )
          )
      ),
      paid_intent_parents AS (
        SELECT DISTINCT c.\(cParent) AS parent_id
        FROM \(table: Child.self) c
        WHERE EXISTS (
          SELECT 1 FROM \(table: ComputerUser.self) cu WHERE cu.\(cuChild) = c.\(cId)
        )
        UNION
        SELECT DISTINCT c.\(cParent) AS parent_id
        FROM \(table: IOSDevice.self) d
        JOIN \(table: Child.self) c ON c.\(cId) = d.\(dChild)
        WHERE EXISTS (
          SELECT 1 FROM \(table: BlockerApp.Supervision.self) s WHERE s.\(supDevice) = d.\(dId)
        )
      ),
      ios_account_parents AS (
        SELECT DISTINCT c.\(cParent) AS parent_id
        FROM \(table: IOSDevice.self) d
        JOIN \(table: Child.self) c ON c.\(cId) = d.\(dChild)
      ),
      paid_invoice_customers AS (
        SELECT DISTINCT event_json #>> '{data,object,customer}' AS customer_id
        FROM (
          SELECT
            CASE
              WHEN raw_json ? 'json'
                AND LEFT(LTRIM(raw_json->>'json'), 1) = '{'
              THEN (raw_json->>'json')::jsonb
              ELSE raw_json
            END AS event_json
          FROM (
            SELECT \(seJson)::jsonb AS raw_json FROM \(table: StripeEvent.self)
          ) raw_events
        ) normalized_events
        WHERE event_json->>'type' = 'invoice.paid'
          AND COALESCE((event_json #>> '{data,object,amount_paid}')::int, 0) > 0
          AND event_json #>> '{data,object,customer}' IS NOT NULL
      ),
      ever_paid_parents AS (
        SELECT DISTINCT bi.\(biParent) AS parent_id
        FROM \(table: BillingIdentity.self) bi
        JOIN paid_invoice_customers pic ON pic.customer_id = bi.\(biCustomer)
        WHERE bi.\(biCustomer) IS NOT NULL
      ),
      currently_paying_parents AS (
        SELECT DISTINCT \(subParent) AS parent_id
        FROM \(table: StripeSubscription.self)
        WHERE \(subStatus) = 'active'
      ),
      survivor_rows AS (
        SELECT
          vp.month AS month,
          COUNT(*)::int AS verified_signups,
          COUNT(*) FILTER (WHERE pi.parent_id IS NOT NULL)::int AS paid_intent_count,
          COUNT(*) FILTER (
            WHERE pi.parent_id IS NOT NULL AND ep.parent_id IS NOT NULL
          )::int AS paid_intent_ever_paid_count,
          COUNT(*) FILTER (
            WHERE pi.parent_id IS NOT NULL AND cp.parent_id IS NOT NULL
          )::int AS paid_intent_paying_count,
          COUNT(*) FILTER (
            WHERE ia.parent_id IS NOT NULL AND pi.parent_id IS NULL
          )::int AS free_ios_count,
          COUNT(*) FILTER (
            WHERE ia.parent_id IS NOT NULL AND pi.parent_id IS NULL
              AND ip.parent_id IS NOT NULL
          )::int AS free_ios_protected_count,
          COUNT(*) FILTER (
            WHERE mp.parent_id IS NOT NULL OR ip.parent_id IS NOT NULL
          )::int AS protected_count,
          COUNT(*) FILTER (WHERE mp.parent_id IS NOT NULL)::int AS mac_protected_count,
          COUNT(*) FILTER (WHERE ip.parent_id IS NOT NULL)::int AS ios_protected_count,
          COUNT(*) FILTER (WHERE ep.parent_id IS NOT NULL)::int AS ever_paid_count,
          COUNT(*) FILTER (
            WHERE cp.parent_id IS NOT NULL
          )::int AS currently_paying_count
        FROM verified_parents vp
        LEFT JOIN mac_protected_parents mp ON mp.parent_id = vp.parent_id
        LEFT JOIN ios_protected_parents ip ON ip.parent_id = vp.parent_id
        LEFT JOIN paid_intent_parents pi ON pi.parent_id = vp.parent_id
        LEFT JOIN ios_account_parents ia ON ia.parent_id = vp.parent_id
        LEFT JOIN ever_paid_parents ep ON ep.parent_id = vp.parent_id
        LEFT JOIN currently_paying_parents cp ON cp.parent_id = vp.parent_id
        GROUP BY vp.month
      )
      SELECT * FROM survivor_rows ORDER BY month
      """)
  }

  var month: String
  var verifiedSignups: Int
  var paidIntentCount: Int
  var paidIntentEverPaidCount: Int
  var paidIntentPayingCount: Int
  var freeIosCount: Int
  var freeIosProtectedCount: Int
  var protectedCount: Int
  var macProtectedCount: Int
  var iosProtectedCount: Int
  var everPaidCount: Int
  var currentlyPayingCount: Int
}
