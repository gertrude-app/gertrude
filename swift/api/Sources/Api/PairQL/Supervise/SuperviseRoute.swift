import PairQL
import Vapor

enum SuperviseRoute: PairRoute {
  case superviseNoop

  nonisolated(unsafe) static let router = OneOf {
    Route(.case(Self.superviseNoop)) {
      Operation(SuperviseNoop.self)
    }
  }
}

extension SuperviseRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .superviseNoop:
      let output = try await SuperviseNoop.resolve(in: context)
      return try await self.respond(with: output)
    }
  }
}
