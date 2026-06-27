import Foundation
import PairQL
import Vapor

enum UnauthedAccountRoute: PairRoute {
  case accountLogin(AccountLogin.Input)
  case accountRequestMagicLink(AccountRequestMagicLink.Input)
  case accountLoginMagicLink(AccountLoginMagicLink.Input)

  nonisolated(unsafe) static let router = OneOf {
    Route(.case(Self.accountLogin)) {
      Operation(AccountLogin.self)
      Body(.accountInput(AccountLogin.self))
    }
    Route(.case(Self.accountRequestMagicLink)) {
      Operation(AccountRequestMagicLink.self)
      Body(.accountInput(AccountRequestMagicLink.self))
    }
    Route(.case(Self.accountLoginMagicLink)) {
      Operation(AccountLoginMagicLink.self)
      Body(.accountInput(AccountLoginMagicLink.self))
    }
  }
}

extension UnauthedAccountRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .accountLogin(let input):
      let output = try await AccountLogin.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .accountRequestMagicLink(let input):
      let output = try await AccountRequestMagicLink.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .accountLoginMagicLink(let input):
      let output = try await AccountLoginMagicLink.resolve(with: input, in: context)
      return try await self.respond(with: output)
    }
  }
}
