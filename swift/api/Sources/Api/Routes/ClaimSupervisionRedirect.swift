import Dependencies
import DuetSQL
import Vapor

enum ClaimSupervisionRedirectRoute {
  @Sendable static func handler(_ request: Request) async throws -> Response {
    let login = "\(request.env.dashboardUrl)/login"

    guard let code = Int(request.parameters.get("code") ?? ""),
          code >= 100_000, code <= 999_999 else {
      return request.redirect(to: "\(login)?error=invalid_code", redirectType: .temporary)
    }

    guard let pendingSupervision = try? await IOSApp.PendingSupervision.query()
      .where(.code == code)
      .first(in: request.context.db) else {
      return request.redirect(to: "\(login)?error=missing_code", redirectType: .temporary)
    }

    if pendingSupervision.claimedChildId == nil,
       pendingSupervision.expiresAt <= get(dependency: \.date.now) {
      return request.redirect(to: "\(login)?error=expired_code", redirectType: .temporary)
    }

    var components = URLComponents()
    components.queryItems = [
      .init(name: "claimPendingSupervision", value: "\(code)"),
      .init(name: "modelName", value: pendingSupervision.modelName),
      .init(name: "iosVersion", value: pendingSupervision.iosVersion),
    ]
    return request.redirect(to: "\(login)\(components.string ?? "")", redirectType: .temporary)
  }
}
