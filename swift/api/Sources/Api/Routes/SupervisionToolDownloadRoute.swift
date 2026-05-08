import Dependencies
import DuetSQL
import Vapor

enum SupervisionToolDownloadRoute {
  @Sendable static func handler(_ request: Request) async throws -> Response {
    guard let code = Int(request.parameters.get("code") ?? ""),
          code >= 100_000, code <= 999_999 else {
      throw Abort(.badRequest, reason: "Invalid claim code")
    }

    guard let platformParam = request.parameters.get("platform"),
          let platform = Platform(rawValue: platformParam) else {
      throw Abort(.badRequest, reason: "Invalid platform (must be 'mac' or 'windows')")
    }

    guard let supervision = try? await BlockerApp.Supervision.query()
      .where(.claimCode == code)
      .first(in: request.context.db) else {
      throw Abort(.notFound, reason: "Device not found for claim code")
    }

    let device = try await supervision.device(in: request.context.db)
    guard let child = try await device.child(in: request.context.db) else {
      throw Abort(.badRequest, reason: "Device not claimed")
    }
    let parent = try await child.parent(in: request.context.db)
    let plan = try await parent.plan(in: request.context.db)
    guard plan.allowsSupervision else {
      throw Abort(.paymentRequired, reason: "Subscription required")
    }

    let task = Task {
      try await request.context.db.create(IOSEvent(
        eventId: "7d644b4d",
        kind: .supervision,
        detail: "supervision_tool_download: platform=\(platform.rawValue)",
        deviceId: device.id,
        modelIdentifier: device.modelIdentifier,
        iosVersion: device.iosVersion,
      ))
      await get(dependency: \.slack)
        .internal(
          .info,
          "*iOS supervision:* tool downloaded (\(platform.rawValue)), code `\(code)`",
        )
    }

    if request.context.env.mode == .test {
      _ = try await task.value
    }

    // we experienced caching issues at least on windows machines
    let cacheBust = Int(Date().timeIntervalSince1970)
    return request.redirect(to: "\(platform.downloadUrl)?t=\(cacheBust)", redirectType: .temporary)
  }

  enum Platform: String {
    case mac
    case windows

    var downloadUrl: String {
      switch self {
      case .mac:
        "https://gertrude.nyc3.digitaloceanspaces.com/releases/supervision/GertrudeSupervisor.zip"
      case .windows:
        "https://gertrude.nyc3.digitaloceanspaces.com/releases/supervision/GertrudeSupervisor.exe"
      }
    }
  }
}
