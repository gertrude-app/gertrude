#if os(macOS)
  import DuetMacros
  import MacroTesting
  import XCTest

  final class DuetModelMacroTests: XCTestCase {
    override func invokeTest() {
      withMacroTesting(record: .failed, macros: [DuetModelMacro.self]) {
        super.invokeTest()
      }
    }

    func testBasicModel() {
      assertMacro {
        """
        @DuetModel(schema: "parent", table: "dash_announcements")
        struct DashAnnouncement: Codable, Sendable {
          var id: Id
          var parentId: Parent.Id
          var icon: String?
          var html: String
          var createdAt = Date()
          var deletedAt: Date
        }
        """
      } expansion: {
        """
        struct DashAnnouncement: Codable, Sendable {
          var id: Id
          var parentId: Parent.Id
          var icon: String?
          var html: String
          var createdAt = Date()
          var deletedAt: Date

          typealias Id = Tagged<DashAnnouncement, UUID>

          enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
            case id
            case parentId
            case icon
            case html
            case createdAt
            case deletedAt
          }
        }

        extension DashAnnouncement {
          static let schemaName = "parent"
          static let tableName = "dash_announcements"
          typealias ColumnName = CodingKeys

          var insertValues: [ColumnName: Postgres.Data] {
            [
              .id: .id(self),
              .parentId: self.parentId.postgresData,
              .icon: self.icon.postgresData,
              .html: self.html.postgresData,
              .createdAt: .currentTimestamp,
              .deletedAt: self.deletedAt.postgresData,
            ]
          }
        }
        """
      }
    }

    func testUpdatedAtBecomesCurrentTimestamp() {
      assertMacro {
        """
        @DuetModel(schema: "child", table: "claims")
        struct Claim: Codable, Sendable, Equatable {
          var id: Id
          var code: Int
          var expiresAt: Date
          var createdAt = Date()
          var updatedAt = Date()
        }
        """
      } expansion: {
        """
        struct Claim: Codable, Sendable, Equatable {
          var id: Id
          var code: Int
          var expiresAt: Date
          var createdAt = Date()
          var updatedAt = Date()

          typealias Id = Tagged<Claim, UUID>

          enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
            case id
            case code
            case expiresAt
            case createdAt
            case updatedAt
          }
        }

        extension Claim {
          static let schemaName = "child"
          static let tableName = "claims"
          typealias ColumnName = CodingKeys

          var insertValues: [ColumnName: Postgres.Data] {
            [
              .id: .id(self),
              .code: self.code.postgresData,
              .expiresAt: self.expiresAt.postgresData,
              .createdAt: .currentTimestamp,
              .updatedAt: .currentTimestamp,
            ]
          }
        }
        """
      }
    }

    func testClientCreatedAtOptOut() {
      assertMacro {
        """
        @DuetModel(schema: "macapp", table: "keystroke_lines", clientCreatedAt: true)
        struct KeystrokeLine: Codable, Sendable {
          var id: Id
          var line: String
          var createdAt = Date()
          var deletedAt: Date?
        }
        """
      } expansion: {
        """
        struct KeystrokeLine: Codable, Sendable {
          var id: Id
          var line: String
          var createdAt = Date()
          var deletedAt: Date?

          typealias Id = Tagged<KeystrokeLine, UUID>

          enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
            case id
            case line
            case createdAt
            case deletedAt
          }
        }

        extension KeystrokeLine {
          static let schemaName = "macapp"
          static let tableName = "keystroke_lines"
          typealias ColumnName = CodingKeys

          var insertValues: [ColumnName: Postgres.Data] {
            [
              .id: .id(self),
              .line: self.line.postgresData,
              .createdAt: self.createdAt.postgresData,
              .deletedAt: self.deletedAt.postgresData,
            ]
          }
        }
        """
      }
    }

    func testPublicModel() {
      assertMacro {
        """
        @DuetModel(schema: "system", table: "things")
        public struct Thing: Codable {
          public var id: Id
          public var name: String
          public var createdAt = Date()
        }
        """
      } expansion: {
        """
        public struct Thing: Codable {
          public var id: Id
          public var name: String
          public var createdAt = Date()

          public typealias Id = Tagged<Thing, UUID>

          public enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
            case id
            case name
            case createdAt
          }
        }

        extension Thing {
          public static let schemaName = "system"
          public static let tableName = "things"
          public typealias ColumnName = CodingKeys

          public var insertValues: [ColumnName: Postgres.Data] {
            [
              .id: .id(self),
              .name: self.name.postgresData,
              .createdAt: .currentTimestamp,
            ]
          }
        }
        """
      }
    }

    func testComputedAndStaticPropertiesSkipped() {
      assertMacro {
        """
        @DuetModel(schema: "parent", table: "parents")
        struct Parent: Codable {
          static let fixed = 3
          var id: Id
          var email: String
          var createdAt = Date()

          var emailVerified: Bool {
            self.emailVerifiedAt != nil
          }
        }
        """
      } expansion: {
        """
        struct Parent: Codable {
          static let fixed = 3
          var id: Id
          var email: String
          var createdAt = Date()

          var emailVerified: Bool {
            self.emailVerifiedAt != nil
          }

          typealias Id = Tagged<Parent, UUID>

          enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
            case id
            case email
            case createdAt
          }
        }

        extension Parent {
          static let schemaName = "parent"
          static let tableName = "parents"
          typealias ColumnName = CodingKeys

          var insertValues: [ColumnName: Postgres.Data] {
            [
              .id: .id(self),
              .email: self.email.postgresData,
              .createdAt: .currentTimestamp,
            ]
          }
        }
        """
      }
    }

    func testNotAStructErrors() {
      assertMacro {
        """
        @DuetModel(schema: "parent", table: "things")
        enum Thing {
          case foo
        }
        """
      } diagnostics: {
        """
        @DuetModel(schema: "parent", table: "things")
        ┬────────────────────────────────────────────
        ╰─ 🛑 @DuetModel can only be applied to struct declarations
        enum Thing {
          case foo
        }
        """
      }
    }

    func testMissingIdErrors() {
      assertMacro {
        """
        @DuetModel(schema: "parent", table: "things")
        struct Thing: Codable {
          var name: String
          var createdAt = Date()
        }
        """
      } diagnostics: {
        """
        @DuetModel(schema: "parent", table: "things")
        ┬────────────────────────────────────────────
        ╰─ 🛑 @DuetModel requires a stored `id` property
        struct Thing: Codable {
          var name: String
          var createdAt = Date()
        }
        """
      }
    }
  }
#endif
