import Gertie
import PairQL
import TSCodable

struct DecideFilterSuspensionRequest: Pair {
  static let auth: ClientAuth = .parent

  @TSCodable
  enum Decision: PairNestable {
    case rejected
    case accepted(durationInSeconds: Int, extraMonitoring: String?)
  }

  struct Input: PairInput {
    var id: MacApp.SuspendFilterRequest.Id
    var decision: Decision
    var responseComment: String?
  }
}

// resolver

extension DecideFilterSuspensionRequest: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    var suspendFilterRequest = try await context.db.find(input.id)
    let userDevice = try await suspendFilterRequest.computerUser(in: context.db)
    try await context.verifiedChild(from: userDevice.childId)

    suspendFilterRequest.responseComment = input.responseComment
    let decision = input.decision.filterSuspensionDecision

    switch decision {
    case .accepted(let duration, let extraMonitoring):
      guard (60 ... 7 * 24 * 60 * 60).contains(duration.rawValue) else {
        throw context.error(
          id: "9212fa5e",
          type: .badRequest,
          debugMessage: "suspension duration out of range: \(duration.rawValue)s",
          userMessage: "Choose a suspension between 1 minute and 7 days.",
        )
      }
      suspendFilterRequest.duration = duration
      suspendFilterRequest.status = .accepted
      suspendFilterRequest.extraMonitoring = extraMonitoring?.magicString
    case .rejected:
      suspendFilterRequest.status = .rejected
    }

    try await context.db.update(suspendFilterRequest)

    try await with(dependency: \.websockets).send(
      .filterSuspensionRequestDecided_v2(
        id: suspendFilterRequest.id.rawValue,
        decision: suspendFilterRequest.decision ?? .rejected,
        comment: suspendFilterRequest.responseComment,
      ),
      to: .userDevice(userDevice.id),
    )

    return .success
  }
}

// extensions

extension DecideFilterSuspensionRequest.Decision {
  var filterSuspensionDecision: FilterSuspensionDecision {
    switch self {
    case .rejected:
      .rejected
    case .accepted(let durationInSeconds, let magicString):
      .accepted(
        duration: .init(durationInSeconds),
        extraMonitoring: magicString
          .flatMap(FilterSuspensionDecision.ExtraMonitoring.init(magicString:)),
      )
    }
  }
}
