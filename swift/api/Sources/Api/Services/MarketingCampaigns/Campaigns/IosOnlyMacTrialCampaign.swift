import DuetSQL

struct IosOnlyMacTrialCampaign: MarketingCampaign {
  let slug = "ios_only_mac_trial"
  let templateAlias = IosOnlyMacTrial.alias
  let variant = "v2"
  let from = "Jared Henderson <jared@gertrude.app>"
  let replyTo: String? = "jared@netrivet.com"

  func audience(in db: any DuetSQL.Client) async throws -> [MarketingCampaignRecipient] {
    let rows = try await db.customQuery(IosOnlyMacTrial7dAudienceRow.self)
    var order: [Parent.Id] = []
    var byParent: [Parent.Id: (email: EmailAddress, kids: [IosOnlyMacTrialKid])] = [:]
    for row in rows {
      let kinds = row.deviceKinds
        .split(separator: ",")
        .compactMap { DeviceKind(rawModelPrefix: String($0)) }
      if byParent[row.parentId] == nil {
        order.append(row.parentId)
        byParent[row.parentId] = (row.email, [])
      }
      byParent[row.parentId]!.kids.append(.init(name: row.childName, kinds: Set(kinds)))
    }
    return order.map { parentId in
      let entry = byParent[parentId]!
      return .init(
        parentId: parentId,
        email: entry.email,
        templateModel: [
          "deviceFragment": iosOnlyMacTrialFragment(
            email: entry.email.rawValue,
            kids: entry.kids,
          ),
        ],
      )
    }
  }
}

private struct IosOnlyMacTrial7dAudienceRow: CustomQueryable {
  var parentId: Parent.Id
  var email: EmailAddress
  var childName: String
  var deviceKinds: String
  var childCreatedAt: Date

  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let parentId = Parent.columnName(.id)
    let parentEmail = Parent.columnName(.email)
    let parentEmailVerifiedAt = Parent.columnName(.emailVerifiedAt)
    let billingParentId = BillingIdentity.columnName(.parentId)
    let fullTrialStartedAt = BillingIdentity.columnName(.fullTrialStartedAt)
    let isComplimentary = BillingIdentity.columnName(.isComplimentary)
    let childId = Child.columnName(.id)
    let childParentId = Child.columnName(.parentId)
    let childName = Child.columnName(.name)
    let childCreatedAt = Child.columnName(.createdAt)
    let deviceId = IOSDevice.columnName(.id)
    let deviceChildId = IOSDevice.columnName(.childId)
    let deviceModelIdentifier = IOSDevice.columnName(.modelIdentifier)
    let installId = BlockerApp.Install.columnName(.id)
    let installDeviceId = BlockerApp.Install.columnName(.deviceId)
    let tokenInstallId = BlockerApp.Token.columnName(.installId)
    let tokenCreatedAt = BlockerApp.Token.columnName(.createdAt)
    let eventDeviceId = IOSEvent.columnName(.deviceId)
    let eventId = IOSEvent.columnName(.eventId)
    let computerParentId = Computer.columnName(.parentId)
    let subscriptionParentId = StripeSubscription.columnName(.parentId)
    let subscriptionTier = StripeSubscription.columnName(.tier)
    let subscriptionStatus = StripeSubscription.columnName(.stripeStatus)

    return SQL.Statement(
      """
      WITH qualified_parents AS (
        SELECT p.\(parentId) AS parent_id, p.\(parentEmail) AS email
        FROM \(table: Parent.self) p
        JOIN (
          SELECT c.\(childParentId) AS parent_id, MIN(t.\(tokenCreatedAt)) AS first_ios_connected_at
          FROM \(table: Child.self) c
          JOIN \(table: IOSDevice.self) d ON d.\(deviceChildId) = c.\(childId)
          JOIN \(table: BlockerApp.Install.self) i ON i.\(installDeviceId) = d.\(deviceId)
          JOIN \(table: BlockerApp.Token.self) t ON t.\(tokenInstallId) = i.\(installId)
          WHERE EXISTS (
            SELECT 1
            FROM \(table: IOSEvent.self) e
            WHERE e.\(eventDeviceId) = d.\(deviceId)
              AND e.\(eventId) = 'b977cfdc'
          )
          GROUP BY c.\(childParentId)
        ) ios ON ios.parent_id = p.\(parentId)
        WHERE p.\(parentEmailVerifiedAt) IS NOT NULL
          AND ios.first_ios_connected_at <= NOW() - INTERVAL '7 days'
          AND NOT EXISTS (
            SELECT 1
            FROM \(table: BillingIdentity.self) bi
            WHERE bi.\(billingParentId) = p.\(parentId)
              AND (bi.\(fullTrialStartedAt) IS NOT NULL OR bi.\(isComplimentary) = TRUE)
          )
          AND NOT EXISTS (
            SELECT 1
            FROM \(table: StripeSubscription.self) s
            WHERE s.\(subscriptionParentId) = p.\(parentId)
              AND s.\(subscriptionTier) = 'full'
              AND s.\(subscriptionStatus) IN ('active', 'trialing', 'past_due')
          )
          AND NOT EXISTS (
            SELECT 1
            FROM \(table: Computer.self) cmp
            WHERE cmp.\(computerParentId) = p.\(parentId)
          )
      )
      SELECT
        qp.parent_id,
        qp.email,
        c.\(childName) AS child_name,
        string_agg(
          DISTINCT SUBSTRING(d.\(deviceModelIdentifier) FROM '^[A-Za-z]+'),
          ',' ORDER BY SUBSTRING(d.\(deviceModelIdentifier) FROM '^[A-Za-z]+')
        ) AS device_kinds,
        c.\(childCreatedAt) AS child_created_at
      FROM qualified_parents qp
      JOIN \(table: Child.self) c ON c.\(childParentId) = qp.parent_id
      JOIN \(table: IOSDevice.self) d ON d.\(deviceChildId) = c.\(childId)
      JOIN \(table: BlockerApp.Install.self) i ON i.\(installDeviceId) = d.\(deviceId)
      JOIN \(table: BlockerApp.Token.self) t ON t.\(tokenInstallId) = i.\(installId)
      GROUP BY qp.parent_id, qp.email, c.\(childId), c.\(childName), c.\(childCreatedAt)
      ORDER BY qp.email, c.\(childCreatedAt) ASC
      """)
  }
}
