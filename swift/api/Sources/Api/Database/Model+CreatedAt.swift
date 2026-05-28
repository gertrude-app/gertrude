#if DEBUG
  import Dependencies
  import DuetSQL
  import Foundation
  import Vapor

  enum TimestampAdjustment {
    case subtracting(TimeInterval)
    case adding(TimeInterval)
    case exact(Date)
  }

  extension DuetSQL.Model {
    /// updates `createdAt` both in memory and in db so tests can stage "old" data
    mutating func modifyCreatedAt(_ adjustment: TimestampAdjustment) async throws {
      switch adjustment {
      case .subtracting(let interval):
        self.createdAt = createdAt.addingTimeInterval(-interval)
      case .adding(let interval):
        self.createdAt = createdAt.addingTimeInterval(interval)
      case .exact(let date):
        self.createdAt = date
      }

      @Dependency(\.db) var db
      guard let client = db as? PgClient else {
        throw Abort(.internalServerError, reason: "af72eb37")
      }

      try await client.db.execute(
        """
        UPDATE \(unsafeRaw: Self.qualifiedTableName)
        SET \(col: .createdAt) = '\(unsafeRaw: self.createdAt.isoString)'
        WHERE id = '\(unsafeRaw: self.id.uuidString.lowercased())'
        """,
      )
    }
  }
#endif
