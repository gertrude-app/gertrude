import DuetSQL
import Gertie

struct Parent: Codable, Sendable {
  var id: Id
  var email: EmailAddress
  var password: String
  var emailVerifiedAt: Date?
  var gclid: String?
  var abTestVariant: String?
  var createdAt = Date()
  var updatedAt = Date()

  var emailVerified: Bool {
    self.emailVerifiedAt != nil
  }

  init(
    id: Id = .init(),
    email: EmailAddress,
    password: String,
    emailVerifiedAt: Date? = nil,
    gclid: String? = nil,
    abTestVariant: String? = nil,
    createdAt: Date = Date(),
  ) {
    self.id = id
    self.email = email
    self.password = password
    self.emailVerifiedAt = emailVerifiedAt
    self.gclid = gclid
    self.abTestVariant = abTestVariant
    self.createdAt = createdAt
  }
}

extension Parent {
  func keychains(in db: any DuetSQL.Client) async throws -> [Keychain] {
    try await Keychain.query()
      .where(.parentId == self.id)
      .all(in: db)
  }

  func keychain(_ keychainId: Keychain.Id, in db: any DuetSQL.Client) async throws -> Keychain {
    try await Keychain.query()
      .where(.parentId == self.id)
      .where(.id == keychainId)
      .first(in: db)
  }

  func children(in db: any DuetSQL.Client) async throws -> [Child] {
    try await Child.query()
      .where(.parentId == self.id)
      .all(in: db)
  }

  func computers(in db: any DuetSQL.Client) async throws -> [Computer] {
    try await Computer.query()
      .where(.parentId == self.id)
      .all(in: db)
  }

  func canDowngradeFullSubToLight(in db: any DuetSQL.Client) async throws -> Bool {
    try await Computer.query()
      .where(.parentId == self.id)
      .count(in: db) == 0
  }

  func notifications(in db: any DuetSQL.Client) async throws -> [Parent.Notification] {
    try await Parent.Notification.query()
      .where(.parentId == self.id)
      .all(in: db)
  }

  func verifiedNotificationMethods(
    in db: any DuetSQL.Client,
  ) async throws -> [Parent.NotificationMethod] {
    try await Parent.NotificationMethod.query()
      .where(.parentId == self.id)
      .all(in: db)
  }

  func subscription(in db: any DuetSQL.Client) async throws -> StripeSubscription? {
    try? await StripeSubscription.query()
      .where(.parentId == self.id)
      .first(in: db)
  }

  func billingIdentity(in db: any DuetSQL.Client) async throws -> BillingIdentity? {
    try? await BillingIdentity.query()
      .where(.parentId == self.id)
      .first(in: db)
  }

  func billingAccountSnapshot(
    in db: any DuetSQL.Client,
    at date: Date,
  ) async throws -> BillingAccountSnapshot {
    async let identity = self.billingIdentity(in: db)
    async let subscription = self.subscription(in: db)
    return try await BillingAccountSnapshot(
      billingIdentity: identity,
      stripeSubscription: subscription,
      date: date,
    )
  }

  @discardableResult
  func ensureBillingIdentity(in db: any DuetSQL.Client) async throws -> BillingIdentity {
    if let existing = try await self.billingIdentity(in: db) {
      return existing
    }
    let identity = BillingIdentity(parentId: self.id)
    return try await db.create(identity)
  }

  func adminSiteLink(_ kind: AdminLink.Kind) -> String {
    switch kind {
    case .email:
      AdminLink().email(to: .parent(self.id), text: self.email.rawValue)
    case .slack:
      AdminLink().slack(to: .parent(self.id), text: self.email.rawValue)
    case .url:
      AdminLink().url(to: .parent(self.id))
    }
  }
}
