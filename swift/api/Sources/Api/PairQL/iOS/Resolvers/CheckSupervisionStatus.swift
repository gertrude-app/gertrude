import Dependencies
import DuetSQL
import IOSRoute
import Vapor

extension CheckSupervisionStatus: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    let supervision = try? await IOSApp.Supervision.query()
      .where(.claimCode == input.code)
      .first(in: ctx.db)

    guard let supervision else {
      return .notFound
    }
    let device = try await supervision.device(in: ctx.db)

    if device.id.rawValue != input.vendorId {
      logIOSUnusual("233c41a8", "vendorId mismatch, c=\(input.code), v=\(input.vendorId)")
      return .notFound
    }

    guard let childId = device.childId else {
      if supervision.claimCodeExpiresAt < get(dependency: \.date.now) {
        logIOSUnusual("92fe7bb1", "expired, code=\(input.code)")
        return .expired
      }
      return .pending
    }

    let child = try await ctx.db.find(childId)
    let token: IOSApp.Token
    let existingToken = try? await IOSApp.Token.query()
      .where(.deviceId == device.id)
      .first(in: ctx.db)
    if let existingToken {
      token = existingToken
    } else {
      token = try await ctx.db.create(IOSApp.Token(deviceId: device.id))
    }

    let data = ChildIOSDeviceData_v2(
      childId: child.id.rawValue,
      token: token.value.rawValue,
      deviceId: device.id.rawValue,
      childName: child.name,
      supervised: .byGertrude(claimCode: supervision.claimCode),
    )

    if supervision.supervisedAt == nil {
      return .claimed(data)
    }

    if supervision.profileInstalledAt == nil {
      return .missingProfile(data)
    }

    return .complete(data)
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
      .internal(.iosLogs, "unusual iOS event: \(githubSearch(id)) \(detail)")
  }
}

func logIOSUnexpected(_ id: String, _ detail: String) {
  guard get(dependency: \.env.mode) == .prod else { return }
  logIOSUnusual(id, detail)
  get(dependency: \.postmark)
    .toSuperAdmin("UNEXPECTED iOS event", "\(id), \(detail)")
}
