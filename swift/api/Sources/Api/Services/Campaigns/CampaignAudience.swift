struct PreparedCampaignAudience<Recipient: Sendable>: Sendable {
  var audience: [Recipient]
  var alreadyDelivered: [Recipient]
  var eligible: [Recipient]

  func selectedRecipients(limit: Int?) -> [Recipient] {
    guard let limit else { return self.eligible }
    return Array(self.eligible.prefix(max(0, limit)))
  }
}

func prepareCampaignAudience<Recipient: Sendable, ID: Hashable & Sendable>(
  audience: [Recipient],
  deliveredIds: Set<ID>,
  identifiedBy id: KeyPath<Recipient, ID>,
) -> PreparedCampaignAudience<Recipient> {
  var seen = Set<ID>()
  let audience = audience.filter { seen.insert($0[keyPath: id]).inserted }
  return .init(
    audience: audience,
    alreadyDelivered: audience.filter { deliveredIds.contains($0[keyPath: id]) },
    eligible: audience.filter { !deliveredIds.contains($0[keyPath: id]) },
  )
}
