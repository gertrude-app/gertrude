import BlockerRoute

extension LogIOSEvent_v2: Resolver {
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

    var deviceId: IOSDevice.Id?
    if let vendorId = input.vendorId {
      deviceId = .init(vendorId)
      try await BlockerApp.Install.ensureExists(
        deviceId: deviceId!,
        modelIdentifier: input.modelIdentifier,
        iosVersion: input.iOSVersion,
        appVersion: input.appVersion,
        in: context.db,
      )
    }

    try await context.db.create(IOSEvent(
      eventId: input.eventId,
      kind: kind,
      detail: detail,
      deviceId: deviceId,
      modelIdentifier: input.modelIdentifier,
      iosVersion: input.iOSVersion,
    ))

    ModelIdentifier.alertIfUnknown(input.modelIdentifier)

    if context.env.mode == .prod,
       input.eventId == "8d35f043",
       let vendorId = input.vendorId {
      let events = AdminLink().slack(to: .iosDeviceEvents(vendorId: vendorId), text: "see events")
      let region = detail?.split(separator: "`").dropFirst().first.map { "`\($0)`" } ?? "`unknown`"
      let stats = "region: \(region), device: `\(input.modelName)`, iOS: `\(input.iOSVersion)`,"
      let message = "*iOS First Launch*, \(stats) \(events)"
      await get(dependency: \.slack).internal(.iosOnboarding, message)
    }

    if context.env.mode == .prod, input.eventId == "84555fc8" {
      var message = "*iOS Self-Management Dead End*"
      if let vendorId = input.vendorId {
        let events = AdminLink().slack(to: .iosDeviceEvents(vendorId: vendorId), text: "see events")
        message += " \(events)"
      }
      await get(dependency: \.slack).internal(.info, message)
    }

    if context.env.mode == .prod, input.eventId == "7c039b10" {
      let device = "`\(input.modelName)`, iOS `\(input.iOSVersion)`, app `\(input.appVersion)`"
      let eventDetail = detail ?? "(no detail)"
      var message = "*iOS Unhandled Button* \(device)\n\(eventDetail)"
      if let vendorId = input.vendorId {
        let events = AdminLink().slack(to: .iosDeviceEvents(vendorId: vendorId), text: "see events")
        message += " \(events)"
      }
      await get(dependency: \.slack).error(message)
      get(dependency: \.postmark).unexpected("7c039b10", "\(device)<br/><br/>\(eventDetail)")
    }

    return .success
  }
}
