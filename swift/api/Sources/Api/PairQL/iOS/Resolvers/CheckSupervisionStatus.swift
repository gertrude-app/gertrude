import Dependencies
import DuetSQL
import IOSRoute
import Vapor

extension CheckSupervisionStatus: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    let device = try? await IOSApp.Device.query()
      .where(.supervisionClaimCode == input.code)
      .first(in: ctx.db)

    guard let device else {
      return .notFound
    }

    if device.id.rawValue != input.vendorId {
      logIOSUnusual("233c41a8", "vendorId mismatch, c=\(input.code), v=\(input.vendorId)")
      return .notFound
    }

    guard let childId = device.childId else {
      if let expiresAt = device.claimCodeExpiresAt, expiresAt < get(dependency: \.date.now) {
        logIOSUnusual("92fe7bb1", "expired, code=\(input.code)")
        return .expired
      }
      return .pending
    }

    let child = try await ctx.db.find(childId)

    if !device.isSupervised {
      return .claimed(.init(childName: child.name))
    }

    if !device.isProfileInstalled {
      let token: IOSApp.Token
      let existingToken = try? await IOSApp.Token.query()
        .where(.deviceId == device.id)
        .first(in: ctx.db)
      if let existingToken {
        token = existingToken
      } else {
        token = try await ctx.db.create(IOSApp.Token(deviceId: device.id))
      }
      return .supervised(.init(
        childName: child.name,
        deviceToken: token.value.rawValue,
        // TODO: superios task 07 will handle this
        profileUrl: "https://todo.com/future/task/",
      ))
    }

    return .complete
  }
}

func logIOSUnusual(_ id: String, _ detail: String) {
  guard get(dependency: \.env.mode) == .prod else { return }
  Task.detached {
    _ = try? await get(dependency: \.db).create(InterestingEvent(
      eventId: id,
      kind: "event",
      context: "iosapp",
      detail: detail,
    ))
    await get(dependency: \.slack)
      .internal(.iosLogs, "unusual iOS event: `\(id)` \(detail)")
  }
}

func logIOSUnexpected(_ id: String, _ detail: String) {
  guard get(dependency: \.env.mode) == .prod else { return }
  logIOSUnusual(id, detail)
  get(dependency: \.postmark)
    .toSuperAdmin("UNEXPECTED iOS event", "\(id), \(detail)")
}
