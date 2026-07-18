import Duet
import PostgresKit

public extension SQL {
  struct Statement: Equatable, Sendable {
    public enum Component: Equatable, Sendable {
      case sql(String)
      case binding(Postgres.Data)
    }

    public var first: String
    public var components: [Component] = []

    public init(_ first: String) {
      self.first = first
    }
  }
}

public extension SQL.Statement {
  internal static func update<M: Model>(_ model: M) -> SQL.Statement {
    var stmt = SQL.Statement("UPDATE \(table: M.self)\nSET ")
    let values = model.insertValues.mapKeys { M.columnName($0) }
    for (column, value) in values {
      if column == "id" || column == "created_at" {
        continue
      } else if column == "updated_at" {
        stmt.components.append(.sql("\"\(column)\" = "))
        stmt.components.append(.binding(.currentTimestamp))
        stmt.components.append(.sql(", "))
      } else {
        stmt.components.append(.sql("\"\(column)\" = "))
        stmt.components.append(.binding(value))
        stmt.components.append(.sql(", "))
      }
    }
    stmt.components.removeLast()
    stmt.components.append(.sql("\nWHERE "))
    stmt.components.append(contentsOf: SQL.WhereConstraint<M>.equals(.id, .id(model)).sql!)
    stmt.components.append(.sql("\nRETURNING *"))
    return stmt
  }

  internal static func create(_ models: [some Model]) -> SQL.Statement {
    self.insert(models, as: nil)
  }

  internal static func create<M: Model>(
    _ models: [M],
    onConflict targets: [M.ColumnName],
    do action: SQL.ConflictAction<M>,
    returning: SQL.Returning<M> = .none,
  ) throws -> SQL.Statement {
    let targetList = try self.conflictTargetSQL(targets, M.self)
    let assignments: String
    switch action {
    case .update(let columns):
      assignments = columns
        .map { "\"\(M.columnName($0))\" = EXCLUDED.\"\(M.columnName($0))\"" }
        .list
    case .updateAllExcept(let except):
      let excluded = Set(except.map { M.columnName($0) }).union(["id", "created_at"])
      assignments = models[0].insertValues.keys
        .map { M.columnName($0) }
        .filter { !excluded.contains($0) }
        .sorted()
        .map { "\"\($0)\" = EXCLUDED.\"\($0)\"" }
        .list
    case .updateRaw(let build):
      assignments = build(SQL.ConflictColumns(alias: "existing"))
    }
    guard !assignments.isEmpty else {
      throw DuetSQLError.emptyConflictUpdate
    }
    var stmt = self.insert(models, as: action.aliasesTarget ? "existing" : nil)
    stmt.components.append(.sql("\nON CONFLICT (\(targetList)) DO UPDATE SET \(assignments)"))
    if let clause = self.returningClause(returning) {
      stmt.components.append(.sql("\n\(clause)"))
    }
    return stmt
  }

  internal static func create<M: Model>(
    _ models: [M],
    ignoringConflictOn targets: [M.ColumnName],
    returning: SQL.Returning<M> = .none,
  ) throws -> SQL.Statement {
    let targetList = try self.conflictTargetSQL(targets, M.self)
    var stmt = self.insert(models, as: nil)
    stmt.components.append(.sql("\nON CONFLICT (\(targetList)) DO NOTHING"))
    if let clause = self.returningClause(returning) {
      stmt.components.append(.sql("\n\(clause)"))
    }
    return stmt
  }

  private static func returningClause<M: Model>(_ returning: SQL.Returning<M>) -> String? {
    switch returning {
    case .none:
      nil
    case .all:
      "RETURNING *"
    case .columns(let columns) where columns.isEmpty:
      nil
    case .columns(let columns):
      "RETURNING \(columns.map { "\"\(M.columnName($0))\"" }.list)"
    }
  }

  private static func conflictTargetSQL<M: Model>(
    _ targets: [M.ColumnName],
    _: M.Type,
  ) throws -> String {
    guard !targets.isEmpty else {
      throw DuetSQLError.emptyConflictTarget
    }
    return targets.map { "\"\(M.columnName($0))\"" }.list
  }

  private static func insert<M: Model>(_ models: [M], as alias: String?) -> SQL.Statement {
    let first = models[0]
    let insert = first.insertValues
    let sorted = insert.keys.map { ($0, M.columnName($0)) }.sorted { $0.1 < $1.1 }
    let colList: String = sorted.map(\.1).quotedList
    let columns: [M.ColumnName] = sorted.map(\.0)
    let aliasClause = alias.map { " AS \($0)" } ?? ""
    var stmt = SQL.Statement("INSERT INTO \(table: M.self)\(aliasClause)\n(\(colList))\nVALUES\n")
    for model in models {
      stmt.components.append(.sql("("))
      for column in columns {
        let value = model.insertValues[column]!
        stmt.components.append(.binding(value))
        stmt.components.append(.sql(", "))
      }
      stmt.components.removeLast()
      stmt.components.append(.sql(")"))
      stmt.components.append(.sql(", "))
    }
    stmt.components.removeLast()
    return stmt
  }

  internal static func select<M: Model>(
    _: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    orderBy order: SQL.Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil,
  ) -> SQL.Statement {
    .query(
      "SELECT * FROM",
      M.self,
      where: constraint,
      orderBy: order,
      limit: limit,
      offset: offset,
    )
  }

  internal static func delete<M: Model>(
    _ Model: M.Type,
    where constraint: SQL.WhereConstraint<M>,
    orderBy order: SQL.Order<M>?,
    limit: Int?,
    offset: Int?,
  ) -> SQL.Statement {
    var stmt = SQL.Statement.query(
      "DELETE FROM",
      M.self,
      where: constraint,
      orderBy: order,
      limit: limit,
      offset: offset,
    )
    stmt.components.append(.sql("\nRETURNING id"))
    return stmt
  }

  internal static func softDelete<M: Model>(
    _ Model: M.Type,
    where constraint: SQL.WhereConstraint<M>,
    orderBy order: SQL.Order<M>?,
    limit: Int?,
    offset: Int?,
  ) -> SQL.Statement {
    .query(
      initial: "UPDATE \(table: M.self)\nSET \"deleted_at\" = CURRENT_TIMESTAMP",
      M.self,
      where: constraint,
      orderBy: order,
      limit: limit,
      offset: offset,
    )
  }

  internal static func count<M: Model>(
    _: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
  ) -> SQL.Statement {
    .query("SELECT COUNT(*) FROM", M.self, where: constraint)
  }

  private static func query<M: Model>(
    _ query: String,
    _: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    orderBy order: SQL.Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil,
  ) -> SQL.Statement {
    .query(
      initial: "\(query) \(table: M.self)",
      M.self,
      where: constraint,
      orderBy: order,
      limit: limit,
      offset: offset,
    )
  }

  private static func query<M: Model>(
    initial query: String,
    _: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    orderBy order: SQL.Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil,
  ) -> SQL.Statement {
    var stmt = SQL.Statement(query)
    if let whereSql = constraint.sql {
      stmt.components.append(.sql("\nWHERE "))
      stmt.components.append(contentsOf: whereSql)
    }
    if let order {
      stmt.components.append(.sql(
        "\nORDER BY \"\(M.columnName(order.column))\" \(order.direction.rawValue.uppercased())",
      ))
    }
    if let limit {
      stmt.components.append(.sql("\nLIMIT \(limit)"))
    }
    if let offset {
      stmt.components.append(.sql("\nOFFSET \(offset)"))
    }
    return stmt
  }

  var sql: SQLQueryString {
    var sql = SQLQueryString(stringLiteral: self.first)
    for component in self.components {
      switch component {
      case .sql(let fragment):
        sql += SQLQueryString(stringLiteral: fragment)
      case .binding(.date(.some(let date))):
        sql.appendInterpolation(expression: .date(date))
      case .binding(.date(.none)):
        sql.appendInterpolation(expression: .null)
      case .binding(.uuid(.some(let uuid))):
        sql.appendInterpolation(expression: .uuid(uuid.uuidString))
      case .binding(.uuid(.none)):
        sql.appendInterpolation(expression: .null)
      case .binding(.currentTimestamp):
        sql.appendInterpolation(expression: .currentTimestamp)
      case .binding(.id(let id)):
        sql.appendInterpolation(expression: .uuid(id.uuidId.uuidString))
      case .binding(.json(.some(let json))):
        sql.appendInterpolation(bind: json)
        sql += SQLQueryString(stringLiteral: "::jsonb")
      case .binding(.json(.none)):
        sql.appendInterpolation(expression: .null)
      case .binding(.bytea(.some(let data))):
        sql.appendInterpolation(expression: .bytea(data.base64EncodedString()))
      case .binding(.bytea(.none)):
        sql.appendInterpolation(expression: .null)
      case .binding(.null):
        sql.appendInterpolation(expression: .null)
      case .binding(let data):
        sql.appendInterpolation(bind: data.binding)
      }
    }
    return sql
  }

  /// NB: these are only for asserting in tests
  #if DEBUG
    var prepared: String {
      var bindNum = 1
      return self.first + components.map {
        switch $0 {
        case .sql(let sql):
          return sql
        case .binding:
          defer { bindNum += 1 }
          return "$\(bindNum)"
        }
      }.joined(separator: "")
    }

    var params: [Postgres.Data] {
      components.compactMap {
        switch $0 {
        case .sql:
          nil
        case .binding(let data):
          data
        }
      }
    }
  #endif
}

extension SQL {
  enum Returning<M: Model> {
    case none
    case all
    case columns([M.ColumnName])
  }
}

public extension SQL {
  enum ConflictAction<M: Model> {
    case update(set: [M.ColumnName])
    case updateAllExcept([M.ColumnName])
    case updateRaw(@Sendable (SQL.ConflictColumns<M>) -> String)

    var aliasesTarget: Bool {
      if case .updateRaw = self { true } else { false }
    }
  }

  struct ConflictColumns<M: Model> {
    let alias: String

    public func col(_ column: M.ColumnName) -> String {
      "\"\(M.columnName(column))\""
    }

    public func excluded(_ column: M.ColumnName) -> String {
      "EXCLUDED.\"\(M.columnName(column))\""
    }

    public func target(_ column: M.ColumnName) -> String {
      "\(self.alias).\"\(M.columnName(column))\""
    }
  }
}

extension Sequence<String> {
  var list: String {
    joined(separator: ", ")
  }

  var quotedList: String {
    "\"\(joined(separator: "\", \""))\""
  }
}
