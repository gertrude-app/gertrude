import DuetSQL
import Foundation
import Gertie
import PairQL

struct GetSuspendFilterRequest: Pair {
  static let auth: ClientAuth = .parent
  typealias Input = MacApp.SuspendFilterRequest.Id

  struct Output: PairOutput {
    var id: MacApp.SuspendFilterRequest.Id
    var deviceId: Api.ComputerUser.Id
    var status: RequestStatus
    var userName: String
    var deviceName: String?
    var requestedDurationInSeconds: Int
    var requestComment: String?
    var responseComment: String?
    var extraMonitoringOptions: [String: String]
    var createdAt: Date
  }
}

// resolver

extension GetSuspendFilterRequest: Resolver {
  static func resolve(with id: Input, in context: ParentContext) async throws -> Output {
    let request = try await context.db.find(id)
    let userDevice = try await request.computerUser(in: context.db)
    let user = try await context.verifiedChild(from: userDevice.childId)
    var extraMonitoringOptions: [String: String] = [:]
    if Semver(userDevice.appVersion)! >= .init("2.1.0")! {
      extraMonitoringOptions = user.extraMonitoringOptions.mapKeys(\.magicString)
    }
    return try await Output(
      id: id,
      deviceId: userDevice.id,
      status: request.status,
      userName: user.name,
      deviceName: disambiguatingDeviceName(for: userDevice, in: context),
      requestedDurationInSeconds: request.duration.rawValue,
      requestComment: request.requestComment,
      responseComment: request.responseComment,
      extraMonitoringOptions: extraMonitoringOptions,
      createdAt: request.createdAt,
    )
  }
}

private func disambiguatingDeviceName(
  for userDevice: ComputerUser,
  in context: ParentContext,
) async throws -> String? {
  let childComputerUsers = try await ComputerUser.query()
    .where(.childId == userDevice.childId)
    .all(in: context.db)
  guard Set(childComputerUsers.map(\.computerId)).count > 1 else { return nil }
  let computer = try await userDevice.computer(in: context.db)
  return computer.customName ?? computer.model.shortDescription
}
