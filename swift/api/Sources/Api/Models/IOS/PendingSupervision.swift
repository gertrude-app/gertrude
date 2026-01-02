import DuetSQL

extension IOSApp {
  struct PendingSupervision: Codable, Sendable, Equatable {
    var id: Id
    var code: Int
    var vendorId: UUID
    var deviceType: String
    var iosVersion: String
    var appVersion: String
    var claimedByParentId: Parent.Id?
    var childId: Child.Id?
    var expiresAt: Date
    var createdAt = Date()
    var updatedAt = Date()

    init(
      id: Id? = nil,
      code: Int,
      vendorId: UUID,
      deviceType: String,
      iosVersion: String,
      appVersion: String,
      claimedByParentId: Parent.Id? = nil,
      childId: Child.Id? = nil,
      expiresAt: Date,
    ) {
      self.id = id ?? .init(get(dependency: \.uuid)())
      self.code = code
      self.vendorId = vendorId
      self.deviceType = deviceType
      self.iosVersion = iosVersion
      self.appVersion = appVersion
      self.claimedByParentId = claimedByParentId
      self.childId = childId
      self.expiresAt = expiresAt
    }
  }
}
