import Dependencies
import DuetSQL
import Gertie
import GertieApp
import GertieBlocker
import Tagged

extension DashAnnouncement.Kind: PostgresRawBindable {}
extension ClaimIntent: PostgresRawBindable {}
extension EventLevel: @retroactive PostgresRawBindable {}
extension GertrudeIOSApp: @retroactive PostgresRawBindable {}
extension StripeSubscription.StripeStatus: PostgresRawBindable {}
extension BillingIdentity.TrialEmailLifecycle: PostgresRawBindable {}
extension RouteTelemetry.Result: PostgresRawBindable {}

extension Semver: @retroactive PostgresBindable {
  public var postgresData: Postgres.Data { .string(self.string) }
  public static var nilPostgresData: Postgres.Data { .string(nil) }
}

extension GertieBlocker.BlockRule: @retroactive PostgresJsonable {}

extension Parent.NotificationMethod.Config: PostgresJsonable {}

extension Gertie.Key: @retroactive PostgresJsonable {}

extension AppScope: @retroactive PostgresJsonable {}

extension RuleSchedule: @retroactive PostgresJsonable {}
extension PlainTimeWindow: @retroactive PostgresJsonable {}
extension DashAnnouncement.Action: PostgresJsonable {}

extension BrowserMatch: @retroactive PostgresJsonable {}

extension RequestStatus: @retroactive PostgresEnum {
  public var typeName: String { "enum_shared_request_status" }
}

extension StripeSubscription.Tier: PostgresEnum {
  public var typeName: String { "parent.subscription_tier" }
}

protocol HasOptionalDeletedAt {
  var deletedAt: Date? { get set }
}

extension HasOptionalDeletedAt {
  var isDeleted: Bool {
    guard let deletedAt else { return false }
    @Dependency(\.date.now) var now
    return deletedAt < now
  }

  var notDeleted: Bool { !self.isDeleted }
}

extension KeystrokeLine: HasOptionalDeletedAt {}
extension Screenshot: HasOptionalDeletedAt {}

extension Either where Left: DuetSQL.Model, Right: DuetSQL.Model {
  var createdAt: Date {
    switch self {
    case .left(let model):
      model.createdAt
    case .right(let model):
      model.createdAt
    }
  }
}

extension BlockerApp.Token {
  typealias Value = Tagged<(BlockerApp.Token, value: ()), UUID>
}

extension PodcastApp.Token {
  typealias Value = Tagged<(PodcastApp.Token, value: ()), UUID>
}

extension MusicApp.Token {
  typealias Value = Tagged<(MusicApp.Token, value: ()), UUID>
}

extension Parent.Notification.Trigger: PostgresRawBindable {}

extension ReleaseChannel: @retroactive PostgresEnum {
  public var typeName: String { "enum_release_channels" }
}
