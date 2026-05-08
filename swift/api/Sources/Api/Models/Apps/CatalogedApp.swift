import Duet
import Foundation

struct CatalogedApp: Codable, Sendable {
  var id: Id
  var bundleId: String
  var name: String
  var category: String?
  var icon: Data?
  var iconContentHash: String?
  var iconUploadedAt: Date?
  var iconSourceAppVersion: String?
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    bundleId: String,
    name: String,
    category: String? = nil,
    icon: Data? = nil,
    iconContentHash: String? = nil,
    iconUploadedAt: Date? = nil,
    iconSourceAppVersion: String? = nil,
  ) {
    self.id = id
    self.bundleId = bundleId
    self.name = name
    self.category = category
    self.icon = icon
    self.iconContentHash = iconContentHash
    self.iconUploadedAt = iconUploadedAt
    self.iconSourceAppVersion = iconSourceAppVersion
  }
}
