import Dependencies
import DuetSQL
import Gertie
import Tagged

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

extension BlockerApp.SuspendFilterRequest {
  typealias Id = Tagged<BlockerApp.SuspendFilterRequest, UUID>
}

extension BlockerApp.SuspendFilterRequest {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case deviceId
    case status
    case duration
    case requestComment
    case responseComment
    case createdAt
    case updatedAt
  }
}

extension BlockerApp.Token {
  typealias Id = Tagged<BlockerApp.Token, UUID>
  typealias Value = Tagged<(BlockerApp.Token, value: ()), UUID>
}

extension BlockerApp.Token {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case installId
    case value
    case createdAt
    case updatedAt
  }
}

extension IOSDevice: Duet.Identifiable {
  typealias Id = Tagged<IOSDevice, UUID>
}

extension IOSDevice {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case childId
    case modelIdentifier
    case iosVersion
    case createdAt
    case updatedAt
  }
}

extension BlockerApp.Install: Duet.Identifiable {
  typealias Id = Tagged<BlockerApp.Install, UUID>
}

extension BlockerApp.Install {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case deviceId
    case appVersion
    case webPolicy
    case isProfileLocked
    case allowAppRemoval
    case allowEraseContentAndSettings
    case allowAppInstallation
    case createdAt
    case updatedAt
  }
}

extension BlockerApp.Supervision: Duet.Identifiable {
  typealias Id = Tagged<BlockerApp.Supervision, UUID>
}

extension BlockerApp.Supervision {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case deviceId
    case udid
    case supervisedAt
    case profileInstalledAt
    case createdAt
    case updatedAt
  }
}

extension PodcastApp.Install: Duet.Identifiable {
  typealias Id = Tagged<PodcastApp.Install, UUID>
}

extension PodcastApp.Install {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case deviceId
    case appVersion
    case createdAt
    case updatedAt
  }
}

extension PodcastApp.Token {
  typealias Id = Tagged<PodcastApp.Token, UUID>
  typealias Value = Tagged<(PodcastApp.Token, value: ()), UUID>
}

extension PodcastApp.Token {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case installId
    case value
    case createdAt
    case updatedAt
  }
}

extension MusicApp.Install: Duet.Identifiable {
  typealias Id = Tagged<MusicApp.Install, UUID>
}

extension MusicApp.Install {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case deviceId
    case appVersion
    case createdAt
    case updatedAt
  }
}

extension MusicApp.Token {
  typealias Id = Tagged<MusicApp.Token, UUID>
  typealias Value = Tagged<(MusicApp.Token, value: ()), UUID>
}

extension MusicApp.Token {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case installId
    case value
    case createdAt
    case updatedAt
  }
}

extension MusicApp.Event: Duet.Identifiable {
  typealias Id = Tagged<MusicApp.Event, UUID>
}

extension MusicApp.Event {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case eventId
    case level
    case domain
    case detail
    case deviceId
    case modelIdentifier
    case iosVersion
    case appVersion
    case createdAt
  }
}

extension BlockerApp.BlockRule: Duet.Identifiable {
  typealias Id = Tagged<BlockerApp.BlockRule, UUID>
}

extension BlockerApp.BlockRule {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case deviceId
    case rule
    case groupId
    case comment
    case createdAt
    case updatedAt
  }
}

extension UserBlockedApp: Duet.Identifiable {
  typealias Id = Tagged<UserBlockedApp, UUID>
}

extension UserBlockedApp {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case identifier
    case childId
    case schedule
    case createdAt
    case updatedAt
  }
}

extension Parent: Duet.Identifiable {
  typealias Id = Tagged<Parent, UUID>
}

extension Parent {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case email
    case password
    case emailVerifiedAt
    case gclid
    case abTestVariant
    case referralCode
    case referredByParentId
    case timeZone
    case dailyReviewEmail
    case lastReviewEmailAt
    case createdAt
    case updatedAt
  }
}

extension StripeSubscription: Duet.Identifiable {
  typealias Id = Tagged<StripeSubscription, UUID>
}

extension StripeSubscription {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case tier
    case stripeId
    case stripeStatus
    case currentPeriodEnd
    case isLegacyPrice
    case createdAt
    case updatedAt
  }
}

extension BillingIdentity: Duet.Identifiable {
  typealias Id = Tagged<BillingIdentity, UUID>
}

extension BillingIdentity {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case stripeCustomerId
    case fullTrialStartedAt
    case lastStripeSubscriptionId
    case lastPaidTier
    case trialEmailLifecycle
    case isComplimentary
    case legacyAmIapPaidAt
    case createdAt
    case updatedAt
  }
}

extension Parent.Notification: Duet.Identifiable {
  typealias Id = Tagged<Parent.Notification, UUID>
}

extension Parent.Notification {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case methodId
    case trigger
    case createdAt
  }
}

extension Parent.Notification.Trigger: PostgresEnum {
  var typeName: String { "enum_parent_notification_trigger" }
}

extension Parent.DashToken: Duet.Identifiable {
  typealias Id = Tagged<Parent.DashToken, UUID>
}

extension Parent.DashToken {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case value
    case createdAt
    case deletedAt
  }
}

extension Parent.NotificationMethod: Duet.Identifiable {
  typealias Id = Tagged<Parent.NotificationMethod, UUID>
}

extension Parent.NotificationMethod {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case config
    case createdAt
  }
}

extension AppCategory: Duet.Identifiable {
  typealias Id = Tagged<AppCategory, UUID>
}

extension AppCategory {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case name
    case slug
    case description
    case createdAt
    case updatedAt
  }
}

extension AppBundleId: Duet.Identifiable {
  typealias Id = Tagged<AppBundleId, UUID>
}

extension AppBundleId {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case bundleId
    case identifiedAppId
    case count
    case createdAt
    case updatedAt
  }
}

extension Computer: Duet.Identifiable {
  typealias Id = Tagged<Computer, UUID>
}

extension Computer {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case customName
    case modelIdentifier
    case serialNumber
    case appReleaseChannel
    case filterVersion
    case osVersion
    case createdAt
    case updatedAt
  }
}

extension ComputerUser: Duet.Identifiable {
  typealias Id = Tagged<ComputerUser, UUID>
}

extension ComputerUser {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case childId
    case computerId
    case appVersion
    case isAdmin
    case username
    case fullUsername
    case numericId
    case createdAt
    case updatedAt
  }
}

extension IdentifiedApp: Duet.Identifiable {
  typealias Id = Tagged<IdentifiedApp, UUID>
}

extension IdentifiedApp {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case categoryId
    case name
    case slug
    case launchable
    case createdAt
    case updatedAt
  }
}

extension Keychain: Duet.Identifiable {
  typealias Id = Tagged<Keychain, UUID>
}

extension Keychain {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case name
    case description
    case warning
    case isPublic
    case rootDomain
    case brandColor
    case createdAt
    case updatedAt
  }
}

extension Key: Duet.Identifiable {
  typealias Id = Tagged<Key, UUID>
}

extension Key {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case keychainId
    case key
    case comment
    case createdAt
    case updatedAt
    case deletedAt
  }
}

extension Release: Duet.Identifiable {
  typealias Id = Tagged<Release, UUID>
}

extension Release {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case semver
    case channel
    case signature
    case length
    case revision
    case requirementPace
    case minVersion
    case notes
    case createdAt
    case updatedAt
  }
}

extension ReleaseChannel: @retroactive PostgresEnum {
  public var typeName: String { "enum_release_channels" }
}

extension StripeEvent: Duet.Identifiable {
  typealias Id = Tagged<StripeEvent, UUID>
}

extension StripeEvent {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case json
    case stripeEventId
    case createdAt
  }
}

extension Screenshot: Duet.Identifiable {
  typealias Id = Tagged<Screenshot, UUID>
}

extension Screenshot {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case computerUserId
    case url
    case width
    case height
    case filterSuspended
    case flagged
    case createdAt
    case deletedAt
  }
}

extension MacApp.SuspendFilterRequest: Duet.Identifiable {
  typealias Id = Tagged<MacApp.SuspendFilterRequest, UUID>
}

extension MacApp.SuspendFilterRequest {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case computerUserId
    case status
    case scope
    case duration
    case requestComment
    case responseComment
    case extraMonitoring
    case createdAt
    case updatedAt
  }
}

extension UnlockRequest: Duet.Identifiable {
  typealias Id = Tagged<UnlockRequest, UUID>
}

extension UnlockRequest {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case computerUserId
    case status
    case requestComment
    case responseComment
    case appBundleId
    case url
    case hostname
    case ipAddress
    case createdAt
    case updatedAt
  }
}

extension Child: Duet.Identifiable {
  typealias Id = Tagged<Child, UUID>
}

extension Child {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case name
    case keyloggingEnabled
    case screenshotsEnabled
    case screenshotsResolution
    case screenshotsFrequency
    case showSuspensionActivity
    case filteringDisabled
    case downtime
    case createdAt
    case updatedAt
  }
}

extension ChildKeychain: Duet.Identifiable {
  typealias Id = Tagged<ChildKeychain, UUID>
}

extension ChildKeychain {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case childId
    case keychainId
    case schedule
    case createdAt
  }
}

extension AlwaysBlockedGroup: Duet.Identifiable {
  typealias Id = Tagged<AlwaysBlockedGroup, UUID>
}

extension AlwaysBlockedGroup {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case name
    case description
    case longDescription
    case recommended
    case createdAt
    case updatedAt
  }
}

extension AlwaysBlockedRule: Duet.Identifiable {
  typealias Id = Tagged<AlwaysBlockedRule, UUID>
}

extension AlwaysBlockedRule {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case groupId
    case rule
    case comment
    case createdAt
    case updatedAt
  }
}

extension ChildAlwaysBlockedGroup: Duet.Identifiable {
  typealias Id = Tagged<ChildAlwaysBlockedGroup, UUID>
}

extension ChildAlwaysBlockedGroup {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case childId
    case groupId
    case createdAt
  }
}

extension ChildAlwaysBlockedRule: Duet.Identifiable {
  typealias Id = Tagged<ChildAlwaysBlockedRule, UUID>
}

extension ChildAlwaysBlockedRule {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case childId
    case rule
    case comment
    case createdAt
    case updatedAt
  }
}

extension MacAppToken: Duet.Identifiable {
  typealias Id = Tagged<MacAppToken, UUID>
}

extension MacAppToken {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case childId
    case computerUserId
    case value
    case createdAt
    case updatedAt
    case deletedAt
  }
}

extension RouteTelemetry: Duet.Identifiable {
  typealias Id = Tagged<RouteTelemetry, UUID>
}

extension RouteTelemetry {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case kind
    case requestId
    case domain
    case operation
    case durationMs
    case result
    case errorId
    case errorType
    case errorMessage
    case parentId
    case ipAddress
    case userAgent
    case numRequestBytes
    case numResponseBytes
    case createdAt
  }
}

extension MarketingEmailSend: Duet.Identifiable {
  typealias Id = Tagged<MarketingEmailSend, UUID>
}

extension MarketingEmailSend {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case campaign
    case variant
    case createdAt
  }
}

extension InterestingEvent: Duet.Identifiable {
  typealias Id = Tagged<InterestingEvent, UUID>
}

extension InterestingEvent {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case eventId
    case kind
    case context
    case computerUserId
    case parentId
    case detail
    case createdAt
  }
}

extension DeletedEntity: Duet.Identifiable {
  typealias Id = Tagged<DeletedEntity, UUID>
}

extension DeletedEntity {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case type
    case reason
    case data
    case createdAt
  }
}

extension Browser: Duet.Identifiable {
  typealias Id = Tagged<Browser, UUID>
}

extension Browser {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case match
    case createdAt
  }
}

extension UnidentifiedApp: Duet.Identifiable {
  typealias Id = Tagged<UnidentifiedApp, UUID>
}

extension UnidentifiedApp {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case bundleId
    case bundleName
    case localizedName
    case launchable
    case count
    case createdAt
  }
}

extension SecurityEvent: Duet.Identifiable {
  typealias Id = Tagged<SecurityEvent, UUID>
}

extension SecurityEvent {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case computerUserId
    case event
    case detail
    case ipAddress
    case createdAt
  }
}

extension BlockerApp.BlockGroup: Duet.Identifiable {
  typealias Id = Tagged<BlockerApp.BlockGroup, UUID>
}

extension BlockerApp.BlockGroup {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case name
    case description
    case longDescription
    case imageSlug
    case optIn
    case createdAt
    case updatedAt
  }
}

extension BlockerApp.DeviceBlockGroup: Duet.Identifiable {
  typealias Id = Tagged<BlockerApp.DeviceBlockGroup, UUID>
}

extension BlockerApp.DeviceBlockGroup {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case deviceId
    case blockGroupId
    case createdAt
  }
}

extension BlockerApp.WebPolicyDomain: Duet.Identifiable {
  typealias Id = Tagged<BlockerApp.WebPolicyDomain, UUID>
}

extension BlockerApp.WebPolicyDomain {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case deviceId
    case domain
    case createdAt
    case updatedAt
  }
}

extension PodcastEvent: Duet.Identifiable {
  typealias Id = Tagged<PodcastEvent, UUID>
}

extension PodcastEvent {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case eventId
    case level
    case domain
    case modelIdentifier
    case appVersion
    case iosVersion
    case deviceId
    case detail
    case createdAt
  }
}

extension IOSEvent: Duet.Identifiable {
  typealias Id = Tagged<IOSEvent, UUID>
}

extension IOSEvent {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case eventId
    case level
    case domain
    case detail
    case deviceId
    case modelIdentifier
    case iosVersion
    case appVersion
    case createdAt
  }
}

extension AppStore.Review: Duet.Identifiable {
  typealias Id = Tagged<AppStore.Review, UUID>
}

extension AppStore.Review {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case appleId
    case app
    case rating
    case title
    case body
    case reviewerNickname
    case territory
    case reviewCreatedAt
    case createdAt
  }
}

extension AppStore.RatingSnapshot: Duet.Identifiable {
  typealias Id = Tagged<AppStore.RatingSnapshot, UUID>
}

extension AppStore.RatingSnapshot {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case app
    case averageRating
    case totalCount
    case reviewCount
    case createdAt
  }
}

extension AppStore.RatingEvent: Duet.Identifiable {
  typealias Id = Tagged<AppStore.RatingEvent, UUID>
}

extension AppStore.RatingEvent {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case app
    case stars
    case createdAt
  }
}

extension SmsSend: Duet.Identifiable {
  typealias Id = Tagged<SmsSend, UUID>
}

extension SmsSend {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case trigger
    case countryCode
    case twilioMessageSid
    case numSegments
    case createdAt
  }
}

extension ShortUrl: Duet.Identifiable {
  typealias Id = Tagged<ShortUrl, UUID>
}

extension ShortUrl {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case shortId
    case target
    case clickCount
    case createdAt
    case deletedAt
  }
}

extension CatalogedApp: Duet.Identifiable {
  typealias Id = Tagged<CatalogedApp, UUID>
}

extension CatalogedApp {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case bundleId
    case name
    case category
    case icon
    case iconContentHash
    case iconUploadedAt
    case iconSourceAppVersion
    case createdAt
    case updatedAt
  }
}

extension InstalledMacApp: Duet.Identifiable {
  typealias Id = Tagged<InstalledMacApp, UUID>
}

extension InstalledMacApp {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case childId
    case computerId
    case macAppId
    case createdAt
    case updatedAt
  }
}

extension Music.ApprovedAlbum: Duet.Identifiable {
  typealias Id = Tagged<Music.ApprovedAlbum, UUID>
}

extension Music.ApprovedAlbum {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case childId
    case appleMusicAlbumId
    case title
    case artistName
    case artworkUrl
    case trackCount
    case showsArtwork
    case createdAt
  }
}
