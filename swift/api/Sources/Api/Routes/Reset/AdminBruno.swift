import Dependencies
import DuetSQL
import Vapor
import XCore

enum AdminBruno {
  enum Ids {
    static let bruno = Parent.Id.from("BE300000-0000-0000-0000-000000000000")
  }

  static func create() async throws {
    @Dependency(\.db) var db
    let bruno = try await db.create(Parent(
      id: Ids.bruno,
      email: "bruno-full-trialing" |> Reset.testEmail,
      password: Bcrypt.hash("bruno123"),
      emailVerifiedAt: Date(),
    ))

    try await db.create(BillingIdentity(
      parentId: bruno.id,
      fullTrialStartedAt: Date(),
    ))

    try await db.create(Parent.DashToken(
      value: .init(rawValue: bruno.id.rawValue),
      parentId: bruno.id,
    ))
  }
}
