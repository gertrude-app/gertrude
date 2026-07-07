import DuetSQL
import PairQL

// we get this request when the parent/accountability partner has plugged
// in the device to their computer and trusted, after it verifies that it's
// the expected device (matching the model that created the code), it sends us
// this which gives us the device UDID, and lets us know that the device
// has been at least connected via USB for the supervision process to start
struct RecordDeviceUSBConnection: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let code: Int
    let udid: String
    let modelIdentifier: String
  }

  typealias Output = Infallible
}

extension RecordDeviceUSBConnection: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let validated = try await SuperviseRoute.validatedSupervisionCode(
      code: input.code,
      baseId: "421f7e7d", // 421f7e7d-1, 421f7e7d-2, 421f7e7d-3, 421f7e7d-4, 421f7e7d-5
      in: context,
    )

    guard input.modelIdentifier == validated.device.modelIdentifier else {
      logIOSUnexpected("d78fbde0", "model identifier mismatch")
      throw context.error("d78fbde0", .badRequest, user: "Unexpected error")
    }

    var supervision = validated.supervision
    let device = validated.device

    if let existingUdid = supervision.udid, existingUdid != input.udid {
      logIOSUnexpected("6eaabffb", "udid mismatch")
      throw context.error("6eaabffb", .badRequest, user: "Unexpected error")
    }

    supervision.udid = input.udid
    try await context.db.update(supervision)

    try await context.db.create(IOSEvent(
      eventId: "86af13a9",
      domain: "supervision",
      detail: "tool_connected: code=\(input.code), udid=\(input.udid), model=\(input.modelIdentifier)",
      deviceId: device.id,
      modelIdentifier: input.modelIdentifier,
      iosVersion: validated.device.iosVersion,
    ))
    return .success
  }
}
