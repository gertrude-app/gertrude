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

    guard let device = try? await IOSApp.Device.query()
      .where(.supervisionClaimCode == code)
      .first(in: request.context.db) else {
      return request.redirect(to: "\(login)?error=missing_code", redirectType: .temporary)
    }

    if device.childId == nil,
       let expiresAt = device.claimCodeExpiresAt,
       expiresAt <= get(dependency: \.date.now) {
      return request.redirect(to: "\(login)?error=expired_code", redirectType: .temporary)
    }

    var components = URLComponents()
    components.queryItems = [
      .init(name: "claimPendingSupervision", value: "\(code)"),
      .init(name: "modelName", value: device.modelName),
      .init(name: "iosVersion", value: device.iosVersion),
    ]
    return request.redirect(to: "\(login)\(components.string ?? "")", redirectType: .temporary)
  }
}
