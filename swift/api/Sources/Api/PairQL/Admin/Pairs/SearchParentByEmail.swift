import DuetSQL
import PairQL

struct SearchParentByEmail: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    var email: String
  }

  struct Output: PairOutput {
    var parentId: Parent.Id?
  }
}

extension SearchParentByEmail: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let email = input.email.lowercased().trimmingCharacters(in: .whitespaces)
    let parent = try? await Parent.query()
      .where(.email == .string(email))
      .first(in: context.db)
    return Output(parentId: parent?.id)
  }
}
