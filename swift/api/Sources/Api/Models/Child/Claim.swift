import DuetSQL

@DuetModel(schema: "child", table: "claims")
struct Claim: Codable, Sendable, Equatable {
  var id: Id
  var code: Int
  var intent: ClaimIntent
  var deviceId: IOSDevice.Id
  var childId: Child.Id?
  var expiresAt: Date
  var claimedAt: Date?
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    code: Int,
    intent: ClaimIntent,
    deviceId: IOSDevice.Id,
    childId: Child.Id? = nil,
    expiresAt: Date,
    claimedAt: Date? = nil,
  ) {
    self.id = id
    self.code = code
    self.intent = intent
    self.deviceId = deviceId
    self.childId = childId
    self.expiresAt = expiresAt
    self.claimedAt = claimedAt
  }
}
