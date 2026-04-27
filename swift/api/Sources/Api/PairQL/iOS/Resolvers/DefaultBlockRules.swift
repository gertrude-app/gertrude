import Dependencies
import DuetSQL
import Gertie
import GertieIOS
import IOSRoute

extension DefaultBlockRules: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let deviceId: IOSApp.Device.Id? = input.vendorId
      .flatMap { $0 == .init(.zero) ? nil : .init($0) }
    let (_, optInExclusions) = try await optInBlockGroupExclusions(deviceId, in: context.db)
    return try await IOSApp.BlockRule.query()
      .where(.groupId != nil .&& .groupId |!=| optInExclusions)
      .all(in: context.db)
      .map(\.rule)
      .frozenEncodable
      .map(\.legacy)
  }
}
