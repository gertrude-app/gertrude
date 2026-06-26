import Dependencies
import DuetSQL
import IOSRoute
import Vapor

extension CheckSupervisionFlowStatus: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    guard var claim = try await Claim.find(code: input.code, in: ctx.db) else {
      return .notFound
    }
    let device = try await claim.device(in: ctx.db)

    if device.id.rawValue != input.vendorId {
      logIOSUnusual("233c41a8", "vendorId mismatch, c=\(input.code), v=\(input.vendorId)")
      return .notFound
    }

    if claim.intent != .blockerSupervise {
      logIOSUnusual("e7b25c80", "intent mismatch, c=\(input.code), intent=\(claim.intent)")
      return .notFound
    }

    guard let childId = device.childId else {
      if claim.expiresAt < get(dependency: \.date.now) {
        logIOSUnusual("92fe7bb1", "expired, code=\(input.code)")
        return .expired
      }
      return .pending
    }

    let child = try await ctx.db.find(childId)
    guard let supervision = try await device.supervision(in: ctx.db) else {
      return .notFound
    }

    try await claim.renewIfPendingSupervision(supervision: supervision, in: ctx.db)

    let install = try await device.blockerInstall(in: ctx.db)
    let token = try await ctx.db.findOrCreate(
      BlockerApp.Token(installId: install.id),
      conflictOn: [.installId],
    )

    let data = ChildIOSDeviceData_v2(
      childId: child.id.rawValue,
      token: token.value.rawValue,
      deviceId: device.id.rawValue,
      childName: child.name,
      supervised: .byGertrude(claimCode: input.code),
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
