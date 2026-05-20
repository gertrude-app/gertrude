import Dependencies
import IOSRoute
import MacAppRoute
import PodcastRoute
import URLRouting
import Vapor
import VaporRouting

struct Context: ResolverContext {
  let requestId: String
  let dashboardUrl: String
  let ipAddress: String?
  let telemetry: TelemetryBag

  @Dependency(\.db) var db
  @Dependency(\.env) var env
}

enum PairQLRoute: Equatable, RouteResponder {
  case dashboard(DashboardRoute)
  case macApp(MacAppRoute)
  case superAdmin(SuperAdminRoute)
  case iOS(IOSRoute)
  case podcast(PodcastRoute)
  case admin(AdminRoute)
  case supervise(SuperviseRoute)

  nonisolated(unsafe) static let router = OneOf {
    Route(.case(PairQLRoute.macApp)) {
      Method("POST")
      Path { "macos-app" }
      MacAppRoute.router
    }
    Route(.case(PairQLRoute.iOS)) {
      Method("POST")
      Path { "ios-app" }
      IOSRoute.router
    }
    Route(.case(PairQLRoute.podcast)) {
      Method("POST")
      Path { "gertrude-am" }
      PodcastRoute.router
    }
    Route(.case(PairQLRoute.dashboard)) {
      Method("POST")
      Path { "dashboard" }
      DashboardRoute.router
    }
    Route(.case(PairQLRoute.superAdmin)) {
      Method("POST")
      Path { "super-admin" }
      SuperAdminRoute.router
    }
    Route(.case(PairQLRoute.admin)) {
      Method("POST")
      Path { "admin" }
      AdminRoute.router
    }
    Route(.case(PairQLRoute.supervise)) {
      Method("POST")
      Path { "supervise" }
      SuperviseRoute.router
    }
  }

  static func respond(to route: PairQLRoute, in context: Context) async throws -> Response {
    switch route {
    case .macApp(let appRoute):
      try await MacAppRoute.respond(to: appRoute, in: context)
    case .dashboard(let dashboardRoute):
      try await DashboardRoute.respond(to: dashboardRoute, in: context)
    case .superAdmin(let superAdminRoute):
      try await SuperAdminRoute.respond(to: superAdminRoute, in: context)
    case .iOS(let iosAppRoute):
      try await IOSRoute.respond(to: iosAppRoute, in: context)
    case .podcast(let podcastRoute):
      try await PodcastRoute.respond(to: podcastRoute, in: context)
    case .admin(let adminRoute):
      try await AdminRoute.respond(to: adminRoute, in: context)
    case .supervise(let superviseRoute):
      try await SuperviseRoute.respond(to: superviseRoute, in: context)
    }
  }

  @Sendable static func handler(_ req: Request) async throws -> Response {
    guard var requestData = URLRequestData(request: req),
          requestData.path.removeFirst() == "pairql" else {
      throw Abort(.badRequest)
    }

    if req.parameters.get("domain") == "super-admin",
       req.parameters.get("operation") == "QueryAdmins" {
      return Response(status: .notFound)
    }

    let ctx = Context(
      requestId: req.id,
      dashboardUrl: req.dashboardUrl,
      ipAddress: req.ipAddress,
      telemetry: TelemetryBag(),
    )

    let start = Date()
    do {
      let route = try PairQLRoute.router.parse(requestData)
      let output = try await PairQLRoute.respond(to: route, in: ctx)
      let duration = Date().timeIntervalSince(start)
      logOperation(route, req, duration)
      recordTelemetry(
        req,
        ctx,
        domain(of: route),
        start,
        .ok,
        numResponseBytes: output.body.count,
      )
      return addDashboardContractHeader(output, for: route)
    } catch {
      let domain = req.parameters.get("domain") ?? ""
      if "\(type(of: error))" == "ParsingError" {
        switch req.context.env.mode {
        case .prod:
          await slackPairQLRouteNotFound(req, error)
        case .dev:
          print("PairQL parsing \(error)")
        case .staging, .test:
          break
        }
        recordTelemetry(
          req,
          ctx,
          domain,
          start,
          .notFound,
          "0f5a25c9",
          "\(type(of: error))",
          parsingErrorSummary(req),
        )
        return addDashboardContractHeader(.init(PqlError(
          id: "0f5a25c9",
          requestId: ctx.requestId,
          type: .notFound,
          debugMessage: req.context.env.mode == .dev
            ? "PairQL routing \(error)"
            : "PairQL route not found",
          showContactSupport: true,
        )), forDomain: domain)
      } else if let pqlError = error as? PqlError {
        recordTelemetry(
          req,
          ctx,
          domain,
          start,
          .pqlError,
          pqlError.id,
          "PqlError",
          pqlError.debugMessage,
        )
        return addDashboardContractHeader(.init(pqlError), forDomain: domain)
      } else if let convertible = error as? PqlErrorConvertible {
        let pqlError = convertible.pqlError(in: ctx)
        recordTelemetry(
          req,
          ctx,
          domain,
          start,
          .convertibleError,
          pqlError.id,
          "\(type(of: error))",
          pqlError.debugMessage,
        )
        return addDashboardContractHeader(.init(pqlError), forDomain: domain)
      } else {
        print(type(of: error), error)
        recordTelemetry(
          req,
          ctx,
          domain,
          start,
          .unexpectedError,
          nil,
          "\(type(of: error))",
          "\(error)",
        )
        throw error
      }
    }
  }
}

// helpers

private func addDashboardContractHeader(_ response: Response, for route: PairQLRoute) -> Response {
  if case .dashboard = route {
    response.headers.replaceOrAdd(
      name: .xDashboardPairQLContract,
      value: DashboardTsCodegenRoute.currentContractHash,
    )
  }
  return response
}

private func addDashboardContractHeader(_ response: Response, forDomain domain: String) -> Response {
  if domain == "dashboard" {
    response.headers.replaceOrAdd(
      name: .xDashboardPairQLContract,
      value: DashboardTsCodegenRoute.currentContractHash,
    )
  }
  return response
}

private func logOperation(_ route: PairQLRoute, _ request: Request, _ duration: TimeInterval) {
  let operation = "\(request.parameters.get("operation") ?? "")".yellow
  var elapsed = ""
  switch duration {
  case 0.0 ..< 1.0:
    elapsed = "(\(Int(duration * 1000)) ms)".dim
  default:
    elapsed = "(\(String(format: "%.2f", duration)) sec)".red
  }
  switch route {
  case .macApp:
    request.logger
      .notice("PairQL request: \("MacApp".magenta) \(operation) \(elapsed)")
  case .dashboard:
    request.logger
      .notice("PairQL request: \("Dashboard".green) \(operation) \(elapsed)")
  case .superAdmin:
    request.logger
      .notice("PairQL request: \("SuperAdmin".cyan) \(operation) \(elapsed)")
  case .iOS:
    request.logger
      .notice("PairQL request: \("iOS".blue) \(operation) \(elapsed)")
  case .podcast:
    request.logger
      .notice("PairQL request: \("Podcast".yellow) \(operation) \(elapsed)")
  case .admin:
    request.logger
      .notice("PairQL request: \("Admin".red) \(operation) \(elapsed)")
  case .supervise:
    request.logger
      .notice("PairQL request: \("Supervise".magenta.bold) \(operation) \(elapsed)")
  }
}

private func recordTelemetry(
  _ request: Request,
  _ context: Context,
  _ domain: String,
  _ start: Date,
  _ result: RouteTelemetry.Result,
  _ errorId: String? = nil,
  _ errorType: String? = nil,
  _ errorMessage: String? = nil,
  numResponseBytes: Int? = nil,
) {
  let operation = request.parameters.get("operation") ?? ""
  let durationMs = Int(Date().timeIntervalSince(start) * 1000)
  let row = RouteTelemetry(
    kind: "pairql",
    requestId: context.requestId,
    domain: domain,
    operation: operation,
    durationMs: durationMs,
    result: result,
    errorId: errorId,
    errorType: errorType,
    errorMessage: errorMessage.map(truncateErrorMessage),
    parentId: context.telemetry.parentId,
    ipAddress: context.ipAddress,
    userAgent: request.headers.first(name: .userAgent).map(truncateUserAgent),
    numRequestBytes: request.body.data?.readableBytes,
    numResponseBytes: numResponseBytes,
  )
  Task {
    do {
      _ = try await context.db.create(row)
    } catch {
      print("route telemetry insert failed:", error)
    }
  }
}

private func truncateUserAgent(_ s: String) -> String {
  s.count <= 256 ? s : String(s.prefix(256))
}

private func truncateErrorMessage(_ s: String) -> String {
  s.count <= 2000 ? s : String(s.prefix(2000)) + "…"
}

private func parsingErrorSummary(_ req: Request) -> String {
  let domain = req.parameters.get("domain") ?? ""
  let operation = req.parameters.get("operation") ?? ""
  return "route not found: \(domain)/\(operation)"
}

private func domain(of route: PairQLRoute) -> String {
  switch route {
  case .macApp: "macos-app"
  case .iOS: "ios-app"
  case .podcast: "gertrude-am"
  case .dashboard: "dashboard"
  case .superAdmin: "super-admin"
  case .admin: "admin"
  case .supervise: "supervise"
  }
}

private func slackPairQLRouteNotFound(_ request: Request, _ error: Error) async {
  let domain = request.parameters.get("domain") ?? ""
  let operation = request.parameters.get("operation") ?? ""

  if domain == "dashboard", operation == "ChildActivitySummaries" {
    return
  }

  if domain == "dashboard", operation == "DashboardWidgets" {
    return
  }

  if domain == "dashboard", operation == "GetAccountOwner" {
    return
  }

  try? await with(dependency: \.slack).error("""
  *PairQL parsing error:*
  domain: `\(domain)`
  operation: `\(operation)`
  body:
  ```
  \(request.collectedBody() ?? "(nil)")
  ```
  headers:
  ```
  \(request.headers.debugDescription)
  ```
  error:
  ```
  \(error)
  ```
  """)
}
