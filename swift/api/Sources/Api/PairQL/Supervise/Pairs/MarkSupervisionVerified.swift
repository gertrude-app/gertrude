import DuetSQL
import PairQL

// we send this pair from the supervision tauri app after the device reboots
// and we instruct the parent to visually confirm in the ios device that it
// is now supervised (from Settings app), as this is the only foolproof way
// to confirm supervision. they tap "yes supervised" on the tauri app UI, which
// fires this request, so that we can mark the device supervised
struct MarkSupervisionVerified: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let code: Int
  }

  typealias Output = Infallible
}

extension MarkSupervisionVerified: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let validated = try await SuperviseRoute.validatedSupervisionCode(
      code: input.code,
      baseId: "1f768983", // 1f768983-1, 1f768983-2, 1f768983-3, 1f768983-4, 1f768983-5
      in: context,
    )

    var supervision = validated.supervision
    supervision.supervisedAt = get(dependency: \.date.now)
    try await context.db.update(supervision)

    try await context.db.create(IOSEvent(
      eventId: "09748184",
      kind: .supervision,
      detail: "supervision_verified: code=\(input.code)",
      deviceId: validated.device.id,
      modelIdentifier: validated.device.modelIdentifier,
      iosVersion: validated.device.iosVersion,
    ))

    Task {
      await get(dependency: \.slack)
        .internal(.info, "*iOS supervision:* supervision verified from tool, code `\(input.code)`")
    }

    return .success
  }
}
