import QueuesFluentDriver
import Vapor

extension Configure {
  static func migrations(_ app: Application) throws {
    app.migrations.add(AdminTables())
    app.migrations.add(KeychainTables())
    app.migrations.add(UserTables())
    app.migrations.add(ActivityTables())
    app.migrations.add(RequestTables())
    app.migrations.add(AppTables())
    app.migrations.add(MiscTables())
    app.migrations.add(JobMetadataMigrate())
    app.migrations.add(InterestingEventsTable())
    app.migrations.add(AddReleaseRequirementPace())
    app.migrations.add(DropWaitlistedAdmins())
    app.migrations.add(DeviceRefactor())
    app.migrations.add(AddReleaseNotes())
    app.migrations.add(DeviceIdForeignKey())
    app.migrations.add(DeviceFilterVersion())
    app.migrations.add(DuringSuspensionActivity())
    app.migrations.add(ReworkPayments())
    app.migrations.add(AddUserShowSuspensionActivity())
    app.migrations.add(EliminateNetworkDecisionsTable())
    app.migrations.add(AddAdminGclid())
    app.migrations.add(BrowsersTable())
    app.migrations.add(SecurityEvents())
    app.migrations.add(ABTestVariants())
    app.migrations.add(ModifySecurityEventsTable())
    app.migrations.add(AddExtraMonitoring())
    app.migrations.add(RemoveSoftDeletes())
    app.migrations.add(RemoveUserTokenNullable())
    app.migrations.add(ScreenshotDisplayId())
    app.migrations.add(RevertScreenshotDisplayId())
    app.migrations.add(UnidentifiedApps())
    app.migrations.add(ScheduleFeatures())
    app.migrations.add(AppBlockingFeature())
    app.migrations.add(IOSBlockRules())
    app.migrations.add(KeychainWarning())
    app.migrations.add(MultipleSchemas())
    // not deleted after here...
    app.migrations.add(RecreateTables())
    app.migrations.add(MarketingPrep())
    app.migrations.add(SearchPaths())
    app.migrations.add(FlaggedActivity())
    app.migrations.add(DashAnnouncements())
    app.migrations.add(IOSConnection())
    app.migrations.add(RenameParentNotifMethods())
    app.migrations.add(CreateBlockGroups())
    app.migrations.add(CreateDeviceBlockGroups())
    app.migrations.add(CreateWebPolicyDomains())
    app.migrations.add(ReencodeIOSBlockRules())
    app.migrations.add(PodcastEvents())
    app.migrations.add(AddSpotifyBlockGroup())
    app.migrations.add(ReleaseMinVersion())
    app.migrations.add(SuperAdminTokens())
    app.migrations.add(IOSEvents())
    app.migrations.add(PendingSupervisions())
    app.migrations.add(UpdatePendingSupervision())
    app.migrations.add(AppStoreReviews())
    app.migrations.add(IOSModelIdentifiers())
    app.migrations.add(DashAnnouncementKind())
    app.migrations.add(SupervisionStateBooleans())
    app.migrations.add(LoginSearchPathTrigger())
    app.migrations.add(FixSearchPathTrigger())
    app.migrations.add(VendorIdAsDeviceId())
    app.migrations.add(CreateSupervisionTable())
    app.migrations.add(SmsSends())
    app.migrations.add(SecurityEventNotificationTriggers())
    app.migrations.add(SubscriptionRefactor())
    app.migrations.add(AddProfileLocked())
    app.migrations.add(BlockGroupLongDescriptions())
    app.migrations.add(DropParentDeletedAt())
    app.migrations.add(IOSDeviceRestrictionToggles())
    app.migrations.add(IOSEventCheckinKind())
    app.migrations.add(ReencodeFlowTypeAsString())
    app.migrations.add(PodcastDeviceId())
    app.migrations.add(BlockGroupImageSlugs())
    app.migrations.add(DropIosScreenshots())
    app.migrations.add(AddChildFilteringDisabled())
    app.migrations.add(DeduplicateKeys())
    app.migrations.add(AddAppBundleIdCount())
    app.migrations.add(CreateMacAppsTables())
    app.migrations.add(AddKeychainRootDomain())
    app.migrations.add(ShortUrlsAndSmsSendFields())
    app.migrations.add(CreateAlwaysBlockedTables())
    app.migrations.add(AddKeychainBrandColor())
    app.migrations.add(AddAlwaysBlockedGroupRecommended())
    app.migrations.add(CreateRouteTelemetry())
    app.migrations.add(CreateMarketingEmailSends())
    app.migrations.add(AddIOSBlockGroupOptIn())
    app.migrations.add(AddPerfIndexes())
    app.migrations.add(EnrichRouteTelemetry())
    app.migrations.add(AppInstallTables())
    app.migrations.add(HoistClaimFieldsToDevice())
    app.migrations.add(AppIconUploadProvenance())
    app.migrations.add(BlockerAppTokenInstallFk())
    app.migrations.add(StripeBillingOverhaul())
    app.migrations.add(PodcastAppTablesAndLegacyAmIap())
    app.migrations.add(AddAllowAppInstallation())
    app.migrations.add(AddMarketingEmailSendVariant())
    app.migrations.add(AddParentReferrals())
    app.migrations.add(PodcastAppTokenInstallUnique())
    app.migrations.add(AddDashboardPerfIndexes())
    app.migrations.add(CreateMusicTables())
    app.migrations.add(AddParentDailyReviewEmail())
    app.migrations.add(DashAnnouncementAction())
    app.migrations.add(ClaimsCutover())
    app.migrations.add(CreateMusicEvents())
    app.migrations.add(AddNativeIOSAppEventFields())
    app.migrations.add(PgEnumsToText())
    app.migrations.add(TrackDeprecationLastSeen())
    app.migrations.add(BlockerProfileSettings())
    app.migrations.add(MediumTier())
    app.migrations.add(AddParentAccountSiteBeta())
    app.migrations.add(ExpandMusicLibrary())
    app.migrations.add(AppStoreMusicApp())
    app.migrations.add(AddChildRelationship())
    app.migrations.add(AddMusicTrackGrants())
    app.migrations.add(CreateUnrestrictedMacApps())
    app.migrations.add(BackfillUnrestrictedMacApps())
    app.migrations.add(AddDashAnnouncementCampaign())
    app.migrations.add(WidenRouteTelemetryErrorId())
    app.migrations.add(AddCardFingerprint())
  }
}

// deleted migrations

// @see https://github.com/gertrude-app/swift/tree/833260d1
struct AdminTables: DeletedMigration {}
struct ActivityTables: DeletedMigration {}
struct DeviceFilterVersion: DeletedMigration {}
struct IOSBlockRules: DeletedMigration {}
struct AppBlockingFeature: DeletedMigration {}
struct AddExtraMonitoring: DeletedMigration {}
struct BrowsersTable: DeletedMigration {}
struct AddReleaseNotes: DeletedMigration {}
struct KeychainTables: DeletedMigration {}
struct DeviceRefactor: DeletedMigration {}
struct ModifySecurityEventsTable: DeletedMigration {}
struct KeychainWarning: DeletedMigration {}
struct DuringSuspensionActivity: DeletedMigration {}
struct ReworkPayments: DeletedMigration {}
struct DeviceIdForeignKey: DeletedMigration {}
struct UnidentifiedApps: DeletedMigration {}
struct ABTestVariants: DeletedMigration {}
struct EliminateNetworkDecisionsTable: DeletedMigration {}
struct RemoveUserTokenNullable: DeletedMigration {}
struct RemoveSoftDeletes: DeletedMigration {}
struct UserTables: DeletedMigration {}
struct AddUserShowSuspensionActivity: DeletedMigration {}
struct ScreenshotDisplayId: DeletedMigration {}
struct RevertScreenshotDisplayId: DeletedMigration {}
struct DropWaitlistedAdmins: DeletedMigration {}
struct InterestingEventsTable: DeletedMigration {}
struct MiscTables: DeletedMigration {}
struct AddAdminGclid: DeletedMigration {}
struct AppTables: DeletedMigration {}
struct ScheduleFeatures: DeletedMigration {}
struct RequestTables: DeletedMigration {}
struct AddReleaseRequirementPace: DeletedMigration {}
struct SecurityEvents: DeletedMigration {}
// @see https://github.com/gertrude-app/swift/tree/57c4073a
struct MultipleSchemas: DeletedMigration {}
struct SearchPaths: DeletedMigration {}
