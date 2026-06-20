import Dependencies
import DuetSQL
import FluentKit
import Foundation
import PostgresKit
import Vapor

public struct ScrubDbCommand: AsyncCommand {
  public struct Signature: CommandSignature {
    public init() {}
  }

  public init() {}
  public var help: String { "Scrub PII from a freshly-loaded copy of the prod DB." }

  public func run(using context: CommandContext, signature: Signature) async throws {
    @Dependency(\.db) var db
    @Dependency(\.env) var env

    let dbName = env.database.name
    guard dbName.hasSuffix("_scrub_staging") else {
      throw Abort(
        .internalServerError,
        reason: "scrub-db: refusing to run — connected to '\(dbName)', expected DB name ending in '_scrub_staging'",
      )
    }

    guard let pg = db as? PgClient else {
      throw Abort(.internalServerError, reason: "scrub-db: requires PgClient")
    }

    context.console.print("[scrub-db] target: \(dbName)")
    try await scrubTokens(pg: pg, console: context.console)
    try await scrubKeystrokeLines(pg: pg, console: context.console)
    try await scrubScreenshots(pg: pg, console: context.console)
    try await scrubParentPasswords(pg: pg, console: context.console)
    try await scrubNotificationMethods(db: db, console: context.console)
    context.console.print("[scrub-db] done")
  }
}

private func scrubTokens(pg: PgClient, console: Console) async throws {
  try await pg.db.execute("""
    UPDATE \(table: MacAppToken.self)
    SET \(col: MacAppToken.columnName(.value)) = gen_random_uuid()
  """)
  try await pg.db.execute("""
    UPDATE \(table: BlockerApp.Token.self)
    SET \(col: BlockerApp.Token.columnName(.value)) = gen_random_uuid()
  """)
  try await pg.db.execute("""
    UPDATE \(table: Parent.DashToken.self)
    SET \(col: Parent.DashToken.columnName(.value)) = gen_random_uuid()
  """)
  try await pg.db.execute("""
    UPDATE \(table: SuperAdminToken.self)
    SET \(col: SuperAdminToken.columnName(.value)) = gen_random_uuid()
  """)
  try await pg.db.execute("""
    UPDATE \(table: PodcastApp.Token.self)
    SET \(col: PodcastApp.Token.columnName(.value)) = gen_random_uuid()
  """)
  try await pg.db.execute("""
    UPDATE \(table: MusicApp.Token.self)
    SET \(col: MusicApp.Token.columnName(.value)) = gen_random_uuid()
  """)
  console.print("[scrub-db] 6 token tables → gen_random_uuid()")
}

private func scrubKeystrokeLines(pg: PgClient, console: Console) async throws {
  let line = KeystrokeLine.columnName(.line)
  try await pg.db.execute("""
    UPDATE \(table: KeystrokeLine.self)
    SET \(col: line) = '[redacted ' || LENGTH(\(col: line)) || ' characters]'
  """)
  console.print("[scrub-db] keystroke_lines.line → [redacted N characters]")
}

private func scrubScreenshots(pg: PgClient, console: Console) async throws {
  let placeholder = "https://gertrude-web-assets.nyc3.digitaloceanspaces.com/placeholders-imgs/800x600.png"
  try await pg.db.execute("""
    UPDATE \(table: Screenshot.self)
    SET \(col: Screenshot.columnName(.url)) = '\(escaping: placeholder)',
        \(col: Screenshot.columnName(.width)) = 800,
        \(col: Screenshot.columnName(.height)) = 600
  """)
  console.print("[scrub-db] screenshots.url → placeholder, width/height → 800x600")
}

private func scrubParentPasswords(pg: PgClient, console: Console) async throws {
  let hash = try Bcrypt.hash("good")
  try await pg.db.execute("""
    UPDATE \(table: Parent.self)
    SET \(col: Parent.columnName(.password)) = '\(escaping: hash)'
  """)
  console.print("[scrub-db] parents.password → bcrypt('good')")
}

private func scrubNotificationMethods(db: any DuetSQL.Client, console: Console) async throws {
  let methods = try await db.select(all: Parent.NotificationMethod.self)
  for var method in methods {
    method.config = scrubbedConfig(method.config, rowId: method.id.rawValue)
    try await db.update(method)
  }
  console.print("[scrub-db] notification_methods.config → \(methods.count) rows")
}

private func scrubbedConfig(
  _ config: Parent.NotificationMethod.Config,
  rowId: UUID,
) -> Parent.NotificationMethod.Config {
  let suffix = rowId.uuidString.prefix(8).lowercased()
  switch config {
  case .slack(let channelId, let channelName, _):
    return .slack(
      channelId: channelId,
      channelName: channelName,
      token: "xoxb-scrubbed-\(suffix)",
    )
  case .email:
    return .email(email: "d\(suffix)@notreal.com")
  case .text:
    let digits = suffix.compactMap { c -> Character? in
      guard let v = Int(String(c), radix: 16) else { return nil }
      return Character("\(v % 10)")
    }
    let local = String(digits.prefix(7))
    return .text(phoneNumber: "+1555\(local)")
  case .ntfy:
    return .ntfy(topic: "scrubbed-\(suffix)")
  }
}
