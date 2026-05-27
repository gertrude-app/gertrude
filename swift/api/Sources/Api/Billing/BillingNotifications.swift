func notifyFirstPayment(parent: Parent, tier: StripeSubscription.Tier) {
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

func notifyTierUpgrade(
  parent: Parent,
  from: StripeSubscription.Tier,
  to: StripeSubscription.Tier,
) {
  let email = parent.email.rawValue
  let adminLink = AdminLink()
  let slackLink = adminLink.slack(to: .parent(parent.id), text: email)
  let emailLink = adminLink.email(to: .parent(parent.id), text: email)
  Task {
    let slack = get(dependency: \.slack)
    let postmark = get(dependency: \.postmark)
    await slack.internal(.info, "*Tier Upgrade* \(slackLink): `.\(from)` → `.\(to)`")
    await slack.internal(.stripe, "*Tier Upgrade* \(slackLink): `.\(from)` → `.\(to)`")
    postmark.toSuperAdmin("Tier Upgrade", "\(emailLink): .\(from) → .\(to)")
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
  fromTier: StripeSubscription.Tier,
  toTier: StripeSubscription.Tier,
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
