import DuetSQL
import Vapor

enum ShortUrlRedirectRoute {
  @Sendable static func handler(_ request: Request) async throws -> Response {
    let dashboardFallback = "\(request.env.dashboardUrl)/link-expired"
    guard let shortId = request.parameters.get("shortId"),
          !shortId.isEmpty else {
      slackErr("Short URL redirect missing shortId parameter")
      return request.redirect(to: dashboardFallback, redirectType: .temporary)
    }

    guard let shortUrl = try? await ShortUrl.query()
      .where(.shortId == shortId)
      .first(in: request.context.db) else {
      // not really an "error" but should't happen often, want to keep an eye
      slackErr("Short URL redirect not found/expired: `\(shortId)`")
      return request.redirect(to: dashboardFallback, redirectType: .temporary)
    }

    Task {
      do {
        var updated = shortUrl
        updated.clickCount += 1
        try await get(dependency: \.db).update(updated)
      } catch {
        await get(dependency: \.slack)
          .error("*short url fail* ad34c4fa `\(shortId)`: \(error)")
      }
    }

    return request.redirect(to: shortUrl.target, redirectType: .temporary)
  }
}
