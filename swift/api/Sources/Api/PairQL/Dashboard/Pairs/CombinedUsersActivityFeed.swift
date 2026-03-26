import DuetSQL
import PairQL
import Vapor

struct CombinedUsersActivityFeed: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var range: DateRange
  }

  struct UserDay: PairOutput {
    var userName: String
    var showSuspensionActivity: Bool
    var numDeleted: Int
    var items: [UserActivity.Item]
  }

  typealias Output = [UserDay]
}

// resolver

extension CombinedUsersActivityFeed: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    guard let (after, before) = input.range.dates else {
      throw Abort(.badRequest)
    }

    let children = try await context.children()

    return try await children.concurrentMap { child in
      let computerUserIds = try await child.computerUsers(in: context.db).map(\.id)

      async let keystrokes = KeystrokeLine.query()
        .where(.computerUserId |=| computerUserIds)
        .where(.createdAt <= .date(before))
        .where(.createdAt > .date(after))
        .orderBy(.createdAt, .desc)
        .withSoftDeleted()
        .all(in: context.db)

      async let screenshots = Screenshot.query()
        .where(.computerUserId |=| computerUserIds)
        .where(.createdAt <= .date(before))
        .where(.createdAt > .date(after))
        .orderBy(.createdAt, .desc)
        .withSoftDeleted()
        .all(in: context.db)

      let coalesced = try await coalesce(screenshots, keystrokes)
      let aws = with(dependency: \.aws)
      let bucketUrl = with(dependency: \.env.s3.bucketUrl)
      let signedItems = coalesced.map { item -> UserActivity.Item in
        guard case .screenshot(let s) = item else { return item }
        var signed = s
        signed.url = signedScreenshotUrl(s.url, bucketUrl: bucketUrl, aws: aws)
        return .screenshot(signed)
      }

      return UserDay(
        userName: child.name,
        showSuspensionActivity: child.showSuspensionActivity,
        numDeleted: signedItems.lazy.filter(\.isDeleted).count,
        items: signedItems.lazy.filter(\.notDeleted),
      )
    }
  }
}

extension DateRange {
  var dates: (Date, Date)? {
    guard let start = try? Date(fromIsoString: start),
          let end = try? Date(fromIsoString: end) else {
      return nil
    }
    return (start, end)
  }
}
