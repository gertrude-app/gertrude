import Foundation
import PairQL
import Vapor

enum AuthedAccountRoute: PairRoute {
  case getPeople
  case getActivitySummaries(GetActivitySummaries.Input)
  case getDayActivity(GetDayActivity.Input)
  case getPersonActivitySummaries(GetPersonActivitySummaries.Input)
  case getPersonDayActivity(GetPersonDayActivity.Input)
  case toggleActivityFlag(ToggleActivityFlag.Input)
  case deleteActivity(DeleteActivity.Input)

  nonisolated(unsafe) static let router = OneOf {
    Route(.case(Self.getPeople)) {
      Operation(GetPeople.self)
    }
    Route(.case(Self.getActivitySummaries)) {
      Operation(GetActivitySummaries.self)
      Body(.accountInput(GetActivitySummaries.self))
    }
    Route(.case(Self.getDayActivity)) {
      Operation(GetDayActivity.self)
      Body(.accountInput(GetDayActivity.self))
    }
    Route(.case(Self.getPersonActivitySummaries)) {
      Operation(GetPersonActivitySummaries.self)
      Body(.accountInput(GetPersonActivitySummaries.self))
    }
    Route(.case(Self.getPersonDayActivity)) {
      Operation(GetPersonDayActivity.self)
      Body(.accountInput(GetPersonDayActivity.self))
    }
    Route(.case(Self.toggleActivityFlag)) {
      Operation(ToggleActivityFlag.self)
      Body(.accountInput(ToggleActivityFlag.self))
    }
    Route(.case(Self.deleteActivity)) {
      Operation(DeleteActivity.self)
      Body(.accountInput(DeleteActivity.self))
    }
  }
}

extension AuthedAccountRoute: RouteResponder {
  static func respond(to route: Self, in context: AccountOwnerContext) async throws -> Response {
    switch route {
    case .getPeople:
      let output = try await GetPeople.resolve(in: context)
      return try await self.respond(with: output)
    case .getActivitySummaries(let input):
      let output = try await GetActivitySummaries.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getDayActivity(let input):
      let output = try await GetDayActivity.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getPersonActivitySummaries(let input):
      let output = try await GetPersonActivitySummaries.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getPersonDayActivity(let input):
      let output = try await GetPersonDayActivity.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .toggleActivityFlag(let input):
      let output = try await ToggleActivityFlag.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .deleteActivity(let input):
      let output = try await DeleteActivity.resolve(with: input, in: context)
      return try await self.respond(with: output)
    }
  }
}
