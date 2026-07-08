func notifyFirstPayment(
  _ parent: Parent,
  _ tier: StripeSubscription.Tier,
  _ referrer: Parent? = nil,
) {
  let email = parent.email.rawValue
  let adminLink = AdminLink()
  let slackLink = adminLink.slack(to: .parent(parent.id), text: email)
  let emailLink = adminLink.email(to: .parent(parent.id), text: email)
  let slackMessage = firstPaymentSlackMessage(slackLink, tier, referrer)
  let emailMessage = firstPaymentEmailMessage(emailLink, tier, referrer)
  Task {
    let slack = get(dependency: \.slack)
    let postmark = get(dependency: \.postmark)
    await slack.internal(.info, slackMessage)
    await slack.internal(.stripe, slackMessage)
    postmark.toSuperAdmin("FIRST Payment", emailMessage)
  }
}

func firstPaymentSlackMessage(
  _ customerLink: String,
  _ tier: StripeSubscription.Tier,
  _ referrer: Parent?,
) -> String {
  var message = "*FIRST Payment* from \(customerLink), plan: `.\(tier)`"
  if let referrer {
    let link = AdminLink().slack(to: .parent(referrer.id), text: referrer.email.rawValue)
    message += "\nreferral: `\(referrer.referralCode ?? "(unknown)")` from \(link)"
  }
  return message
}

func firstPaymentEmailMessage(
  _ customerLink: String,
  _ tier: StripeSubscription.Tier,
  _ referrer: Parent?,
) -> String {
  var message = "from \(customerLink), plan: .\(tier)"
  if let referrer {
    let link = AdminLink().email(to: .parent(referrer.id), text: referrer.email.rawValue)
    message += "<br>referral: \(referrer.referralCode ?? "(unknown)") from \(link)"
  }
  return message
}

func notifyTierChange(
  _ parent: Parent,
  _ from: StripeSubscription.Tier,
  _ to: StripeSubscription.Tier,
) {
  let email = parent.email.rawValue
  let adminLink = AdminLink()
  let slackLink = adminLink.slack(to: .parent(parent.id), text: email)
  let emailLink = adminLink.email(to: .parent(parent.id), text: email)
  let change = to > from ? "Upgrade" : "Downgrade"
  Task {
    let slack = get(dependency: \.slack)
    let postmark = get(dependency: \.postmark)
    await slack.internal(.info, "*Tier \(change)* \(slackLink): `.\(from)` → `.\(to)`")
    await slack.internal(.stripe, "*Tier \(change)* \(slackLink): `.\(from)` → `.\(to)`")
    postmark.toSuperAdmin("Tier \(change)", "\(emailLink): .\(from) → .\(to)")
  }
}

func notifyDuplicateSubscriptionAttempt(
  _ parentId: Parent.Id,
  _ existingSubId: String,
  _ incomingSubId: String,
  _ existingStatus: String,
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
  _ parentId: Parent.Id,
  _ fromTier: StripeSubscription.Tier,
  _ toTier: StripeSubscription.Tier,
  _ source: String,
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

func notifyPostUpdateStatusAnomaly(_ parentId: Parent.Id, _ status: String) {
  let adminLink = AdminLink().slack(to: .parent(parentId), text: parentId.lowercased)
  Task {
    await get(dependency: \.slack).internal(.unexpectedErrors, """
      *Post-update status anomaly* on \(adminLink)
      - stripe returned status: `\(status)`
      - expected: `active` or `past_due`
    """)
  }
}
