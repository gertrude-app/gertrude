import DuetSQL
import Foundation
import GertieApp
import IOSAppsRoute

extension LogAppEvent {
  static func resolveBlockerEvent(_ input: Input, in context: Context) async throws -> Output {
    let detail = input.detail
    let domain = input.domain

    var deviceId: IOSDevice.Id?
    if let vendorId = input.deviceId {
      deviceId = .init(vendorId)
      try await BlockerApp.Install.ensureExists(
        deviceId: deviceId!,
        modelIdentifier: input.modelIdentifier,
        iosVersion: input.iosVersion,
        appVersion: input.appVersion,
        in: context.db,
      )
    }

    try await context.db.create(IOSEvent(
      eventId: input.eventId,
      level: input.level,
      domain: domain,
      detail: detail,
      deviceId: deviceId,
      modelIdentifier: input.modelIdentifier,
      iosVersion: input.iosVersion,
      appVersion: input.appVersion,
    ))

    ModelIdentifier.alertIfUnknown(input.modelIdentifier)

    if context.env.mode == .prod,
       input.eventId == "8d35f043",
       let vendorId = input.deviceId {
      let events = AdminLink().slack(to: .iosDeviceEvents(vendorId: vendorId), text: "see events")
      let region = detail?.split(separator: "`").dropFirst().first.map { "`\($0)`" } ?? "`unknown`"
      let stats = "region: \(region), device: `\(input.modelName)`, iOS: `\(input.iosVersion)`,"
      let message = "*iOS First Launch*, \(stats) \(events)"
      await get(dependency: \.slack).internal(.iosOnboarding, message)
    }

    if context.env.mode == .prod, input.eventId == "84555fc8" {
      var message = "*iOS Self-Management Dead End*"
      if let vendorId = input.deviceId {
        let events = AdminLink().slack(to: .iosDeviceEvents(vendorId: vendorId), text: "see events")
        message += " \(events)"
      }
      await get(dependency: \.slack).internal(.info, message)
    }

    if context.env.mode == .prod, input.eventId == "7c039b10" {
      let device = "`\(input.modelName)`, iOS `\(input.iosVersion)`, app `\(input.appVersion)`"
      let eventDetail = detail ?? "(no detail)"
      var message = "*iOS Unhandled Button* \(device)\n\(eventDetail)"
      if let vendorId = input.deviceId {
        let events = AdminLink().slack(to: .iosDeviceEvents(vendorId: vendorId), text: "see events")
        message += " \(events)"
      }
      await get(dependency: \.slack).error(message)
      get(dependency: \.postmark).unexpected("7c039b10", "\(device)<br/><br/>\(eventDetail)")
    }

    if context.env.mode == .prod, input.eventId == blockerCrossPromoImageFailedEventId {
      let device = "`\(input.modelName)`, iOS `\(input.iosVersion)`, app `\(input.appVersion)`"
      var message = "*iOS Cross Promo Image Failed* \(device)\n\(detail ?? "(no detail)")"
      if let vendorId = input.deviceId {
        let events = AdminLink().slack(to: .iosDeviceEvents(vendorId: vendorId), text: "see events")
        message += " \(events)"
      }
      await get(dependency: \.slack).error(message)
    }

    return .success
  }
}

private let blockerCrossPromoImageFailedEventId = "670a86df"
