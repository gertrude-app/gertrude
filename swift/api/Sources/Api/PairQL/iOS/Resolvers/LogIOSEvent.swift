import IOSRoute

extension LogIOSEvent: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let kind: IOSEvent.Kind = if input.detail?.contains("[onboarding]") == true {
      .onboarding
    } else if input.detail?.contains("controller proxy") == true
      || input.detail?.contains("filter install") == true {
      .filter
    } else {
      .info
    }

    var detail = input.detail
    if detail?.hasPrefix("[onboarding]: ") == true {
      detail = String(detail!.dropFirst("[onboarding]: ".count))
    } else if detail?.hasPrefix("[onboarding] ") == true {
      detail = String(detail!.dropFirst("[onboarding] ".count))
    }

    try await context.db.create(IOSEvent(
      eventId: input.eventId,
      kind: kind,
      detail: detail,
      vendorId: input.vendorId,
      deviceType: input.deviceType,
      iosVersion: input.iOSVersion,
    ))

    if context.env.mode == .prod,
       input.eventId == "8d35f043",
       let vendorId = input.vendorId {
      let adminUrl = context.env.get("ADMIN_SITE_URL") ?? "http://localhost:4243"
      let eventLink = "\(adminUrl)/ios/\(vendorId.lowercased)/events"
      let events = Slack.link(to: eventLink, withText: "see events")
      let region = detail?.split(separator: "`").dropFirst().first.map { "`\($0)`" } ?? "`unknown`"
      let stats = "region: \(region), device: `\(input.deviceType)`, iOS: `\(input.iOSVersion)`,"
      let message = "*iOS First Launch*, \(stats) \(events)"
      await get(dependency: \.slack).internal(.iosOnboarding, message)
    }

    return .success
  }
}
