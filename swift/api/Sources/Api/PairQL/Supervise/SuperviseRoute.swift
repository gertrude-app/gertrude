import PairQL
import Vapor

enum SuperviseRoute: PairRoute {
  case getPendingSupervision(GetPendingSupervision.Input)
  case recordDeviceConnection(RecordDeviceConnection.Input)
  case markSupervisionVerified(MarkSupervisionVerified.Input)
  case reportSupervisionFailed(ReportSupervisionFailed.Input)

  nonisolated(unsafe) static let router = OneOf {
    Route(.case(Self.getPendingSupervision)) {
      Operation(GetPendingSupervision.self)
      Body(.json(GetPendingSupervision.Input.self))
    }
    Route(.case(Self.recordDeviceConnection)) {
      Operation(RecordDeviceConnection.self)
      Body(.json(RecordDeviceConnection.Input.self))
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
    case .recordDeviceConnection(let input):
      let output = try await RecordDeviceConnection.resolve(with: input, in: context)
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
