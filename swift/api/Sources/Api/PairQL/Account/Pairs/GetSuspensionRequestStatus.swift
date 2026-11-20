import Dependencies
import Foundation
import PairQL

struct GetSuspensionRequestStatus: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let id: MacApp.SuspendFilterRequest.Id
  }

  struct Output: PairOutput {
    enum Status: String, PairNestable {
      case pending
      case accepted
      case rejected
      case expired
    }

    let status: Status
    let personName: String
    let durationInSeconds: Int
  }
}

extension GetSuspensionRequestStatus: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let request = try await GetSuspendFilterRequest.resolve(
      with: input.id,
      in: context.legacyContext,
    )
    let status: Output.Status = switch request.status {
    case .accepted: .accepted
    case .rejected: .rejected
    case .pending:
      request.createdAt < get(dependency: \.date.now) - MacApp.SuspendFilterRequest.answerableFor
        ? .expired
        : .pending
    }
    return .init(
      status: status,
      personName: request.userName,
      durationInSeconds: request.requestedDurationInSeconds,
    )
  }
}
