import Dependencies
import DuetSQL
import IOSRoute
import Vapor

extension CheckSupervisionStatus: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    let pendingSupervision = try? await IOSApp.PendingSupervision
      .query()
      .where(.code == .int(input.code))
      .first(in: ctx.db)

    guard let pendingSupervision else {
      return .notFound
    }

    if pendingSupervision.vendorId != input.vendorId {
      logIOSUnusual("233c41a8", "vendorId mismatch, c=\(input.code), v=\(input.vendorId)")
      return .notFound
    }

    if pendingSupervision.expiresAt < get(dependency: \.date.now) {
      logIOSUnusual("92fe7bb1", "expired, code=\(input.code)")
      return .expired
    }

    guard let childId = pendingSupervision.claimedChildId else {
      return .pending
    }

    let device = try? await IOSApp.Device.query()
      .where(.childId == childId)
      .where(.vendorId == input.vendorId)
      .first(in: ctx.db)

    guard let device else {
      logIOSUnexpected("05444534", "c=\(input.code), v=\(input.vendorId)")
      return .notFound
    }

    let child = try await ctx.db.find(childId)
    if device.supervisedAt == nil {
      return .claimed(.init(childName: child.name))
    }

    if device.profileFirstInstalledAt == nil {
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
