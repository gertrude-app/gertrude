import DuetSQL
import PairQL

struct LogSupervisionEvent: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let code: Int
    let event: String
    let detail: String
  }

  typealias Output = Infallible
}

extension LogSupervisionEvent: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let validated = try await SuperviseRoute.validatedSupervisionCode(
      code: input.code,
      baseId: "f91992ac", // f91992ac-1, f91992ac-2, f91992ac-3
      in: context,
    )

    try await context.db.create(IOSEvent(
      eventId: "016d03db",
      kind: .supervision,
      detail: "\(input.event): \(input.detail)",
      deviceId: validated.device.id,
      modelIdentifier: validated.device.modelIdentifier,
      iosVersion: validated.device.iosVersion,
    ))

    return .success
  }
}
