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
      baseId: "1f768983", // 1f768983-1, 1f768983-2, 1f768983-3
      in: context,
    )

    var device = try await IOSApp.Device.query()
      .where(.childId == validated.claimedChildId)
      .where(.vendorId == validated.pendingSupervision.vendorId)
      .first(in: context.db)

    device.isSupervised = true
    try await context.db.update(device)

    try await context.db.create(IOSEvent(
      eventId: "09748184",
      kind: .supervision,
      detail: "supervision_verified: code=\(input.code)",
      vendorId: validated.pendingSupervision.vendorId,
      iosDeviceId: device.id,
      modelIdentifier: device.modelIdentifier,
      iosVersion: validated.pendingSupervision.iosVersion,
    ))

    return .success
  }
}
