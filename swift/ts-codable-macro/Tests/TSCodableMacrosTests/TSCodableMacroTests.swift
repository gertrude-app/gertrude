#if os(macOS)
  import MacroTesting
  import Testing
  import TSCodableMacros

  @Suite(.macros([TSCodableMacro.self], record: .failed))
  struct TSCodableMacroTests {
    @Test func singleNamedPayload() {
      assertMacro {
        """
        @TSCodable
        enum Status {
          case active
          case suspended(resuming: String)
          case inactive
        }
        """
      } expansion: {
        #"""
        enum Status {
          case active
          case suspended(resuming: String)
          case inactive

          private struct _NamedCase: Codable {
            var `case`: String
            static func extract(from decoder: Decoder) throws -> String {
              let container = try decoder.singleValueContainer()
              return try container.decode(_NamedCase.self).case
            }
          }

          private struct _TypeScriptDecodeError: Error {
            var message: String
          }

          private struct _CaseSuspended: Codable {
            var `case` = "suspended"
            var resuming: String
          }

          func encode(to encoder: Encoder) throws {
            switch self {
            case .active:
              try _NamedCase(case: "active").encode(to: encoder)
            case .suspended(let resuming):
              try _CaseSuspended(resuming: resuming).encode(to: encoder)
            case .inactive:
              try _NamedCase(case: "inactive").encode(to: encoder)
            }
          }

          init(from decoder: Decoder) throws {
            let caseName = try _NamedCase.extract(from: decoder)
            let container = try decoder.singleValueContainer()
            switch caseName {
            case "active":
              self = .active
            case "suspended":
              let value = try container.decode(_CaseSuspended.self)
              self = .suspended(resuming: value.resuming)
            case "inactive":
              self = .inactive
            default:
              throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
            }
          }
        }
        """#
      }
    }

    @Test func multiPayloadNamedCase() {
      assertMacro {
        """
        @TSCodable
        enum NotificationMethod {
          case slack(channelId: String, channelName: String, token: String)
          case email(email: String)
          case text(phoneNumber: String)
        }
        """
      } expansion: {
        #"""
        enum NotificationMethod {
          case slack(channelId: String, channelName: String, token: String)
          case email(email: String)
          case text(phoneNumber: String)

          private struct _NamedCase: Codable {
            var `case`: String
            static func extract(from decoder: Decoder) throws -> String {
              let container = try decoder.singleValueContainer()
              return try container.decode(_NamedCase.self).case
            }
          }

          private struct _TypeScriptDecodeError: Error {
            var message: String
          }

          private struct _CaseSlack: Codable {
            var `case` = "slack"
            var channelId: String
            var channelName: String
            var token: String
          }

          private struct _CaseEmail: Codable {
            var `case` = "email"
            var email: String
          }

          private struct _CaseText: Codable {
            var `case` = "text"
            var phoneNumber: String
          }

          func encode(to encoder: Encoder) throws {
            switch self {
            case .slack(let channelId, let channelName, let token):
              try _CaseSlack(channelId: channelId, channelName: channelName, token: token).encode(to: encoder)
            case .email(let email):
              try _CaseEmail(email: email).encode(to: encoder)
            case .text(let phoneNumber):
              try _CaseText(phoneNumber: phoneNumber).encode(to: encoder)
            }
          }

          init(from decoder: Decoder) throws {
            let caseName = try _NamedCase.extract(from: decoder)
            let container = try decoder.singleValueContainer()
            switch caseName {
            case "slack":
              let value = try container.decode(_CaseSlack.self)
              self = .slack(channelId: value.channelId, channelName: value.channelName, token: value.token)
            case "email":
              let value = try container.decode(_CaseEmail.self)
              self = .email(email: value.email)
            case "text":
              let value = try container.decode(_CaseText.self)
              self = .text(phoneNumber: value.phoneNumber)
            default:
              throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
            }
          }
        }
        """#
      }
    }

    @Test func optionalParameters() {
      assertMacro {
        """
        @TSCodable
        enum Decision {
          case accepted(durationInSeconds: Int, extraMonitoring: String?)
          case rejected
        }
        """
      } expansion: {
        #"""
        enum Decision {
          case accepted(durationInSeconds: Int, extraMonitoring: String?)
          case rejected

          private struct _NamedCase: Codable {
            var `case`: String
            static func extract(from decoder: Decoder) throws -> String {
              let container = try decoder.singleValueContainer()
              return try container.decode(_NamedCase.self).case
            }
          }

          private struct _TypeScriptDecodeError: Error {
            var message: String
          }

          private struct _CaseAccepted: Codable {
            var `case` = "accepted"
            var durationInSeconds: Int
            var extraMonitoring: String?
          }

          func encode(to encoder: Encoder) throws {
            switch self {
            case .accepted(let durationInSeconds, let extraMonitoring):
              try _CaseAccepted(durationInSeconds: durationInSeconds, extraMonitoring: extraMonitoring).encode(to: encoder)
            case .rejected:
              try _NamedCase(case: "rejected").encode(to: encoder)
            }
          }

          init(from decoder: Decoder) throws {
            let caseName = try _NamedCase.extract(from: decoder)
            let container = try decoder.singleValueContainer()
            switch caseName {
            case "accepted":
              let value = try container.decode(_CaseAccepted.self)
              self = .accepted(durationInSeconds: value.durationInSeconds, extraMonitoring: value.extraMonitoring)
            case "rejected":
              self = .rejected
            default:
              throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
            }
          }
        }
        """#
      }
    }

    @Test func arrayAndComplexTypes() {
      assertMacro {
        """
        @TSCodable
        enum Rule {
          case both(a: BlockRule, b: BlockRule)
          case unless(rule: BlockRule, negatedBy: [BlockRule])
        }
        """
      } expansion: {
        #"""
        enum Rule {
          case both(a: BlockRule, b: BlockRule)
          case unless(rule: BlockRule, negatedBy: [BlockRule])

          private struct _NamedCase: Codable {
            var `case`: String
            static func extract(from decoder: Decoder) throws -> String {
              let container = try decoder.singleValueContainer()
              return try container.decode(_NamedCase.self).case
            }
          }

          private struct _TypeScriptDecodeError: Error {
            var message: String
          }

          private struct _CaseBoth: Codable {
            var `case` = "both"
            var a: BlockRule
            var b: BlockRule
          }

          private struct _CaseUnless: Codable {
            var `case` = "unless"
            var rule: BlockRule
            var negatedBy: [BlockRule]
          }

          func encode(to encoder: Encoder) throws {
            switch self {
            case .both(let a, let b):
              try _CaseBoth(a: a, b: b).encode(to: encoder)
            case .unless(let rule, let negatedBy):
              try _CaseUnless(rule: rule, negatedBy: negatedBy).encode(to: encoder)
            }
          }

          init(from decoder: Decoder) throws {
            let caseName = try _NamedCase.extract(from: decoder)
            let container = try decoder.singleValueContainer()
            switch caseName {
            case "both":
              let value = try container.decode(_CaseBoth.self)
              self = .both(a: value.a, b: value.b)
            case "unless":
              let value = try container.decode(_CaseUnless.self)
              self = .unless(rule: value.rule, negatedBy: value.negatedBy)
            default:
              throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
            }
          }
        }
        """#
      }
    }

    @Test func flattenedStructCase() {
      assertMacro {
        """
        @TSCodable
        enum FeedEvent {
          case child(ChildEvent)
          case admin(AdminEvent)
        }
        """
      } expansion: {
        #"""
        enum FeedEvent {
          case child(ChildEvent)
          case admin(AdminEvent)

          private struct _NamedCase: Codable {
            var `case`: String
            static func extract(from decoder: Decoder) throws -> String {
              let container = try decoder.singleValueContainer()
              return try container.decode(_NamedCase.self).case
            }
          }

          private struct _TypeScriptDecodeError: Error {
            var message: String
          }

          private enum _CodingKeys: String, CodingKey {
            case `case`
          }

          func encode(to encoder: Encoder) throws {
            switch self {
            case .child(let value):
              var container = encoder.container(keyedBy: _CodingKeys.self)
              try container.encode("child", forKey: .case)
              try value.encode(to: encoder)
            case .admin(let value):
              var container = encoder.container(keyedBy: _CodingKeys.self)
              try container.encode("admin", forKey: .case)
              try value.encode(to: encoder)
            }
          }

          init(from decoder: Decoder) throws {
            let caseName = try _NamedCase.extract(from: decoder)
            switch caseName {
            case "child":
              self = .child(try ChildEvent(from: decoder))
            case "admin":
              self = .admin(try AdminEvent(from: decoder))
            default:
              throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
            }
          }
        }
        """#
      }
    }

    @Test func kitchenSink() {
      assertMacro {
        """
        @TSCodable
        enum ComputerStatus {
          case offline
          case filterOff
          case filterOn
          case filterSuspended(resuming: Date?)
          case connected(ConnectionInfo)
        }
        """
      } expansion: {
        #"""
        enum ComputerStatus {
          case offline
          case filterOff
          case filterOn
          case filterSuspended(resuming: Date?)
          case connected(ConnectionInfo)

          private struct _NamedCase: Codable {
            var `case`: String
            static func extract(from decoder: Decoder) throws -> String {
              let container = try decoder.singleValueContainer()
              return try container.decode(_NamedCase.self).case
            }
          }

          private struct _TypeScriptDecodeError: Error {
            var message: String
          }

          private enum _CodingKeys: String, CodingKey {
            case `case`
          }

          private struct _CaseFilterSuspended: Codable {
            var `case` = "filterSuspended"
            var resuming: Date?
          }

          func encode(to encoder: Encoder) throws {
            switch self {
            case .offline:
              try _NamedCase(case: "offline").encode(to: encoder)
            case .filterOff:
              try _NamedCase(case: "filterOff").encode(to: encoder)
            case .filterOn:
              try _NamedCase(case: "filterOn").encode(to: encoder)
            case .filterSuspended(let resuming):
              try _CaseFilterSuspended(resuming: resuming).encode(to: encoder)
            case .connected(let value):
              var container = encoder.container(keyedBy: _CodingKeys.self)
              try container.encode("connected", forKey: .case)
              try value.encode(to: encoder)
            }
          }

          init(from decoder: Decoder) throws {
            let caseName = try _NamedCase.extract(from: decoder)
            let container = try decoder.singleValueContainer()
            switch caseName {
            case "offline":
              self = .offline
            case "filterOff":
              self = .filterOff
            case "filterOn":
              self = .filterOn
            case "filterSuspended":
              let value = try container.decode(_CaseFilterSuspended.self)
              self = .filterSuspended(resuming: value.resuming)
            case "connected":
              self = .connected(try ConnectionInfo(from: decoder))
            default:
              throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
            }
          }
        }
        """#
      }
    }

    @Test func publicEnum() {
      assertMacro {
        """
        @TSCodable
        public enum BlockRule {
          case hostnameEquals(value: String)
          case both(a: BlockRule, b: BlockRule)
        }
        """
      } expansion: {
        #"""
        public enum BlockRule {
          case hostnameEquals(value: String)
          case both(a: BlockRule, b: BlockRule)

          private struct _NamedCase: Codable {
            var `case`: String
            static func extract(from decoder: Decoder) throws -> String {
              let container = try decoder.singleValueContainer()
              return try container.decode(_NamedCase.self).case
            }
          }

          private struct _TypeScriptDecodeError: Error {
            var message: String
          }

          private struct _CaseHostnameEquals: Codable {
            var `case` = "hostnameEquals"
            var value: String
          }

          private struct _CaseBoth: Codable {
            var `case` = "both"
            var a: BlockRule
            var b: BlockRule
          }

          public func encode(to encoder: Encoder) throws {
            switch self {
            case .hostnameEquals(let value):
              try _CaseHostnameEquals(value: value).encode(to: encoder)
            case .both(let a, let b):
              try _CaseBoth(a: a, b: b).encode(to: encoder)
            }
          }

          public init(from decoder: Decoder) throws {
            let caseName = try _NamedCase.extract(from: decoder)
            let container = try decoder.singleValueContainer()
            switch caseName {
            case "hostnameEquals":
              let value = try container.decode(_CaseHostnameEquals.self)
              self = .hostnameEquals(value: value.value)
            case "both":
              let value = try container.decode(_CaseBoth.self)
              self = .both(a: value.a, b: value.b)
            default:
              throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
            }
          }
        }
        """#
      }
    }

    @Test func errorOnFlattenedPrimitive() {
      assertMacro {
        """
        @TSCodable
        enum Event {
          case child(ChildEvent)
          case error(String)
        }
        """
      } diagnostics: {
        """
        @TSCodable
        enum Event {
          case child(ChildEvent)
          case error(String)
                     ┬─────
                     ╰─ 🛑 single unnamed primitive parameter cannot be flattened; add a label to encode it as a named field
        }
        """
      }
    }

    @Test func diagnosticOnStruct() {
      assertMacro {
        """
        @TSCodable
        struct NotAnEnum {
          var name: String
        }
        """
      } diagnostics: {
        """
        @TSCodable
        ┬─────────
        ╰─ 🛑 @TSCodable can only be applied to enum declarations
        struct NotAnEnum {
          var name: String
        }
        """
      }
    }
  }
#endif
