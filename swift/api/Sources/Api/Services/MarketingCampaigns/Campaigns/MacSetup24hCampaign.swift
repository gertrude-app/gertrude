import DuetSQL

struct MacSetup24hCampaign: MarketingCampaign {
  let slug = "mac_setup_24h"
  let templateAlias = MacSetup24h.alias
  let dashboardUrl: String

  func audience(in db: any DuetSQL.Client) async throws -> [MarketingCampaignRecipient] {
    let rows = try await db.customQuery(MacSetup24hAudienceRow.self)
    return rows.map {
      MarketingCampaignRecipient(
        parentId: $0.parentId,
        email: $0.email,
        templateModel: self.templateModel(for: $0),
      )
    }
  }

  private func templateModel(for row: MacSetup24hAudienceRow) -> [String: String] {
    let dashboardUrl = self.dashboardUrl.withoutTrailingSlashes
    if row.childCount == 1,
       let childId = row.childId,
       let childName = row.childName {
      return [
        "childName": childName,
        "dashboardUrl": dashboardUrl,
        "primaryCtaUrl": "\(dashboardUrl)/children/\(childId.lowercased)/mac",
      ]
    } else {
      return [
        "childName": "your child",
        "dashboardUrl": dashboardUrl,
        "primaryCtaUrl": "\(dashboardUrl)/children",
      ]
    }
  }
}

private struct MacSetup24hAudienceRow: CustomQueryable {
  var parentId: Parent.Id
  var email: EmailAddress
  var childCount: Int
  var childId: Child.Id?
  var childName: String?

  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let parentId = Parent.columnName(.id)
    let parentEmail = Parent.columnName(.email)
    let billingParentId = BillingIdentity.columnName(.parentId)
    let fullTrialStartedAt = BillingIdentity.columnName(.fullTrialStartedAt)
    let childId = Child.columnName(.id)
    let childParentId = Child.columnName(.parentId)
    let childName = Child.columnName(.name)
    let childCreatedAt = Child.columnName(.createdAt)
    let computerId = Computer.columnName(.id)
    let computerParentId = Computer.columnName(.parentId)
    let computerUserChildId = ComputerUser.columnName(.childId)
    let computerUserComputerId = ComputerUser.columnName(.computerId)

    let stmt = SQL.Statement(
      """
      SELECT
        p.\(parentId) AS parent_id,
        p.\(parentEmail) AS email,
        first_child.child_count,
        first_child.child_id,
        first_child.child_name
      FROM \(table: Parent.self) p
      JOIN \(table: BillingIdentity.self) bi ON bi.\(billingParentId) = p.\(parentId)
      JOIN (
        SELECT
          c.\(childParentId) AS parent_id,
          COUNT(*)::int AS child_count,
          MIN(c.\(childCreatedAt)) AS first_child_created_at,
          (ARRAY_AGG(c.\(childId) ORDER BY c.\(childCreatedAt), c.\(childId)))[1] AS child_id,
          (ARRAY_AGG(c.\(childName) ORDER BY c.\(childCreatedAt), c.\(childId)))[1] AS child_name
        FROM \(table: Child.self) c
        GROUP BY c.\(childParentId)
      ) first_child ON first_child.parent_id = p.\(parentId)
      WHERE bi.\(fullTrialStartedAt) IS NOT NULL
        AND bi.\(fullTrialStartedAt) > NOW() - INTERVAL '21 days'
        AND GREATEST(bi.\(fullTrialStartedAt), first_child.first_child_created_at)
          <= NOW() - INTERVAL '24 hours'
        AND NOT EXISTS (
          SELECT 1
          FROM \(table: Child.self) c
          JOIN \(table: ComputerUser.self) cu ON cu.\(computerUserChildId) = c.\(childId)
          JOIN \(table: Computer.self) cmp ON cmp.\(computerId) = cu.\(computerUserComputerId)
          WHERE c.\(childParentId) = p.\(parentId)
            AND cmp.\(computerParentId) = p.\(parentId)
        )
      ORDER BY p.\(parentEmail)
      """)
    return stmt
  }
}
