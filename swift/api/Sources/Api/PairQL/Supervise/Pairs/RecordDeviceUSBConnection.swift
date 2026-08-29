import Dependencies
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

    let child = try await context.db.find(validated.claimedChildId)
    let parent = try await child.parent(in: context.db)
    let account = try await parent.billingAccountSnapshot(
      in: context.db,
      at: get(dependency: \.date.now),
    )
    if account.can(.superviseIosDevice), let limit = account.supervisedIOSDeviceLimit {
      let supervised = try await parent.supervisedIOSDevices(in: context.db)
      if !supervised.alreadyIncludes(udid: input.udid), supervised.count >= limit {
        let parentLink = AdminLink().slack(to: .parent(parent.id), text: parent.email.rawValue)
        Task {
          await get(dependency: \.slack)
            .internal(
              .info,
              "*iOS supervision:* new device blocked (over device limit), \(parentLink)",
            )
        }
        throw context.error(
          id: "d6c63cab",
          type: .badRequest,
          debugMessage: "supervised device limit reached (\(supervised.count)/\(limit))",
          userMessage: SUPERVISED_DEVICE_LIMIT_MESSAGE,
          showContactSupport: true,
        )
      }
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

let SUPERVISED_DEVICE_LIMIT_MESSAGE = """
This account has supervised more iPhones and iPads than Gertrude allows. Gertrude is \
built for parents and accountability partners helping kids and friends. If that \
describes you and you need more devices, get in touch and we'll sort it out with you.
"""
