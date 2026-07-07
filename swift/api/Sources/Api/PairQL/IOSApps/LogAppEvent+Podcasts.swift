import Dependencies
import DuetSQL
import Foundation
import GertieApp
import IOSAppsRoute
import XSlack

extension LogAppEvent {
  static func resolvePodcastEvent(_ input: Input, in context: Context) async throws -> Output {
    let deviceId = input.deviceId.map { IOSDevice.Id($0) }

    if let deviceId {
      try await PodcastApp.Install.ensureExists(
        deviceId: deviceId,
        modelIdentifier: input.modelIdentifier,
        iosVersion: input.iosVersion,
        appVersion: input.appVersion,
        in: context.db,
      )
    }

    try await context.db.create(PodcastEvent(
      eventId: input.eventId,
      level: input.level,
      domain: input.domain,
      detail: input.detail,
      deviceId: deviceId,
      modelIdentifier: input.modelIdentifier,
      appVersion: input.appVersion,
      iosVersion: input.iosVersion,
    ))

    ModelIdentifier.alertIfUnknown(input.modelIdentifier)

    if context.env.mode != .prod || input.level == .debug || suppressedEventIds
      .contains(input.eventId) {
      return .success
    }

    let iapTxnId = extractPodcastLegacyIAPTxnId(input.detail)
    let isFamilyShareIapEvent = iapTxnId.map { !iapIdIsRootPurchase($0) } ?? false

    Task {
      let slack = get(dependency: \.slack)

      if isFamilyShareIapEvent {
        if try await isPodcastFirstFamilyShareForDevice(input, deviceId: deviceId, in: context) {
          await slack.internal(
            .info,
            "*FIRST Podcast Family-Sharing Activation* `\(input.modelName)`",
          )
        }
        return // don't log duplicate family share txn events
      }

      let search = githubSearch(input.eventId)
      let name = EventLabel.name(input.app, input.eventId) ?? input.eventId
      let msg = "`\(name)`\(input.detail.map { " - \($0)" } ?? "")"
      await slack.internal(.podcasts, "Podcast app event: \(search) \(msg)")

      if try await isPodcastFirstPayment(input, in: context) {
        await slack.internal(.info, "*FIRST Podcast Subscription* `\(input.modelName)`")
        await slack.internal(.podcasts, "*FIRST Podcast Subscription* `\(input.modelName)`")
        get(dependency: \.postmark).toSuperAdmin(
          "FIRST Podcast Subscription",
          "device: \(input.modelName)",
        )
      }

      if input.eventId == midClaimPinSetEventId, let deviceId {
        try await alertSuperAdminOfMidClaimPinSet(input, deviceId: deviceId, in: context)
      }
    }

    return .success
  }
}

// helpers

private func isPodcastFirstPayment(
  _ input: LogEventRequest,
  in ctx: Context,
) async throws -> Bool {
  guard isPodcastLegacyIAPPaymentEvent(input.eventId),
        let iapTxnId = extractPodcastLegacyIAPTxnId(input.detail),
        iapIdIsRootPurchase(iapTxnId) else {
    return false
  }
  let paidEventCount = try await ctx.db.count(
    HostPurchaseEventCountForOriginalID.self,
    withBindings: [.string(iapTxnId)],
  )
  return paidEventCount == 1
}

private func isPodcastFirstFamilyShareForDevice(
  _ input: LogEventRequest,
  deviceId: IOSDevice.Id?,
  in ctx: Context,
) async throws -> Bool {
  guard let deviceId, isPodcastLegacyIAPPaymentEvent(input.eventId) else {
    return false
  }
  let count = try await ctx.db.count(
    FamilySharedOrSandboxEventCountForDevice.self,
    withBindings: [.uuid(deviceId)],
  )
  return count == 1
}

private func alertSuperAdminOfMidClaimPinSet(
  _ input: LogEventRequest,
  deviceId: IOSDevice.Id,
  in ctx: Context,
) async throws {
  let device = try await ctx.db.find(deviceId)
  guard let child = try await device.child(in: ctx.db) else { return }
  let parent = try await child.parent(in: ctx.db)
  get(dependency: \.postmark).toSuperAdmin(
    "Podcasts PIN set after mid-claim relaunch",
    "device: \(input.modelName), child: \(child.name), parent: \(parent.email.rawValue) — "
      + "the Podcasts PIN may have been set by someone other than the parent (app killed between "
      + "claim and PIN setup). Consider emailing the parent about a dashboard PIN reset.",
  )
}

private let suppressedEventIds: Set<String> = [
  "7785c87b", // subscribe event, noisy, not super interesting
  "4ac9084e", // skipped download invalidation while active
  "d299b47a", // episode play recovered after file check
  "2e2c9e97", // episode play recovery failed
  "8c975d36", // download success invalidated before commit
  "eeaa7b30", // legacy (v1.2): episode play, missing local file
  "45692a47", // legacy (v1.2-1.3): missing file for downloaded episode
  "ba664a9f", // legacy (v1.3): play missing file, recovered
  "4fa186eb", // legacy (v1.3): play missing file, dl failed
]
