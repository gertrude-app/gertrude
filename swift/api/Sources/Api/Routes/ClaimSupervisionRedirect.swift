import Dependencies
import DuetSQL
import Vapor

enum ClaimSupervisionRedirectRoute {
  @Sendable static func handler(_ request: Request) async throws -> Response {
    let signup = "\(request.env.dashboardUrl)/signup"

    guard let code = Int(request.parameters.get("code") ?? ""),
          code >= 100_000, code <= 999_999 else {
      return request.redirect(to: "\(signup)?error=invalid_code", redirectType: .temporary)
    }

    guard let device = try? await IOSApp.Device.query()
      .where(.supervisionClaimCode == code)
      .first(in: request.context.db) else {
      return request.redirect(to: "\(signup)?error=missing_code", redirectType: .temporary)
    }

    if device.childId == nil,
       let expiresAt = device.claimCodeExpiresAt,
       expiresAt <= get(dependency: \.date.now) {
      return request.redirect(to: "\(signup)?error=expired_code", redirectType: .temporary)
    }

    var components = URLComponents()
    components.queryItems = [
      .init(name: "claimPendingSupervision", value: "\(code)"),
      .init(name: "modelName", value: device.modelName),
      .init(name: "iosVersion", value: device.iosVersion),
      .init(name: "redirect", value: "/supervise-device/\(code)/claim"),
    ]
    return request.redirect(to: "\(signup)\(components.string ?? "")", redirectType: .temporary)
  }
}
