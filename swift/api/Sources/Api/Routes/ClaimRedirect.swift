import Dependencies
import DuetSQL
import Vapor

enum ClaimRedirectRoute {
  @Sendable static func handle(
    _ request: Request,
    intent urlIntent: ClaimIntent,
  ) async throws -> Response {
    let dashboardUrl = request.env.dashboardUrl

    guard let code = Int(request.parameters.get("code") ?? ""),
          code >= 100_000, code <= 999_999 else {
      return request.redirect(
        to: "\(dashboardUrl)/\(urlIntent.unauthedLandingRoute)?error=invalid_code",
        redirectType: .temporary,
      )
    }

    let claim = try await Claim.find(code: code, in: request.context.db)
    let intent = claim?.intent ?? urlIntent
    let landing = "\(dashboardUrl)/\(intent.unauthedLandingRoute)"

    guard let claim else {
      return request.redirect(to: "\(landing)?error=missing_code", redirectType: .temporary)
    }
    let device = try await claim.device(in: request.context.db)

    if device.childId == nil,
       claim.expiresAt <= get(dependency: \.date.now) {
      return request.redirect(to: "\(landing)?error=expired_code", redirectType: .temporary)
    }

    var components = URLComponents()
    components.queryItems = [
      .init(name: intent.claimPendingQueryKey, value: "\(code)"),
      .init(name: "modelName", value: device.modelName),
      .init(name: "iosVersion", value: device.iosVersion),
      .init(name: "redirect", value: intent.claimFunnelPath(code: code)),
    ]
    return request.redirect(
      to: "\(landing)\(components.string ?? "")",
      redirectType: .temporary,
    )
  }
}
