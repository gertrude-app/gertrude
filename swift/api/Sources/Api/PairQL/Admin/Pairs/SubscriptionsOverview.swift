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
    var lightPlanCount: Int
    var lightPlanAnnualRevenue: Int
    var trialingCount: Int
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
    var lightPlanCents: Int
    var otherCents: Int
    var paidInvoices: Int
  }
}

extension SubscriptionsOverview: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let data = try await AnalyticsQuery.shared.data()

    var fullPlanCount = 0
    var fullPlanAnnualCents = 0
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
          || parent.hasConnectedPodcastApp {
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
      .customQuery(MonthlySubscriptionRevenue.self)
      .map { row in
        MonthlySubscriptionRevenueOutput(
          month: row.month,
          centsCollected: row.centsCollected,
          fullPlanCents: row.fullPlanCents,
          lightPlanCents: row.lightPlanCents,
          otherCents: row.otherCents,
          paidInvoices: row.paidInvoices,
        )
      }

    let totalAnnualCents = fullPlanAnnualCents + lightPlanAnnualCents
    return .init(
      monthlyRevenue: totalAnnualCents / 100 / 12,
      annualRevenue: totalAnnualCents / 100,
      monthlySubscriptionRevenue: monthlySubscriptionRevenue,
      fullPlanCount: fullPlanCount,
      fullPlanAnnualRevenue: fullPlanAnnualCents / 100,
      lightPlanCount: lightPlanCount,
      lightPlanAnnualRevenue: lightPlanAnnualCents / 100,
      trialingCount: trialingCount,
      totalAccounts: data.overview.allTimeSignups,
      recentSignups: signups,
    )
  }
}

private struct MonthlySubscriptionRevenue: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement(
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
          ) AS unit_amount
        FROM normalized_events
        WHERE event_json->>'type' = 'invoice.paid'
      ),
      deduped_invoice_events AS MATERIALIZED (
        SELECT DISTINCT ON (invoice_id)
          invoice_id,
          event_time,
          cents_collected,
          CASE
            WHEN interval = 'month' AND unit_amount IN (500, 1000, 1500) THEN cents_collected
            ELSE 0
          END AS full_plan_cents,
          CASE
            WHEN interval = 'year' AND unit_amount = 1000 THEN cents_collected
            ELSE 0
          END AS light_plan_cents,
          CASE
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
        COALESCE(monthly.light_plan_cents, 0)::int AS light_plan_cents,
        COALESCE(monthly.other_cents, 0)::int AS other_cents,
        COALESCE(monthly.paid_invoices, 0)::int AS paid_invoices
      FROM months
      LEFT JOIN monthly USING (month_start)
      ORDER BY months.month_start
      """)
  }

  var month: String
  var centsCollected: Int
  var fullPlanCents: Int
  var lightPlanCents: Int
  var otherCents: Int
  var paidInvoices: Int
}
