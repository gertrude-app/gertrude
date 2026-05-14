import Dependencies
import DuetSQL
import Tagged

extension BlockerApp {
  struct Token: Codable, Sendable {
    var id: Id
    var installId: BlockerApp.Install.Id
    var value: Value
    var createdAt = Date()
    var updatedAt = Date()

    init(id: Id = .init(), installId: BlockerApp.Install.Id, value: Value? = nil) {
      self.id = id
      self.installId = installId
      self.value = value ?? .init(get(dependency: \.uuid)())
    }
  }
}

// loaders

extension BlockerApp.Token {
  func install(in db: any DuetSQL.Client) async throws -> BlockerApp.Install {
    try await BlockerApp.Install.query()
      .where(.id == self.installId)
      .first(in: db)
  }

  static func connectedDeviceIds(
    among deviceIds: [IOSDevice.Id],
    in db: any DuetSQL.Client,
  ) async throws -> Set<IOSDevice.Id> {
    guard !deviceIds.isEmpty else { return [] }
    let rows = try await db.customQuery(
      ConnectedDeviceIdRow.self,
      withBindings: deviceIds.map { .uuid($0) },
    )
    return Set(rows.map(\.deviceId))
  }
}

private struct ConnectedDeviceIdRow: CustomQueryable {
  var deviceId: IOSDevice.Id

  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let iId = BlockerApp.Install.columnName(.id)
    let iDeviceId = BlockerApp.Install.columnName(.deviceId)
    let tInstallId = BlockerApp.Token.columnName(.installId)
    var stmt = SQL.Statement("""
    SELECT DISTINCT i.\(iDeviceId) AS device_id
    FROM \(table: BlockerApp.Install.self) i
    INNER JOIN \(table: BlockerApp.Token.self) t ON t.\(tInstallId) = i.\(iId)
    WHERE i.\(iDeviceId) IN (
    """)
    for (idx, binding) in bindings.enumerated() {
      if idx > 0 { stmt.components.append(.sql(", ")) }
      stmt.components.append(.binding(binding))
    }
    stmt.components.append(.sql(")"))
    return stmt
  }
}
