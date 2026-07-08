import DuetSQL
import PairQL
import Vapor

struct IOSDeviceEvents: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    var vendorId: UUID
  }

  struct Output: PairOutput {
    var vendorId: UUID
    var modelName: String
    var deviceType: String
    var iosVersion: String
    var firstLaunch: Date?
    var lastCheckin: Date?
    var reachedOptOut: Bool
    var connectedAccount: IOSDevice.ConnectedAccount?
    var prevVendorId: IOSDevice.Id?
    var nextVendorId: IOSDevice.Id?
    var events: [Event]
  }

  struct Event: PairNestable {
    var id: String
    var eventId: String
    var label: String
    var detail: String?
    var createdAt: Date
    var elapsedSeconds: Int?
  }
}

extension IOSDeviceEvents: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let events = try await IOSEvent.query()
      .where(.deviceId == input.vendorId)
      .orderBy(.createdAt, .asc)
      .all(in: context.db)

    guard !events.isEmpty else {
      throw Abort(.notFound)
    }

    let firstLaunch = events.first { $0.eventId == "8d35f043" }
    let lastCheckin = events.last { $0.domain == "checkin" }
    let reachedOptOut = events.contains { $0.eventId == "cdb31095" }
    let modelIdentifier = firstLaunch?.modelIdentifier ?? events.first?.modelIdentifier ?? "Unknown"
    let modelName = ModelIdentifier.marketingName(for: modelIdentifier)
    let deviceType = ModelIdentifier.deviceType(from: modelIdentifier)
    let iosVersion = firstLaunch?.iosVersion ?? events.first?.iosVersion ?? "Unknown"

    var prevVendorId: IOSDevice.Id?
    var nextVendorId: IOSDevice.Id?
    if let firstLaunchDate = firstLaunch?.createdAt {
      if let prev = try? await IOSEvent.query()
        .where(.eventId == "8d35f043")
        .where(.deviceId != input.vendorId)
        .where(.createdAt >= firstLaunchDate)
        .orderBy(.createdAt, .asc)
        .first(in: context.db) {
        prevVendorId = prev.deviceId
      }
      if let next = try? await IOSEvent.query()
        .where(.eventId == "8d35f043")
        .where(.deviceId != input.vendorId)
        .where(.createdAt <= firstLaunchDate)
        .orderBy(.createdAt, .desc)
        .first(in: context.db) {
        nextVendorId = next.deviceId
      }
    }

    var connectedAccount: IOSDevice.ConnectedAccount?
    if let device = try? await context.db.find(IOSDevice.Id(input.vendorId)) as IOSDevice {
      connectedAccount = try await device.connectedAccount(in: context.db)
    }

    let filteredEvents = events.filter { !["b977cfdc", "06329f27"].contains($0.eventId) }
    var outputEvents: [Event] = []
    for (index, event) in filteredEvents.enumerated() {
      let elapsedSeconds: Int?
      if index == 0 {
        elapsedSeconds = nil
      } else {
        let previousEvent = filteredEvents[index - 1]
        elapsedSeconds = Int(event.createdAt.timeIntervalSince(previousEvent.createdAt))
      }
      outputEvents.append(Event(
        id: event.id.rawValue.uuidString,
        eventId: event.eventId,
        label: EventLabel.blocker(event.eventId) ?? event.eventId,
        detail: event.detail,
        createdAt: event.createdAt,
        elapsedSeconds: elapsedSeconds,
      ))
    }

    return .init(
      vendorId: input.vendorId,
      modelName: modelName,
      deviceType: deviceType,
      iosVersion: iosVersion,
      firstLaunch: firstLaunch?.createdAt,
      lastCheckin: lastCheckin?.createdAt,
      reachedOptOut: reachedOptOut,
      connectedAccount: connectedAccount,
      prevVendorId: prevVendorId,
      nextVendorId: nextVendorId,
      events: outputEvents,
    )
  }
}
