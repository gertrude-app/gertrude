import IOSRoute

extension SelfReportSupervision: Resolver {
  static func resolve(
    with input: Input,
    in ctx: IOSApp.ChildContext,
  ) async throws -> Output {
    guard var supervision = try await ctx.device.supervision(in: ctx.db) else {
      logIOSUnexpected("f9797be9", "unreachable, \(ctx.device.id)")
      return .success
    }

    let wasSupervised = supervision.supervised
    supervision.supervisedAt = input.isSupervised ? get(dependency: \.date.now) : nil

    try await ctx.db.update(supervision)

    try await ctx.db.create(IOSEvent(
      eventId: "80451da8",
      kind: .supervision,
      detail: "self_reported_supervision: was=\(wasSupervised) now=\(input.isSupervised)",
      deviceId: ctx.device.id,
      modelIdentifier: ctx.device.modelIdentifier,
      iosVersion: ctx.device.iosVersion,
    ))

    return .success
  }
}
