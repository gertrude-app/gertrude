import IOSRoute

extension SelfReportSupervision: Resolver {
  static func resolve(
    with input: Input,
    in ctx: IOSApp.ChildContext,
  ) async throws -> Output {
    var device = ctx.device
    let wasSupervised = device.isSupervised
    device.isSupervised = input.isSupervised

    try await ctx.db.update(device)

    try await ctx.db.create(IOSEvent(
      eventId: "80451da8",
      kind: .supervision,
      detail: "self_reported_supervision: was=\(wasSupervised) now=\(input.isSupervised)",
      deviceId: device.id,
      modelIdentifier: device.modelIdentifier,
      iosVersion: device.iosVersion,
    ))

    return .success
  }
}
