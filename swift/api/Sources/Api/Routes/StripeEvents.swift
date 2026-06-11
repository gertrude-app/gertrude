import DuetSQL
import Gertie
import Vapor
import XCore
import XStripe

enum StripeEventsRoute {
  @Sendable static func handler(_ request: Request) async throws -> Response {
    guard let json = try await request.collectedBody() else {
      return Response(status: .badRequest)
    }

    if let webhookSecret = request.env.get("STRIPE_WEBHOOK_SECRET") {
      let signature = request.headers.first(name: "Stripe-Signature")
      if signature == nil ||
        !Stripe.Webhook.verifySignature(
          payload: json,
          signature: signature!,
          secret: webhookSecret,
          currentTime: get(dependency: \.date.now),
        ) {
        await get(dependency: \.slack).error("Stripe webhook signature verification failed")
        return Response(status: .unauthorized)
      }
    } else if request.context.env.mode == .prod {
      await get(dependency: \.slack).error("Production API missing STRIPE_WEBHOOK_SECRET")
      return Response(status: .unauthorized)
    }

    let event = try? JSON.decode(json, as: EventInfo.self)

    let stripeEvent: StripeEvent? = try await request.context.db.withTransaction { db in
      guard let stripeEvent = try await StripeEvent.insertIdempotent(
        json: json,
        stripeEventId: event?.id,
        in: db,
      ) else {
        return nil
      }

      switch event?.type {
      case "invoice.paid":
        try await handleInvoicePaid(event: event, stripeEvent: stripeEvent, db: db)
      case "customer.subscription.updated":
        try await handleSubscriptionUpdated(event: event, stripeEvent: stripeEvent, db: db)
      case "customer.subscription.deleted":
        try await handleSubscriptionDeleted(event: event, stripeEvent: stripeEvent, db: db)
      default:
        break
      }
      return stripeEvent
    }

    guard stripeEvent != nil else {
      return Response(status: .noContent)
    }

    slackNotify(event)
    return Response(status: .noContent)
  }
}

private func handleInvoicePaid(
  event: EventInfo?,
  stripeEvent: StripeEvent,
  db: any DuetSQL.Client,
) async throws {
  let amountDue = event?.data?.object?.amount_due ?? 0
  if amountDue <= 0 {
    return
  }

  let email = event?.data?.object?.customer_email
  let customerId = event?.data?.object?.customer

  var parent: Parent?

  if let customerId,
     let identity = try? await BillingIdentity.query()
     .where(.stripeCustomerId == .init(customerId))
     .first(in: db) {
    parent = try? await db.find(identity.parentId)
  }

  if parent == nil, let email {
    parent = try? await Parent.query()
      .where(.email == email.lowercased())
      .first(in: db)
  }

  // resolving from the subscription id allows for a different account for payment
  // a customer asked for this, he pays for himself but his "parent" is accountability
  // partner that has a different email/account, whom he did not want to have to pay
  if parent == nil {
    let subscription = try? await StripeSubscription.query()
      .where(.stripeId == .init(event?.data?.object?.subscription ?? ""))
      .first(in: db)
    if let subscription {
      parent = try await db.find(subscription.parentId)
    }
  }

  guard let parent else {
    unexpected(
      "b3aaf12c",
      detail: "email: \(email ?? "(nil)"), customer: \(customerId ?? "(nil)"), "
        + "event: \(stripeEvent.id)",
    )
    return
  }

  let priceId = event?.data?.object?.lines?.data?.first?.price?.id
  guard let eventTier = priceId.flatMap(StripeSubscription.Tier.init(stripePriceId:)) else {
    unexpected("bf3cad72", detail: "email: \(email ?? "(nil)"), event: \(stripeEvent.id)")
    return
  }

  guard let eventSubscriptionId = event?.data?.object?.subscription else {
    unexpected("d4e8f3c1", detail: "email: \(email ?? "(nil)"), event: \(stripeEvent.id)")
    return
  }

  let now = get(dependency: \.date.now)
  let periodEnd = event?.data?.object?.lines?.data?.first?.period?.end
    .map { Date(timeIntervalSince1970: TimeInterval($0)) }
    ?? now + .days(eventTier.periodLengthInDays)

  if var subscription = try await parent.subscription(in: db) {
    if subscription.stripeId.rawValue != eventSubscriptionId {
      let allow = try await reconcileDuplicateSubscription(
        parent: parent,
        existingSubId: subscription.stripeId.rawValue,
        incomingSubId: eventSubscriptionId,
        context: "stripe-webhook",
        audit: "stripe_event_id: \(stripeEvent.stripeEventId ?? "(nil)")",
        db: db,
      )
      guard allow else { return }
    }
    subscription.tier = eventTier
    subscription.stripeId = .init(eventSubscriptionId)
    subscription.stripeStatus = .active
    subscription.currentPeriodEnd = periodEnd
    try await db.update(subscription)

  } else {
    _ = try await parent.ensureBillingIdentity(in: db)
    try await db.create(StripeSubscription(
      parentId: parent.id,
      tier: eventTier,
      stripeId: .init(eventSubscriptionId),
      stripeStatus: .active,
      currentPeriodEnd: periodEnd,
    ))
    await recordPaidAdConversion(parent: parent, db: db)
    let referrer = try await parent.referrer(in: db)
    notifyFirstPayment(parent, eventTier, referrer)
  }

  if var identity = try await parent.billingIdentity(in: db) {
    var changed = false
    if let customerId, identity.stripeCustomerId?.rawValue != customerId {
      identity.stripeCustomerId = .init(customerId)
      changed = true
    }
    if identity.stripeCustomerId != nil,
       identity.lastStripeSubscriptionId?.rawValue != eventSubscriptionId {
      identity.lastStripeSubscriptionId = .init(eventSubscriptionId)
      changed = true
    }
    if identity.stripeCustomerId != nil, identity.lastPaidTier != eventTier {
      identity.lastPaidTier = eventTier
      changed = true
    }
    if changed {
      try await db.update(identity)
    }
  } else if let customerId {
    let identity = BillingIdentity(
      parentId: parent.id,
      stripeCustomerId: .init(customerId),
      lastStripeSubscriptionId: .init(eventSubscriptionId),
      lastPaidTier: eventTier,
    )
    try await db.create(identity)
  }
}

private func handleSubscriptionUpdated(
  event: EventInfo?,
  stripeEvent: StripeEvent,
  db: any DuetSQL.Client,
) async throws {
  guard let stripeSubId = event?.data?.object?.id else {
    unexpected("c92ad175", detail: "missing sub id, event: \(stripeEvent.id)")
    return
  }

  guard var subscription = try? await StripeSubscription.query()
    .where(.stripeId == .init(stripeSubId))
    .first(in: db) else {
    unexpected(
      "61f0e37c",
      detail: "no local sub for stripe sub id: \(stripeSubId), event: \(stripeEvent.id)",
    )
    return
  }

  let priceId = event?.data?.object?.items?.data?.first?.price?.id
  guard let eventTier = priceId.flatMap(StripeSubscription.Tier.init(stripePriceId:)) else {
    unexpected(
      "8e1cb204",
      detail: "unknown price id: \(priceId ?? "(nil)"), event: \(stripeEvent.id)",
    )
    return
  }

  guard let statusRaw = event?.data?.object?.status,
        let stripeStatus = StripeSubscription.StripeStatus(rawValue: statusRaw) else {
    unexpected(
      "33ec5b7f",
      detail: "unknown status: \(event?.data?.object?.status ?? "(nil)"), event: \(stripeEvent.id)",
    )
    return
  }

  if subscription.tier != eventTier {
    let fromTier = subscription.tier
    notifyUnexpectedTierChange(
      subscription.parentId,
      fromTier,
      eventTier,
      "customer.subscription.updated",
    )
    _ = try? await db.create(InterestingEvent(
      eventId: "tier_upgraded",
      kind: "billing",
      context: "stripe-webhook",
      parentId: subscription.parentId,
      detail: "from: \(fromTier.rawValue), to: \(eventTier.rawValue), "
        + "stripe_event_id: \(stripeEvent.stripeEventId ?? "(nil)")",
    ))
    subscription.tier = eventTier
  }

  subscription.stripeStatus = stripeStatus
  if let periodEnd = event?.data?.object?.current_period_end {
    subscription.currentPeriodEnd = Date(timeIntervalSince1970: TimeInterval(periodEnd))
  }
  try await db.update(subscription)

  if stripeStatus.isPaying, var identity = try await db.find(subscription.parentId)
    .billingIdentity(in: db) {
    var changed = false
    if let customer = event?.data?.object?.customer,
       identity.stripeCustomerId?.rawValue != customer {
      identity.stripeCustomerId = .init(customer)
      changed = true
    }
    if identity.stripeCustomerId != nil,
       identity.lastStripeSubscriptionId?.rawValue != stripeSubId {
      identity.lastStripeSubscriptionId = .init(stripeSubId)
      changed = true
    }
    if identity.stripeCustomerId != nil, identity.lastPaidTier != eventTier {
      identity.lastPaidTier = eventTier
      changed = true
    }
    if changed {
      try await db.update(identity)
    }
  }
}

private func handleSubscriptionDeleted(
  event: EventInfo?,
  stripeEvent: StripeEvent,
  db: any DuetSQL.Client,
) async throws {
  guard let stripeSubId = event?.data?.object?.id else {
    return
  }

  guard var subscription = try? await StripeSubscription.query()
    .where(.stripeId == .init(stripeSubId))
    .first(in: db) else {
    unexpected("a7c3d1e5", detail: "stripe sub id: \(stripeSubId), event: \(stripeEvent.id)")
    return
  }

  subscription.stripeStatus = .canceled
  try await db.update(subscription)

  let parent = try await db.find(subscription.parentId) as Parent
  notifySubscriptionCancelled(parent: parent, details: event?.data?.object?.cancellation_details)
}

private func slackNotify(_ event: EventInfo?) {
  var message = """
    *Received Gertrude Stripe Event:*
    - type: `\(event?.type ?? "(nil)")`
    - customer email: `\(event?.data?.object?.customer_email ?? "(nil)")`
  """
  if event?.type == "customer.subscription.deleted" {
    message += "\n- cancellation: `\(event?.data?.object?.cancellation_details?.reason ?? "(nil)")`"
  }
  Task {
    await get(dependency: \.slack).internal(.stripe, message)
  }
}

private struct EventInfo: Decodable {
  struct Data: Decodable {
    struct Object: Decodable {
      var id: String?

      struct CancellationDetails: Decodable {
        var comment: String?
        var feedback: String?
        var reason: String?
      }

      struct Lines: Decodable {
        struct Line: Decodable {
          struct Period: Decodable {
            var end: Int?
          }

          struct Price: Decodable {
            var id: String?
          }

          var period: Period?
          var price: Price?
        }

        var data: [Line]?
      }

      struct Items: Decodable {
        struct Item: Decodable {
          struct Price: Decodable {
            var id: String?
          }

          var price: Price?
        }

        var data: [Item]?
      }

      var amount_due: Int?
      var customer: String?
      var customer_email: String?
      var cancellation_details: CancellationDetails?
      var lines: Lines?
      var items: Items?
      var subscription: String?
      var status: String?
      var current_period_end: Int?
    }

    var object: Object?
  }

  var id: String?
  var type: String?
  var data: Data?
}

func recordPaidAdConversion(parent: Parent, db: any DuetSQL.Client) async {
  guard let gclid = parent.gclid else { return }
  let alreadyRecorded = try? await InterestingEvent.query()
    .where(.eventId == "g-ad-paid-conversion")
    .where(.parentId == parent.id)
    .exists(in: db)
  guard alreadyRecorded == false else { return }
  _ = try? await db.create(InterestingEvent(
    eventId: "g-ad-paid-conversion",
    kind: "event",
    context: "reporting",
    parentId: parent.id,
    detail: "gclid=\(gclid)",
  ))
}

private func notifySubscriptionCancelled(
  parent: Parent,
  details: EventInfo.Data.Object.CancellationDetails?,
) {
  let adminLink = AdminLink()
  let slackLink = adminLink.slack(to: .parent(parent.id), text: parent.email.rawValue)
  let emailLink = adminLink.email(to: .parent(parent.id), text: parent.email.rawValue)
  let reason = details?.reason ?? "(nil)"
  var body = "by \(emailLink)<br>stripe reason: \(reason)"
  if let feedback = details?.feedback, !feedback.isEmpty {
    body += "<br>feedback: \(feedback)"
  }
  if let comment = details?.comment, !comment.isEmpty {
    body += "<br>comment: \(comment)"
  }
  Task {
    await get(dependency: \.slack)
      .internal(.info, "*Subscription cancelled* (`\(reason)`) by \(slackLink)")
    get(dependency: \.postmark)
      .toSuperAdmin("Subscription Cancelled (\(reason))", body)
  }
}
