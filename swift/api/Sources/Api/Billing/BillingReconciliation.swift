import DuetSQL
import XStripe

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

  enum Decision {
    case allow(reason: String)
    case reject(reason: String, status: String)
  }

  let decision: Decision = switch lookup {
  case .success(let existing):
    if let status = StripeSubscription.StripeStatus(rawValue: existing.status.rawValue),
       !status.isLive {
      .allow(reason: "terminal status: \(existing.status.rawValue)")
    } else {
      .reject(reason: "live status", status: existing.status.rawValue)
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
