import DuetSQL
import PairQL
import XCore

struct DeleteParent: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    var parentId: Parent.Id
    var reason: String
  }
}

extension DeleteParent: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let parent = try await context.db.find(input.parentId)
    try await context.db.create(DeletedEntity(
      type: "Parent",
      reason: "\(input.reason) (from web admin)",
      data: JSON.encode(parent, [.isoDates]),
    ))
    try await context.db.delete(parent)
    return .success
  }
}
