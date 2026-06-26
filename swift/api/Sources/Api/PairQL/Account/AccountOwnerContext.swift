import Dependencies
import DuetSQL
import Foundation

struct AccountOwnerContext: ResolverContext {
  let requestId: String
  let dashboardUrl: String
  let accountOwner: Parent
  let ipAddress: String?
  let telemetry: TelemetryBag

  @Dependency(\.db) var db
  @Dependency(\.env) var env

  func people() async throws -> [Child] {
    try await Child.query()
      .where(.parentId == self.accountOwner.id)
      .all(in: self.db)
  }
}

extension AccountOwnerContext {
  var legacyContext: ParentContext {
    ParentContext(
      requestId: self.requestId,
      dashboardUrl: self.dashboardUrl,
      parent: self.accountOwner,
      ipAddress: self.ipAddress,
      telemetry: self.telemetry,
    )
  }
}
