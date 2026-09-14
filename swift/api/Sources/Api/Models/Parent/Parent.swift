import DuetSQL
import Gertie

@DuetModel(schema: "parent", table: "parents")
struct Parent: Codable, Sendable {
  var id: Id
  var email: EmailAddress
  var password: String
  var emailVerifiedAt: Date?
  var gclid: String?
  var abTestVariant: String?
  var referralCode: String?
  var referredByParentId: Id?
  var timeZone: String?
  var accountSiteBetaEnabled = false
  var dailyReviewEmail = false
  var lastReviewEmailAt: Date?
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
    referralCode: String? = nil,
    referredByParentId: Id? = nil,
    createdAt: Date = Date(),
  ) {
    self.id = id
    self.email = email
    self.password = password
    self.emailVerifiedAt = emailVerifiedAt
    self.gclid = gclid
    self.abTestVariant = abTestVariant
    self.referralCode = referralCode
    self.referredByParentId = referredByParentId
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

  func canLeaveFullTier(in db: any DuetSQL.Client) async throws -> Bool {
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

  func referrer(in db: any DuetSQL.Client) async throws -> Parent? {
    guard let referredByParentId else { return nil }
    return try await Parent.query()
      .where(.id == referredByParentId)
      .all(in: db)
      .first
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

  func supervisedIOSDevices(in db: any DuetSQL.Client) async throws -> SupervisedIOSDevices {
    let rows = try await db.customQuery(
      SupervisedIOSDeviceUdids.self,
      withBindings: [.uuid(self.id.rawValue)],
    )
    return SupervisedIOSDevices(
      udids: Set(rows.compactMap(\.udid)),
      unidentified: rows.count(where: { $0.udid == nil }),
    )
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

struct SupervisedIOSDevices {
  let udids: Set<String>
  let unidentified: Int

  var count: Int {
    self.udids.count + self.unidentified
  }

  func alreadyIncludes(udid: String) -> Bool {
    self.udids.contains(udid)
  }
}

private struct SupervisedIOSDeviceUdids: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    guard let parentId = bindings.first else {
      return SQL.Statement("SELECT NULL AS udid WHERE FALSE")
    }
    var stmt = SQL.Statement("""
    SELECT s.\(BlockerApp.Supervision.columnName(.udid)) AS udid
    FROM \(table: BlockerApp.Supervision.self) s
    JOIN \(table: IOSDevice.self) d
      ON d.id = s.\(BlockerApp.Supervision.columnName(.deviceId))
    JOIN \(table: Child.self) c
      ON c.id = d.\(IOSDevice.columnName(.childId))
    WHERE s.\(BlockerApp.Supervision.columnName(.supervisedAt)) IS NOT NULL
      AND c.\(Child.columnName(.parentId)) =
    """)
    stmt.components.append(.binding(parentId))
    return stmt
  }

  var udid: String?
}
