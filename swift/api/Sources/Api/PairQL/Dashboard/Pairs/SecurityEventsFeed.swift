import DuetSQL
import Gertie
import PairQL
import TSCodable

struct SecurityEventsFeed: Pair {
  static let auth: ClientAuth = .parent

  enum Severity: String, PairNestable {
    case all
    case medium
    case recommended
  }

  struct ChildSecurityEvent: PairNestable {
    var id: SecurityEvent.Id
    var childId: Child.Id
    var childName: String
    var deviceId: Computer.Id
    var deviceName: String
    var event: String
    var detail: String?
    var explanation: String
    var severity: Severity
    var createdAt: Date
  }

  struct AdminSecurityEvent: PairNestable {
    var id: SecurityEvent.Id
    var event: String
    var detail: String?
    var explanation: String
    var severity: Severity
    var ipAddress: String?
    var createdAt: Date
  }

  @TSCodable
  enum FeedEvent: PairOutput {
    case child(ChildSecurityEvent)
    case admin(AdminSecurityEvent)
  }

  typealias Output = [FeedEvent]
}

extension SecurityEventsFeed.Severity {
  init(_ severity: Gertie.SecurityEvent.Severity) {
    switch severity {
    case .all: self = .all
    case .medium: self = .medium
    case .recommended: self = .recommended
    }
  }
}

// resolver

extension SecurityEventsFeed: NoInputResolver {
  static func resolve(in context: ParentContext) async throws -> Output {
    let models = try await SecurityEvent.query()
      .where(.parentId == context.parent.id)
      .where(.createdAt >= Date(subtractingDays: 14))
      .orderBy(.createdAt, .desc)
      .all(in: context.db)

    let children = try await context.parent.children(in: context.db)
      .reduce(into: [Child.Id: Child]()) { result, user in
        result[user.id] = user
      }

    let computers = try await context.parent.computers(in: context.db)
    let computerUsers = try await ComputerUser.query()
      .where(.computerId |=| computers.map(\.id))
      .all(in: context.db)
      .reduce(into: [ComputerUser.Id: ComputerUser]()) { result, computerUser in
        result[computerUser.id] = computerUser
      }

    return models.compactMap { model in
      if let computerUserId = model.computerUserId {
        guard let computerUser = computerUsers[computerUserId],
              let child = children[computerUser.childId],
              let computer = computers.first(where: { $0.id == computerUser.computerId }),
              let event = Gertie.SecurityEvent.MacApp(rawValue: model.event) else {
          return nil
        }
        return .child(.init(
          id: model.id,
          childId: child.id,
          childName: child.name,
          deviceId: computerUser.computerId,
          deviceName: computer.customName ?? computer.model.shortDescription,
          event: event.toWords,
          detail: model.detail,
          explanation: event.explanation,
          severity: .init(event.severity),
          createdAt: model.createdAt,
        ))
      } else {
        guard let event = Gertie.SecurityEvent.Dashboard(rawValue: model.event) else {
          return nil
        }
        return .admin(.init(
          id: model.id,
          event: event.toWords,
          detail: model.detail,
          explanation: event.explanation,
          severity: .init(event.severity),
          ipAddress: model.ipAddress,
          createdAt: model.createdAt,
        ))
      }
    }
  }
}
