import Dependencies
import PairQL

struct PrepIOSAppConnection: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let child: ClaimIOSDevice.ChildAssignment
  }

  typealias Output = IOSAppConnectionCode.Output
}

extension PrepIOSAppConnection: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = switch input.child {
    case .existingChild(id: let id):
      try await context.verifiedChild(from: id)
    case .newChild(name: let name):
      try await context.db.create(Child(parentId: context.parent.id, name: name))
    }
    let code = await with(dependency: \.ephemeral).getOrCreatePendingAppConnection(child.id)
    return .init(code: code)
  }
}
