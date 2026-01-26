import PairQL

struct GetChildren: Pair {
  static let auth: ClientAuth = .parent
  typealias Output = [GetChild.Output]
}

// resolver

extension GetChildren: NoInputResolver {
  static func resolve(in context: ParentContext) async throws -> Output {
    let children = try await context.parent.children(in: context.db)
    return try await children.concurrentMap { child in
      try await GetChild.resolve(with: child.id, in: context)
    }
  }
}
