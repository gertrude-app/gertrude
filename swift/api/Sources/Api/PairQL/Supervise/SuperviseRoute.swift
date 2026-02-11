import PairQL
import Vapor

enum SuperviseRoute: PairRoute {
  case getPendingSupervision(GetPendingSupervision.Input)
  case logSupervisionEvent(LogSupervisionEvent.Input)
  case recordDeviceUSBConnection(RecordDeviceUSBConnection.Input)
  case markSupervisionVerified(MarkSupervisionVerified.Input)
  case reportSupervisionFailed(ReportSupervisionFailed.Input)

  nonisolated(unsafe) static let router = OneOf {
    Route(.case(Self.getPendingSupervision)) {
      Operation(GetPendingSupervision.self)
      Body(.json(GetPendingSupervision.Input.self))
    }
    Route(.case(Self.logSupervisionEvent)) {
      Operation(LogSupervisionEvent.self)
      Body(.json(LogSupervisionEvent.Input.self))
    }
    Route(.case(Self.recordDeviceUSBConnection)) {
      Operation(RecordDeviceUSBConnection.self)
      Body(.json(RecordDeviceUSBConnection.Input.self))
    }
    Route(.case(Self.markSupervisionVerified)) {
      Operation(MarkSupervisionVerified.self)
      Body(.json(MarkSupervisionVerified.Input.self))
    }
    Route(.case(Self.reportSupervisionFailed)) {
      Operation(ReportSupervisionFailed.self)
      Body(.json(ReportSupervisionFailed.Input.self))
    }
  }
}

extension SuperviseRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .getPendingSupervision(let input):
      let output = try await GetPendingSupervision.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .logSupervisionEvent(let input):
      let output = try await LogSupervisionEvent.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .recordDeviceUSBConnection(let input):
      let output = try await RecordDeviceUSBConnection.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .markSupervisionVerified(let input):
      let output = try await MarkSupervisionVerified.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .reportSupervisionFailed(let input):
      let output = try await ReportSupervisionFailed.resolve(with: input, in: context)
      return try await self.respond(with: output)
    }
  }
}
