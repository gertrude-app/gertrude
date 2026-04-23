import DuetSQL
import Gertie
import PairQL

struct SendMarketingCampaign: Pair {
  static let auth: ClientAuth = .superAdmin

  enum Slug: String, CaseIterable, PairNestable {
    case macV291Announce = "mac_v2_9_1_announce"
    case iosOnlyMacTrial = "ios_only_mac_trial"
  }

  struct Input: PairInput {
    let campaign: Slug
    let dryRun: Bool
    let limit: Int?
  }

  struct Output: PairOutput {
    let audienceSize: Int
    let alreadySent: Int
    let eligible: Int
    let sent: Int
    let failed: Int
    let audience: [String]
    let toSend: [String]
  }
}

extension SendMarketingCampaign: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let audience: [(Parent.Id, EmailAddress, [String: String])] = switch input.campaign {
    case .macV291Announce:
      try await audienceForMacV291Announce(in: context)
        .map { ($0.0, $0.1, V2_9_1_Announce().templateModel) }
    case .iosOnlyMacTrial:
      try await audienceForIosOnlyMacTrial(in: context)
    }

    let templateAlias: String
    let from: String
    let replyTo: String?
    switch input.campaign {
    case .macV291Announce:
      templateAlias = V2_9_1_Announce.alias
      from = "Jared from Gertrude <jared@gertrude.app>"
      replyTo = "jared@netrivet.com"
    case .iosOnlyMacTrial:
      templateAlias = IosOnlyMacTrial.alias
      from = "Jared Henderson <jared@gertrude.app>"
      replyTo = "jared@netrivet.com"
    }

    let prior = try await MarketingEmailSend.query()
      .where(.campaign == .string(input.campaign.rawValue))
      .all(in: context.db)
    let alreadySent = Set(prior.map(\.parentId))
    let eligible = audience.filter { !alreadySent.contains($0.0) }
    let toSend = if let limit = input.limit { Array(eligible.prefix(limit)) } else { eligible }

    if input.dryRun || toSend.isEmpty {
      return Output(
        audienceSize: audience.count,
        alreadySent: alreadySent.count,
        eligible: eligible.count,
        sent: 0,
        failed: 0,
        audience: audience.map(\.1.rawValue),
        toSend: toSend.map(\.1.rawValue),
      )
    }

    let postmark = get(dependency: \.postmark)
    let results = await postmark.sendMarketingBatch(
      templateAlias: templateAlias,
      campaignSlug: input.campaign.rawValue,
      recipients: toSend.map { (email: $0.1.rawValue, model: $0.2) },
      from: from,
      replyTo: replyTo,
    )

    var sent = 0
    var failed = 0
    var successRows: [MarketingEmailSend] = []
    for (recipient, result) in zip(toSend, results) {
      switch result {
      case .success:
        sent += 1
        successRows.append(MarketingEmailSend(
          parentId: recipient.0,
          campaign: input.campaign.rawValue,
        ))
      case .failure:
        failed += 1
      }
    }
    if !successRows.isEmpty {
      try await context.db.create(successRows)
    }

    return Output(
      audienceSize: audience.count,
      alreadySent: alreadySent.count,
      eligible: eligible.count,
      sent: sent,
      failed: failed,
      audience: audience.map(\.1.rawValue),
      toSend: toSend.map(\.1.rawValue),
    )
  }
}

// NB: ephemeral query, remove after campaign sent
struct MacV291AnnounceAudience: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    WITH mac_parents AS (
      SELECT p.id, p.email, MAX(cu.updated_at) AS last_active
        FROM parent.parents p
        JOIN parent.computers c ON c.parent_id = p.id
        JOIN child.computer_users cu ON cu.computer_id = c.id
       WHERE p.email_verified_at IS NOT NULL
       GROUP BY p.id, p.email
    )
    SELECT DISTINCT mp.id, mp.email
      FROM mac_parents mp
      LEFT JOIN parent.subscriptions s ON s.parent_id = mp.id
     WHERE s.billing_status = 'paid'
        OR (s.billing_status = 'unpaid' AND s.tier = 'full'
            AND mp.last_active > NOW() - INTERVAL '365 days')
     ORDER BY mp.email
    """)
  }

  var id: Parent.Id
  var email: EmailAddress
}

private func audienceForMacV291Announce(
  in context: Context,
) async throws -> [(Parent.Id, EmailAddress)] {
  let rows = try await context.db.customQuery(MacV291AnnounceAudience.self)
  return rows.map { ($0.id, $0.email) }
}

struct IosOnlyMacTrialAudience: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    WITH audience AS (
      SELECT p.id, p.email
        FROM parent.parents p
       WHERE EXISTS (
         SELECT 1 FROM parent.children c
           JOIN child.ios_devices d ON d.child_id = c.id
           JOIN child.iosapp_tokens t ON t.device_id = d.id
          WHERE c.parent_id = p.id
       )
       AND NOT EXISTS (SELECT 1 FROM parent.computers cmp WHERE cmp.parent_id = p.id)
       AND NOT EXISTS (
         SELECT 1 FROM parent.subscriptions s
          WHERE s.parent_id = p.id
            AND s.tier = 'full'
            AND s.billing_status IS NULL
       )
    )
    SELECT
      a.id,
      a.email,
      c.name AS child_name,
      string_agg(DISTINCT SUBSTRING(d.model_identifier FROM '^[A-Za-z]+'), ','
                 ORDER BY SUBSTRING(d.model_identifier FROM '^[A-Za-z]+')) AS device_kinds,
      c.created_at AS child_created_at
    FROM audience a
    JOIN parent.children c ON c.parent_id = a.id
    JOIN child.ios_devices d ON d.child_id = c.id
    JOIN child.iosapp_tokens t ON t.device_id = d.id
    GROUP BY a.id, a.email, c.id, c.name, c.created_at
    ORDER BY a.email, c.created_at ASC
    """)
  }

  var id: Parent.Id
  var email: EmailAddress
  var childName: String
  var deviceKinds: String
  var childCreatedAt: Date
}

private func audienceForIosOnlyMacTrial(
  in context: Context,
) async throws -> [(Parent.Id, EmailAddress, [String: String])] {
  let rows = try await context.db.customQuery(IosOnlyMacTrialAudience.self)
  // group by parent, preserving row order (already sorted by email, child_created_at)
  var order: [Parent.Id] = []
  var byParent: [Parent.Id: (email: EmailAddress, kids: [IosOnlyMacTrialKid])] = [:]
  for row in rows {
    let kinds = row.deviceKinds
      .split(separator: ",")
      .compactMap { DeviceKind(rawModelPrefix: String($0)) }
    if byParent[row.id] == nil {
      order.append(row.id)
      byParent[row.id] = (row.email, [])
    }
    byParent[row.id]!.kids.append(.init(name: row.childName, kinds: Set(kinds)))
  }
  return order.map { parentId in
    let entry = byParent[parentId]!
    let fragment = iosOnlyMacTrialFragment(email: entry.email.rawValue, kids: entry.kids)
    return (parentId, entry.email, ["deviceFragment": fragment])
  }
}
