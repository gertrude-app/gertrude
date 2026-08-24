import Foundation
import PairQL
import TSCodable

struct GetSecurityEvents: Pair {
  static let auth: ClientAuth = .parent

  enum Severity: String, PairNestable {
    case high
    case medium
    case low
  }

  struct MacAppEvent: PairNestable {
    let id: SecurityEvent.Id
    let personId: Child.Id
    let personName: String
    let deviceId: Computer.Id
    let deviceName: String
    let title: String
    let detail: String?
    let explanation: String
    let severity: Severity
    let createdAt: Date
  }

  struct AccountEvent: PairNestable {
    let id: SecurityEvent.Id
    let title: String
    let detail: String?
    let explanation: String
    let severity: Severity
    let ipAddress: String?
    let createdAt: Date
  }

  @TSCodable
  enum Event: PairOutput {
    case macApp(MacAppEvent)
    case account(AccountEvent)
  }

  typealias Output = [Event]
}

extension GetSecurityEvents.Severity {
  init(_ severity: SecurityEventsFeed.Severity) {
    switch severity {
    case .recommended: self = .high
    case .medium: self = .medium
    case .all: self = .low
    }
  }
}

extension GetSecurityEvents.Event {
  init(_ event: SecurityEventsFeed.FeedEvent) {
    switch event {
    case .child(let event):
      self = .macApp(.init(
        id: event.id,
        personId: event.childId,
        personName: event.childName,
        deviceId: event.deviceId,
        deviceName: event.deviceName,
        title: event.event,
        detail: event.detail,
        explanation: event.explanation,
        severity: .init(event.severity),
        createdAt: event.createdAt,
      ))
    case .admin(let event):
      self = .account(.init(
        id: event.id,
        title: event.event,
        detail: event.detail,
        explanation: event.explanation,
        severity: .init(event.severity),
        ipAddress: event.ipAddress,
        createdAt: event.createdAt,
      ))
    }
  }
}

extension GetSecurityEvents: NoInputResolver {
  static func resolve(in context: AccountOwnerContext) async throws -> Output {
    try await SecurityEventsFeed.resolve(in: context.legacyContext)
      .map(Event.init)
  }
}
