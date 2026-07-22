import DuetSQL
import Vapor

enum AppIconRoute {
  @Sendable static func handler(_ req: Request) async throws -> Response {
    guard let hash = req.parameters.get("hash"), !hash.isEmpty else {
      throw Abort(.badRequest)
    }

    let app: CatalogedApp?
    do {
      app = try await CatalogedApp.query()
        .where(.iconContentHash == hash)
        .first(in: req.context.db)
    } catch DuetSQLError.notFound {
      app = nil
    }

    guard let iconData = app?.icon else {
      throw Abort(.notFound)
    }

    return Response(
      status: .ok,
      headers: [
        "Content-Type": "image/png",
        "Cache-Control": "public, max-age=31536000, immutable",
      ],
      body: .init(data: iconData),
    )
  }
}
