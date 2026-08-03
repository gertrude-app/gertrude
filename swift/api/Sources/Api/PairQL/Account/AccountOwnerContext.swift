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

  func person(_ id: Child.Id) async throws -> Child {
    try await Child.query()
      .where(.id == id)
      .where(.parentId == self.accountOwner.id)
      .first(in: self.db)
  }

  func validatePersonRelationship(
    _ relationship: Child.Relationship,
    excluding excludedPersonId: Child.Id? = nil,
  ) async throws {
    guard relationship == .selfManaged else { return }
    let hasAnotherSelfManagedPerson = try await self.people().contains {
      $0.id != excludedPersonId && $0.relationship == .selfManaged
    }
    guard !hasAnotherSelfManagedPerson else {
      throw self.error(
        id: "2eac58e7",
        type: .badRequest,
        debugMessage: "account already has a self-managed person",
        userMessage: "Another protected person is already set to Myself. Change their relationship first.",
      )
    }
  }

  func validatedPersonName(_ untrimmedName: String) throws -> String {
    let name = untrimmedName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else {
      throw self.error(
        id: "d13d20d5",
        type: .badRequest,
        debugMessage: "person name cannot be empty",
        userMessage: "Enter a name for this person.",
      )
    }
    return name
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
