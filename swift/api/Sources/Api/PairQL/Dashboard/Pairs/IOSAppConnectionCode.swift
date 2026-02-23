import Dependencies
import PairQL

struct IOSAppConnectionCode: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
  }

  struct Output: PairOutput {
    var code: Int
  }
}

extension IOSAppConnectionCode: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChild(from: input.childId)
    let code = await with(dependency: \.ephemeral).createPendingAppConnection(child.id)
    return .init(code: code)
  }
}
