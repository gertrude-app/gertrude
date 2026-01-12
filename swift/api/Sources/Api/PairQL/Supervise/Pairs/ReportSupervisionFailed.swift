import DuetSQL
import PairQL

// we send this pair from the supervision tauri app after the device reboots
// and we instruct the parent to visually confirm in the ios device that it
// is now supervised (from Settings app), as this is the only foolproof way
// to confirm supervision. if they tap "no, not supervised" on the tauri app UI,
// which fires this request, record the failure, to add to the audit trail
// of events and aid us in helping them recover/resume, and us to know failure points
struct ReportSupervisionFailed: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let code: Int
  }

  typealias Output = Infallible
}

extension ReportSupervisionFailed: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let validated = try await SuperviseRoute.validatedSupervisionCode(
      code: input.code,
      baseId: "e29b7f89", // e29b7f89-1, e29b7f89-2, e29b7f89-3
      in: context,
    )

    let device = try? await IOSApp.Device.query()
      .where(.childId == validated.claimedChildId)
      .where(.vendorId == validated.pendingSupervision.vendorId)
      .first(in: context.db)

    try await context.db.create(IOSEvent(
      eventId: "df3914fa",
      kind: .supervision,
      detail: "supervision_failed: code=\(input.code)",
      vendorId: validated.pendingSupervision.vendorId,
      iosDeviceId: device?.id,
      modelIdentifier: validated.pendingSupervision.modelIdentifier,
      iosVersion: validated.pendingSupervision.iosVersion,
    ))

    return .success
  }
}
