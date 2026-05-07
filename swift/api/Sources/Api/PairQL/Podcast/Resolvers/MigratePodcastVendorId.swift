import DuetSQL
import Foundation
import PodcastRoute

extension MigratePodcastVendorId: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let deviceId = PodcastEvent.columnName(.deviceId)
    var stmt = SQL.Statement("UPDATE \(table: PodcastEvent.self) SET \(deviceId) = ")
    stmt.components.append(.binding(.uuid(input.newVendorId)))
    stmt.components.append(.sql(" WHERE \(deviceId) = "))
    stmt.components.append(.binding(.uuid(input.oldDeviceId)))
    try await context.db.execute(statement: stmt)

    Task {
      if context.env.mode == .prod,
         await (try? context.db.find(IOSDevice.Id(rawValue: input.newVendorId))) != nil {
        await get(dependency: \.slack).internal(
          .info,
          "Podcast migration cross-correlated with iOS app device `\(input.newVendorId)`",
        )
      }
    }

    return .success
  }
}
