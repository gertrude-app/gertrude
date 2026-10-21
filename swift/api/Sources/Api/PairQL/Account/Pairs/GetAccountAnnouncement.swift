import DuetSQL
import PairQL

struct GetAccountAnnouncement: Pair {
  static let auth: ClientAuth = .parent

  struct Announcement: PairNestable {
    var id: DashAnnouncement.Id
    var kind: DashAnnouncement.Kind
    var html: String
    var action: DashAnnouncement.Action?
  }

  struct Output: PairOutput {
    var announcement: Announcement?
  }
}

extension GetAccountAnnouncement: NoInputResolver {
  static func resolve(in context: AccountOwnerContext) async throws -> Output {
    let announcement = try await DashAnnouncement.query()
      .where(.parentId == context.accountOwner.id)
      .orderBy(.createdAt, .asc)
      .limit(1)
      .all(in: context.db)
      .first

    return .init(announcement: announcement.map { .init(
      id: $0.id,
      kind: $0.kind,
      html: $0.html,
      action: $0.action,
    ) })
  }
}
