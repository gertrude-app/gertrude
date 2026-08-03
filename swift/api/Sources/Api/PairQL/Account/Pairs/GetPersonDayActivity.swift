import Foundation
import PairQL
import TSCodable

struct GetPersonDayActivity: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let personId: Child.Id
    let range: DateRange
  }

  struct Output: PairOutput {
    let personName: String
    let items: [Item]
  }

  @TSCodable
  enum Item: PairNestable {
    case screenshot(Screenshot)
    case keylog(Keylog)
  }

  struct Screenshot: PairNestable {
    let id: Api.Screenshot.Id
    let ids: [Api.Screenshot.Id]
    let url: String
    let width: Int
    let height: Int
    let date: Date
    let flagged: Bool
    let duringSuspension: Bool
  }

  struct Keylog: PairNestable {
    let id: KeystrokeLine.Id
    let ids: [KeystrokeLine.Id]
    let text: String
    let appName: String
    let date: Date
    let flagged: Bool
    let duringSuspension: Bool
  }
}

// resolver

extension GetPersonDayActivity: Resolver {
  static func resolve(with input: Input, in context: AccountOwnerContext) async throws -> Output {
    let feed = try await UserActivityFeed.resolve(
      with: .init(userId: input.personId, range: input.range),
      in: context.legacyContext,
    )
    return Output(
      personName: feed.userName,
      items: feed.items.map { Item(from: $0, showSuspensionActivity: feed.showSuspensionActivity) },
    )
  }
}

// mappers

extension GetPersonDayActivity.Item {
  init(from item: UserActivity.Item, showSuspensionActivity: Bool) {
    switch item {
    case .screenshot(let screenshot):
      self = .screenshot(.init(
        id: screenshot.id,
        ids: screenshot.ids,
        url: screenshot.url,
        width: screenshot.width,
        height: screenshot.height,
        date: screenshot.createdAt,
        flagged: screenshot.flagged,
        duringSuspension: showSuspensionActivity && screenshot.duringSuspension,
      ))
    case .keystrokeLine(let keystroke):
      self = .keylog(.init(
        id: keystroke.id,
        ids: keystroke.ids,
        text: keystroke.line,
        appName: keystroke.appName,
        date: keystroke.createdAt,
        flagged: keystroke.flagged,
        duringSuspension: showSuspensionActivity && keystroke.duringSuspension,
      ))
    }
  }
}
