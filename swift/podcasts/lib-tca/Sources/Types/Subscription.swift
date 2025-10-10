import Foundation

struct Subscription {
  var status: Status
  var expiresAt: Date
}

extension Subscription {
  enum Status {
    case trialing
    case active
    case complimentary
  }

  // TODO: fetch from api is better
  enum ProductId: String, CaseIterable {
    case yearly = "gertrude.am.yearly.permanent.access"
  }
}
