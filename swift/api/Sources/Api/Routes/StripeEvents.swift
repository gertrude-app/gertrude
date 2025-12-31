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

    let slack = get(dependency: \.slack)
    let stripeEvent = try await request.context.db.create(StripeEvent(json: json))
    let event = try? JSON.decode(json, as: EventInfo.self)

    if event?.type == "invoice.paid",
       let email = event?.data?.object?.customer_email {

      let parent = try? await Parent.query()
        .where(.or(
          .email == email.lowercased(),
          .subscriptionId == (event?.data?.object?.subscription ?? UUID().uuidString),
        ))
        .first(in: request.context.db)

      if var parent {
        parent.subscriptionStatus = .paid
        parent.subscriptionStatusExpiration = event?.data?.object?.lines?.data?.first?.period?.end
          .map { Date(timeIntervalSince1970: TimeInterval($0)).advanced(by: .days(2)) }
          ?? get(dependency: \.date.now) + .days(33)

        switch (parent.subscriptionId, event?.data?.object?.subscription) {
        case (.none, .some(let subscriptionId)):
          parent.subscriptionId = .init(rawValue: subscriptionId)
          Task {
            await slack.internal(.info, "*FIRST Payment* from `\(email)`")
            await slack.internal(.stripe, "*FIRST Payment* from `\(email)`")
            get(dependency: \.postmark).toSuperAdmin("FIRST Payment", "from \(email)")
          }
        case (.some(let existing), .some(let subscriptionId))
          where existing.rawValue != subscriptionId:
          parent.subscriptionId = .init(rawValue: subscriptionId)
          unexpected("2156b9f8", detail: "prev: \(existing), new: \(subscriptionId)")
        default:
          break
        }
        try await request.context.db.update(parent)
      } else {
        unexpected("b3aaf12c", detail: "email: \(email), event: \(stripeEvent.id)")
      }
    }

    Task {
      await slack.internal(.stripe, """
        *Received Gertrude Stripe Event:*
        - type: `\(event?.type ?? "(nil)")`
        - customer email: `\(event?.data?.object?.customer_email ?? "(nil)")`
      """)
    }

    return Response(status: .noContent)
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

          var period: Period?
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
