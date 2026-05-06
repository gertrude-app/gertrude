import Crypto
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
        !verifyStripeSignature(payload: json, signature: signature!, secret: webhookSecret) {
        await get(dependency: \.slack).error("Stripe webhook signature verification failed")
        return Response(status: .unauthorized)
      }
    } else if request.context.env.mode == .prod {
      await get(dependency: \.slack).error("Production API missing STRIPE_WEBHOOK_SECRET")
      return Response(status: .unauthorized)
    }

    let event = try? JSON.decode(json, as: EventInfo.self)

    // TODO: wrap in transaction — adding a transaction helper to Duet in a separate
    // branch, then coming back to wrap insertIdempotent + the dispatch below so a
    // mid-handler crash rolls back the idempotency marker and Stripe can retry cleanly
    let stripeEvent = try await StripeEvent.insertIdempotent(
      json: json,
      stripeEventId: event?.id,
      in: request.context.db,
    )
    guard let stripeEvent else {
      return Response(status: .noContent)
    }

    switch event?.type {
    case "invoice.paid":
      try await handleInvoicePaid(event: event, stripeEvent: stripeEvent, db: request.context.db)
    case "customer.subscription.updated":
      try await handleSubscriptionUpdated(
        event: event,
        stripeEvent: stripeEvent,
        db: request.context.db,
      )
    case "customer.subscription.deleted":
      try await handleSubscriptionDeleted(
        event: event,
        stripeEvent: stripeEvent,
        db: request.context.db,
      )
    default:
      break
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
    let subscription = try? await Subscription.query()
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
  guard let eventTier = priceId.flatMap(Subscription.Tier.init(stripePriceId:)) else {
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
  let statusExpiration = periodEnd + .days(2)

  if var subscription = try await parent.subscription(in: db) {
    if subscription.stripeId == nil {
      await recordPaidAdConversion(parent: parent, db: db)
      notifyFirstPayment(parent: parent, tier: eventTier)
    } else if subscription.stripeId?.rawValue != eventSubscriptionId {
      let allow = try await reconcileDuplicateSubscription(
        parent: parent,
        existingSubId: subscription.stripeId!.rawValue,
        incomingSubId: eventSubscriptionId,
        context: "stripe-webhook",
        audit: "stripe_event_id: \(stripeEvent.stripeEventId ?? "(nil)")",
        db: db,
      )
      guard allow else { return }
    }
    subscription.tier = eventTier
    subscription.billingStatus = .paid
    subscription.stripeId = .init(eventSubscriptionId)
    subscription.stripeStatus = .active
    subscription.currentPeriodEnd = periodEnd
    subscription.statusExpiresAt = statusExpiration
    try await db.update(subscription)

  } else {
    try await db.create(Subscription(
      parentId: parent.id,
      tier: eventTier,
      billingStatus: .paid,
      stripeId: .init(eventSubscriptionId),
      stripeStatus: .active,
      currentPeriodEnd: periodEnd,
      statusExpiresAt: statusExpiration,
    ))
    await recordPaidAdConversion(parent: parent, db: db)
    notifyFirstPayment(parent: parent, tier: eventTier)
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

  guard var subscription = try? await Subscription.query()
    .where(.stripeId == .init(stripeSubId))
    .first(in: db) else {
    unexpected(
      "61f0e37c",
      detail: "no local sub for stripe sub id: \(stripeSubId), event: \(stripeEvent.id)",
    )
    return
  }

  let priceId = event?.data?.object?.items?.data?.first?.price?.id
  guard let eventTier = priceId.flatMap(Subscription.Tier.init(stripePriceId:)) else {
    unexpected(
      "8e1cb204",
      detail: "unknown price id: \(priceId ?? "(nil)"), event: \(stripeEvent.id)",
    )
    return
  }

  guard let statusRaw = event?.data?.object?.status,
        let stripeStatus = Subscription.StripeStatus(rawValue: statusRaw) else {
    unexpected(
      "33ec5b7f",
      detail: "unknown status: \(event?.data?.object?.status ?? "(nil)"), event: \(stripeEvent.id)",
    )
    return
  }

  if subscription.tier != eventTier {
    let fromTier = subscription.tier
    notifyUnexpectedTierChange(
      parentId: subscription.parentId,
      fromTier: fromTier,
      toTier: eventTier,
      source: "customer.subscription.updated",
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
  if let mirrored = stripeStatus.mirroredBillingStatus {
    subscription.billingStatus = mirrored
  }
  if let periodEnd = event?.data?.object?.current_period_end {
    subscription.currentPeriodEnd = Date(timeIntervalSince1970: TimeInterval(periodEnd))
  }
  try await db.update(subscription)
}

extension Subscription.StripeStatus {
  var mirroredBillingStatus: BillingStatus.Db? {
    switch self {
    case .active: .paid
    case .pastDue: .overdue
    case .unpaid, .incomplete, .incompleteExpired: .unpaid
    case .canceled: .cancelled
    case .trialing: nil
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

  guard var subscription = try? await Subscription.query()
    .where(.stripeId == .init(stripeSubId))
    .first(in: db) else {
    unexpected("a7c3d1e5", detail: "stripe sub id: \(stripeSubId), event: \(stripeEvent.id)")
    return
  }

  subscription.billingStatus = .cancelled
  subscription.stripeStatus = .canceled
  subscription.statusExpiresAt = .distantFuture
  try await db.update(subscription)

  Task {
    let parent = try await db.find(subscription.parentId) as Parent
    let adminLink = AdminLink()
    let slackLink = adminLink.slack(to: .parent(parent.id), text: parent.email.rawValue)
    let emailLink = adminLink.email(to: .parent(parent.id), text: parent.email.rawValue)
    await get(dependency: \.slack)
      .internal(.info, "*Subscription cancelled* by \(slackLink)")
    get(dependency: \.postmark)
      .toSuperAdmin("Subscription Cancelled", "by \(emailLink)")
  }
}

func reconcileDuplicateSubscription(
  parent: Parent,
  existingSubId: String,
  incomingSubId: String,
  context: String,
  audit: String,
  db: any DuetSQL.Client,
) async throws -> Bool {
  let stripe = get(dependency: \.stripe)
  let lookup: Result<Stripe.Api.Subscription, Error>
  do {
    lookup = try await .success(stripe.getSubscription(existingSubId))
  } catch {
    lookup = .failure(error)
  }

  enum Decision { case allow(reason: String)
    case reject(reason: String, status: String)
  }
  let decision: Decision = switch lookup {
  case .success(let existing):
    switch existing.status {
    case .active, .trialing, .pastDue, .incomplete:
      .reject(reason: "live status", status: existing.status.rawValue)
    case .canceled, .unpaid, .incompleteExpired:
      .allow(reason: "terminal status: \(existing.status.rawValue)")
    }
  case .failure(let error as Stripe.Api.Error) where error.code == "resource_missing":
    .allow(reason: "stripe 404 (resource_missing)")
  case .failure(let error):
    .reject(reason: "stripe lookup failed", status: "\(error)")
  }

  switch decision {
  case .reject(let reason, let status):
    notifyDuplicateSubscriptionAttempt(
      parentId: parent.id,
      existingSubId: existingSubId,
      incomingSubId: incomingSubId,
      existingStatus: status,
    )
    _ = try? await db.create(InterestingEvent(
      eventId: "duplicate_subscription_rejected",
      kind: "billing",
      context: context,
      parentId: parent.id,
      detail: "existing: \(existingSubId), incoming: \(incomingSubId), "
        + "reason: \(reason), existing_status: \(status), \(audit)",
    ))
    return false
  case .allow(let reason):
    _ = try? await db.create(InterestingEvent(
      eventId: "subscription_overwritten",
      kind: "billing",
      context: context,
      parentId: parent.id,
      detail: "existing: \(existingSubId), incoming: \(incomingSubId), "
        + "reason: \(reason), \(audit)",
    ))
    return true
  }
}

extension StripeEvent {
  static func insertIdempotent(
    json: String,
    stripeEventId: String?,
    in db: any DuetSQL.Client,
  ) async throws -> StripeEvent? {
    typealias SE = StripeEvent
    let event = StripeEvent(json: json, stripeEventId: stripeEventId)
    var stmt = SQL.Statement("""
    INSERT INTO \(table: SE.self)
    (\(SE.columnName(.id)), \(SE.columnName(.json)), \
    \(SE.columnName(.stripeEventId)), \(SE.columnName(.createdAt)))
    VALUES (
    """)
    stmt.components.append(.binding(.id(event)))
    stmt.components.append(.sql(", "))
    stmt.components.append(.binding(.string(json)))
    stmt.components.append(.sql(", "))
    stmt.components.append(.binding(.string(stripeEventId)))
    stmt.components.append(.sql(", "))
    stmt.components.append(.binding(.currentTimestamp))
    stmt.components.append(.sql("""
    )
    ON CONFLICT (\(SE.columnName(.stripeEventId))) DO NOTHING
    RETURNING \(SE.columnName(.id))
    """))
    let rows = try await db.execute(statement: stmt)
    return rows.isEmpty ? nil : event
  }
}

private func slackNotify(_ event: EventInfo?) {
  Task {
    await get(dependency: \.slack).internal(.stripe, """
      *Received Gertrude Stripe Event:*
      - type: `\(event?.type ?? "(nil)")`
      - customer email: `\(event?.data?.object?.customer_email ?? "(nil)")`
    """)
  }
}

private struct EventInfo: Decodable {
  struct Data: Decodable {
    struct Object: Decodable {
      var id: String?

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

func verifyStripeSignature(
  payload: String,
  signature: String,
  secret: String,
  tolerance: TimeInterval = 300,
  currentTime: Date = Date(),
) -> Bool {
  var timestamp: String?
  var signatures: [String] = []

  for part in signature.split(separator: ",") {
    let kv = part.split(separator: "=", maxSplits: 1)
    guard kv.count == 2 else { continue }
    let key = String(kv[0])
    let value = String(kv[1])
    if key == "t" {
      timestamp = value
    } else if key == "v1" {
      signatures.append(value)
    }
  }

  guard let timestamp, !signatures.isEmpty else {
    return false
  }

  if let timestampInt = Int(timestamp) {
    let eventTime = Date(timeIntervalSince1970: TimeInterval(timestampInt))
    let age = currentTime.timeIntervalSince(eventTime)
    if age < 0 || age > tolerance {
      return false
    }
  } else {
    return false
  }

  let signedPayload = "\(timestamp).\(payload)"
  let key = SymmetricKey(data: Data(secret.utf8))
  let hmac = HMAC<SHA256>.authenticationCode(for: Data(signedPayload.utf8), using: key)
  let expectedSignature = Data(hmac).map { String(format: "%02x", $0) }.joined()

  return signatures.contains { receivedSig in
    guard receivedSig.count == expectedSignature.count else { return false }
    var result: UInt8 = 0
    for (a, b) in zip(receivedSig.utf8, expectedSignature.utf8) {
      result |= a ^ b
    }
    return result == 0
  }
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

func notifyFirstPayment(parent: Parent, tier: Subscription.Tier) {
  let email = parent.email.rawValue
  let adminLink = AdminLink()
  let slackLink = adminLink.slack(to: .parent(parent.id), text: email)
  let emailLink = adminLink.email(to: .parent(parent.id), text: email)
  Task {
    let slack = get(dependency: \.slack)
    let postmark = get(dependency: \.postmark)
    await slack.internal(.info, "*FIRST Payment* from \(slackLink), plan: `.\(tier)`")
    await slack.internal(.stripe, "*FIRST Payment* from \(slackLink), plan: `.\(tier)`")
    postmark.toSuperAdmin("FIRST Payment", "from \(emailLink), plan: .\(tier)")
  }
}

func notifyDuplicateSubscriptionAttempt(
  parentId: Parent.Id,
  existingSubId: String,
  incomingSubId: String,
  existingStatus: String,
) {
  let adminLink = AdminLink().slack(to: .parent(parentId), text: parentId.lowercased)
  Task {
    await get(dependency: \.slack).internal(.unexpectedErrors, """
      *DUPLICATE SUBSCRIPTION ATTEMPT* on \(adminLink)
      - existing sub id: `\(existingSubId)`
      - incoming sub id: `\(incomingSubId)`
      - existing status: `\(existingStatus)`
      - incoming overwrite was *rejected*; investigate before reconciling
    """)
  }
}

func notifyUnexpectedTierChange(
  parentId: Parent.Id,
  fromTier: Subscription.Tier,
  toTier: Subscription.Tier,
  source: String,
) {
  let adminLink = AdminLink().slack(to: .parent(parentId), text: parentId.lowercased)
  Task {
    await get(dependency: \.slack).internal(.unexpectedErrors, """
      *Unexpected tier change* on \(adminLink)
      - from: `.\(fromTier)`
      - to: `.\(toTier)`
      - source: `\(source)`
    """)
  }
}

func notifyPostUpdateStatusAnomaly(parentId: Parent.Id, status: String) {
  let adminLink = AdminLink().slack(to: .parent(parentId), text: parentId.lowercased)
  Task {
    await get(dependency: \.slack).internal(.unexpectedErrors, """
      *Post-update status anomaly* on \(adminLink)
      - stripe returned status: `\(status)`
      - expected: `active` or `past_due`
    """)
  }
}
