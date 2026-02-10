import Crypto
import DuetSQL
import Gertie
import Vapor
import XCore

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

    let now = get(dependency: \.date.now)
    let stripeEvent = try await request.context.db.create(StripeEvent(json: json))
    let event = try? JSON.decode(json, as: EventInfo.self)

    if event?.type == "invoice.paid",
       let email = event?.data?.object?.customer_email {

      var parent = try? await Parent.query()
        .where(.email == email.lowercased())
        .first(in: request.context.db)

      // resolving from the subscription id allows for a different account for payment
      // a customer asked for this, he pays for himself but his "parent" is accountability
      // partner that has a different email/account, whom he did not want to have to pay
      if parent == nil {
        let subscription = try? await Subscription.query()
          .where(.stripeId == .init(event?.data?.object?.subscription ?? ""))
          .first(in: request.context.db)
        if let subscription {
          parent = try await request.context.db.find(subscription.parentId)
        }
      }

      guard let parent else {
        unexpected("b3aaf12c", detail: "email: \(email), event: \(stripeEvent.id)")
        slackNotify(event)
        return Response(status: .noContent)
      }

      let priceId = event?.data?.object?.lines?.data?.first?.price?.id
      guard let eventTier = priceId.flatMap(Subscription.Tier.init(stripePriceId:)) else {
        unexpected("bf3cad72", detail: "email: \(email), event: \(stripeEvent.id)")
        slackNotify(event)
        return Response(status: .noContent)
      }

      guard let eventSubscriptionId = event?.data?.object?.subscription else {
        unexpected("d4e8f3c1", detail: "email: \(email), event: \(stripeEvent.id)")
        slackNotify(event)
        return Response(status: .noContent)
      }

      let statusExpiration = event?.data?.object?.lines?.data?.first?.period?.end
        .map { Date(timeIntervalSince1970: TimeInterval($0)).advanced(by: .days(2)) }
        ?? now + .days(eventTier.periodLengthInDays + 2)

      if var subscription = try await parent.subscription(in: request.context.db) {
        if subscription.stripeId == nil {
          notifyFirstPayment(parent: parent, tier: eventTier)
        } else if subscription.stripeId?.rawValue != eventSubscriptionId {
          unexpected(
            "2156b9f8",
            detail: "prev: \(subscription.stripeId ?? ""), new: \(eventSubscriptionId)",
          )
        }
        subscription.tier = eventTier
        subscription.billingStatus = .paid
        subscription.stripeId = .init(eventSubscriptionId)
        subscription.statusExpiresAt = statusExpiration
        try await request.context.db.update(subscription)

      } else {
        try await request.context.db.create(Subscription(
          parentId: parent.id,
          tier: eventTier,
          billingStatus: .paid,
          stripeId: .init(eventSubscriptionId),
          statusExpiresAt: statusExpiration,
        ))
        notifyFirstPayment(parent: parent, tier: eventTier)
      }
    }

    slackNotify(event)
    return Response(status: .noContent)
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

      var customer_email: String?
      var lines: Lines?
      var subscription: String?
    }

    var object: Object?
  }

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

func notifyFirstPayment(email: String, tier: Subscription.Tier) {
  Task {
    let slack = get(dependency: \.slack)
    let postmark = get(dependency: \.postmark)
    await slack.internal(.info, "*FIRST Payment* from `\(email)`, plan: `.\(tier)`")
    await slack.internal(.stripe, "*FIRST Payment* from `\(email)`, plan: `.\(tier)`")
    postmark.toSuperAdmin("FIRST Payment", "from \(email), plan: .\(tier)")
  }
}

func notifyFirstPayment(parent: Parent, tier: Subscription.Tier) {
  notifyFirstPayment(email: parent.email.rawValue, tier: tier)
}
