import DuetSQL

@DuetModel(schema: "macos", table: "app_bundle_ids")
struct AppBundleId: Codable, Sendable {
  var id: Id
  var bundleId: String
  var identifiedAppId: IdentifiedApp.Id
  var count: Int
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    identifiedAppId: IdentifiedApp.Id,
    bundleId: String,
    count: Int = 0,
  ) {
    self.id = id
    self.identifiedAppId = identifiedAppId
    self.bundleId = bundleId
    self.count = count
  }
}
