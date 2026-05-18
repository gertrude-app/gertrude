import Dependencies
import Vapor

struct ResetCommand: AsyncCommand {
  struct Signature: CommandSignature {}
  var help: String { "Reset staging data" }

  func run(using context: CommandContext, signature: Signature) async throws {
    guard get(dependency: \.env).mode != .prod else {
      fatalError("`reset` is only allowed in non-prod environments")
    }
    try await Reset.run()
    try await SyncStagingDataCommand().run(using: context, signature: .init())

    @Dependency(\.db) var db
    let ben: Parent = try await db.find(AdminBen.Ids.ben)
    let bella: Parent = try await db.find(AdminBella.Ids.bella)
    let bruno: Parent = try await db.find(AdminBruno.Ids.bruno)
    let blanca: Parent = try await db.find(AdminBlanca.Ids.blanca)
    let bart: Parent = try await db.find(AdminBart.Ids.bart)

    print("")
    print("Login emails (Stripe-sandbox canonical billing states):")
    print("  Light — paid          \(ben.email)")
    print("  Full — paid           \(bella.email)")
    print("  Full — trialing       \(bruno.email)")
    print("  Free — lapsed Light   \(blanca.email)")
    print("  Free — lapsed Full    \(bart.email)")
    print("")
  }
}

enum ResetRoute {
  @Sendable static func handler(_ request: Request) async throws -> Response {
    guard request.env.mode != .prod else {
      throw Abort(.notFound)
    }

    try await Reset.run()
    try await SyncStagingDataCommand()
      .exec()
      .mapError { Abort(.internalServerError, reason: $0.message) }
      .get()

    let betsy = try await request.context.db.find(AdminBetsy.Ids.betsy)
    let ben: Parent = try await request.context.db.find(AdminBen.Ids.ben)
    let bella: Parent = try await request.context.db.find(AdminBella.Ids.bella)
    let bruno: Parent = try await request.context.db.find(AdminBruno.Ids.bruno)
    let blanca: Parent = try await request.context.db.find(AdminBlanca.Ids.blanca)
    let bart: Parent = try await request.context.db.find(AdminBart.Ids.bart)
    let dashUrl = request.env.dashboardUrl
    let jimmysId = AdminBetsy.Ids.jimmysId
    let filterReqId = AdminBetsy.Ids.suspendFilter.lowercased

    func row(_ state: String, _ parent: Parent) -> String {
      """
      <tr>
        <td style="padding: 0.25em 1em;">\(state)</td>
        <td style="padding: 0.25em 1em;"><code>\(parent.email)</code></td>
        <td style="padding: 0.25em 1em;"><code>\(parent.id.lowercased)</code></td>
      </tr>
      """
    }

    return .init(
      status: .ok,
      headers: ["Content-Type": "text/html"],
      body: .init(string: """
        <html><body><head><title>&#129532; DB Reset</title></head>
        <style>
          html { padding: 0.5em; }
          code { color: rebeccapurple; font-size: 1.2em;}
        </style>
        <h2>Reset complete</h2>
        <h3>Betsy (Mac-focused)</h3>
        <p>
          To auto login as "Betsy" set this <code>.env</code> variable
           in <code>./dashboard/.env</code>
        </p>
        <pre style="background: #eaeaea; padding: 1em 1em 0 1em;">
        VITE_ADMIN_CREDS=\(betsy.id.lowercased):\(betsy.id.lowercased)
        </pre>
        <p>
          ...or use her email address:
           <code>\(betsy.email)</code>
        </p>
        <p>
          To test a filter suspension, use
          <a href ="\(dashUrl)/children/\(jimmysId)/suspend-filter-requests/\(filterReqId)">
          this route</a> in the dashboard web app:<br />
        </p>
        <hr />
        <h3>Ben (iOS-only, one child: Luke)</h3>
        <p>
          To auto login as "Ben" set this <code>.env</code> variable
           in <code>./dashboard/.env</code>
        </p>
        <pre style="background: #eaeaea; padding: 1em 1em 0 1em;">
        VITE_ADMIN_CREDS=\(ben.id.lowercased):\(ben.id.lowercased)
        </pre>
        <p>
          ...or use his email address:
           <code>\(ben.email)</code>
        </p>
        <hr />
        <h3>Billing-state fixtures</h3>
        <p>
          Canonical Stripe sandbox states for testing the subscription panel. Each row's
          <code>VITE_ADMIN_CREDS</code> uses <code>parent_id:parent_id</code> just like
          Betsy/Ben.
        </p>
        <table style="border-collapse: collapse; margin-bottom: 1em;">
          <thead>
            <tr style="background: #eaeaea;">
              <th style="padding: 0.25em 1em; text-align: left;">State</th>
              <th style="padding: 0.25em 1em; text-align: left;">Email</th>
              <th style="padding: 0.25em 1em; text-align: left;">Parent ID</th>
            </tr>
          </thead>
          <tbody>
            \(row("Light — paid", ben))
            \(row("Full — paid", bella))
            \(row("Full — trialing", bruno))
            \(row("Free — lapsed Light", blanca))
            \(row("Free — lapsed Full", bart))
          </tbody>
        </table>
        </body></html>
      """),
    )
  }
}
