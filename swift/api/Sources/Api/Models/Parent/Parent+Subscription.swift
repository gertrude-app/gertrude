import DuetSQL

@dynamicMemberLookup
struct ParentWithSubscription: Sendable {
  let model: Parent
  let subscription: Subscription?

  subscript<T>(dynamicMember keyPath: KeyPath<Parent, T>) -> T {
    self.model[keyPath: keyPath]
  }
}

extension ParentWithSubscription {
  static func find(
    _ id: Parent.Id,
    in db: any DuetSQL.Client,
  ) async throws -> ParentWithSubscription {
    if let parent = try await db.customQuery(ParentSubscriptionRow.self, withBindings: [.uuid(id)])
      .first?
      .models {
      return parent
    } else {
      throw DuetSQLError.notFound("\(ParentWithSubscription.self)")
    }
  }

  static func all(in db: any DuetSQL.Client) async throws -> [ParentWithSubscription] {
    try await db.customQuery(ParentSubscriptionRow.self)
      .map(\.models)
  }
}

struct ParentSubscriptionRow: CustomQueryable {
  var pId: Parent.Id
  var pEmail: EmailAddress
  var pPassword: String
  var pGclid: String?
  var pAbTestVariant: String?
  var pEmailVerifiedAt: Date?
  var pCreatedAt: Date

  var sId: Subscription.Id?
  var sParentId: Parent.Id?
  var sTier: Subscription.Tier?
  var sBillingStatus: BillingStatus.Db?
  var sStripeId: Subscription.StripeId?
  var sIsLegacyPrice: Bool?
  var sTrialStartedAt: Date?
  var sStatusExpiresAt: Date?

  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    var stmt = SQL.Statement("""
    SELECT
      p.\(Parent.columnName(.id)) AS p_id,
      p.\(Parent.columnName(.email)) AS p_email,
      p.\(Parent.columnName(.password)) AS p_password,
      p.\(Parent.columnName(.gclid)) AS p_gclid,
      p.\(Parent.columnName(.abTestVariant)) AS p_ab_test_variant,
      p.\(Parent.columnName(.emailVerifiedAt)) AS p_email_verified_at,
      p.\(Parent.columnName(.createdAt)) AS p_created_at,
      s.\(Subscription.columnName(.id)) AS s_id,
      s.\(Subscription.columnName(.parentId)) AS s_parent_id,
      s.\(Subscription.columnName(.tier)) AS s_tier,
      s.\(Subscription.columnName(.billingStatus)) AS s_billing_status,
      s.\(Subscription.columnName(.stripeId)) AS s_stripe_id,
      s.\(Subscription.columnName(.isLegacyPrice)) AS s_is_legacy_price,
      s.\(Subscription.columnName(.trialStartedAt)) AS s_trial_started_at,
      s.\(Subscription.columnName(.statusExpiresAt)) AS s_status_expires_at
    FROM \(table: Parent.self) p
    LEFT JOIN \(table: Subscription.self) s
      ON s.\(Subscription.columnName(.parentId)) = p.\(Parent.columnName(.id))
    """)

    if let parentId = bindings.first {
      stmt.components.append(.sql(" WHERE p.\(Parent.columnName(.id)) = "))
      stmt.components.append(.binding(parentId))
    }

    return stmt
  }

  var models: ParentWithSubscription {
    let parent = Parent(
      id: pId,
      email: pEmail,
      password: pPassword,
      emailVerifiedAt: pEmailVerifiedAt,
      gclid: pGclid,
      abTestVariant: pAbTestVariant,
      createdAt: pCreatedAt,
    )

    let subscription: Subscription? = self.sId.flatMap { id in
      guard let parentId = sParentId, let tier = sTier,
            let isLegacyPrice = sIsLegacyPrice,
            let statusExpiresAt = sStatusExpiresAt else {
        return nil
      }
      var sub = Subscription(
        id: id,
        parentId: parentId,
        tier: tier,
        billingStatus: self.sBillingStatus,
        stripeId: self.sStripeId,
        trialStartedAt: self.sTrialStartedAt,
        statusExpiresAt: statusExpiresAt,
      )
      sub.isLegacyPrice = isLegacyPrice
      return sub
    }

    return ParentWithSubscription(model: parent, subscription: subscription)
  }
}
