import DuetSQL
import Gertie
import GertieBlocker

extension DashAnnouncement: Model {
  public static let schemaName = "parent"
  public static let tableName = "dash_announcements"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .kind: .string(self.kind.rawValue)
    case .icon: .varchar(self.icon)
    case .html: .string(self.html)
    case .action: .json(self.action?.toPostgresJson)
    case .createdAt: .date(self.createdAt)
    case .deletedAt: .date(self.deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .kind: .string(self.kind.rawValue),
      .icon: .varchar(self.icon),
      .html: .string(self.html),
      .action: .json(self.action?.toPostgresJson),
      .createdAt: .currentTimestamp,
      .deletedAt: .date(self.deletedAt),
    ]
  }
}

extension BlockerApp.BlockRule: Model {
  public static let schemaName = "blocker_app"
  public static let tableName = "block_rules"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .deviceId: .uuid(self.deviceId)
    case .rule: .json(self.rule.toPostgresJson)
    case .groupId: .uuid(self.groupId)
    case .comment: .string(self.comment)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .deviceId: .uuid(self.deviceId),
      .rule: .json(self.rule.toPostgresJson),
      .groupId: .uuid(self.groupId),
      .comment: .string(self.comment),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension BlockerApp.SuspendFilterRequest: Model {
  public static let schemaName = "blocker_app"
  public static let tableName = "suspend_filter_requests"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .deviceId: .uuid(self.deviceId)
    case .status: .enum(self.status)
    case .duration: .int(self.duration.rawValue)
    case .requestComment: .string(self.requestComment)
    case .responseComment: .string(self.responseComment)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .deviceId: .uuid(self.deviceId),
      .status: .enum(self.status),
      .duration: .int(self.duration.rawValue),
      .requestComment: .string(self.requestComment),
      .responseComment: .string(self.responseComment),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension BlockerApp.Token: Model {
  public static let schemaName = "blocker_app"
  public static let tableName = "tokens"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .installId: .uuid(self.installId)
    case .value: .uuid(self.value)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .installId: .uuid(self.installId),
      .value: .uuid(self.value),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension Claim: Model {
  public static let schemaName = "child"
  public static let tableName = "claims"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .code: .int(self.code)
    case .intent: .string(self.intent.rawValue)
    case .deviceId: .uuid(self.deviceId)
    case .childId: .uuid(self.childId)
    case .expiresAt: .date(self.expiresAt)
    case .claimedAt: .date(self.claimedAt)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .code: .int(self.code),
      .intent: .string(self.intent.rawValue),
      .deviceId: .uuid(self.deviceId),
      .childId: .uuid(self.childId),
      .expiresAt: .date(self.expiresAt),
      .claimedAt: .date(self.claimedAt),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension IOSDevice: Model {
  public static let schemaName = "child"
  public static let tableName = "ios_devices"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .childId: .uuid(self.childId)
    case .modelIdentifier: .string(self.modelIdentifier)
    case .iosVersion: .string(self.iosVersion)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .childId: .uuid(self.childId),
      .modelIdentifier: .string(self.modelIdentifier),
      .iosVersion: .string(self.iosVersion),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension BlockerApp.Install: Model {
  public static let schemaName = "blocker_app"
  public static let tableName = "installs"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .deviceId: .uuid(self.deviceId)
    case .appVersion: .string(self.appVersion)
    case .webPolicy: .string(self.webPolicy)
    case .isProfileLocked: .bool(self.isProfileLocked)
    case .allowAppRemoval: .bool(self.allowAppRemoval)
    case .allowEraseContentAndSettings: .bool(self.allowEraseContentAndSettings)
    case .allowAppInstallation: .bool(self.allowAppInstallation)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .deviceId: .uuid(self.deviceId),
      .appVersion: .string(self.appVersion),
      .webPolicy: .string(self.webPolicy),
      .isProfileLocked: .bool(self.isProfileLocked),
      .allowAppRemoval: .bool(self.allowAppRemoval),
      .allowEraseContentAndSettings: .bool(self.allowEraseContentAndSettings),
      .allowAppInstallation: .bool(self.allowAppInstallation),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension BlockerApp.Supervision: Model {
  public static let schemaName = "blocker_app"
  public static let tableName = "supervisions"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .deviceId: .uuid(self.deviceId)
    case .udid: .string(self.udid)
    case .supervisedAt: .date(self.supervisedAt)
    case .profileInstalledAt: .date(self.profileInstalledAt)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .deviceId: .uuid(self.deviceId),
      .udid: .string(self.udid),
      .supervisedAt: .date(self.supervisedAt),
      .profileInstalledAt: .date(self.profileInstalledAt),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension PodcastApp.Install: Model {
  public static let schemaName = "podcast_app"
  public static let tableName = "installs"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .deviceId: .uuid(self.deviceId)
    case .appVersion: .string(self.appVersion)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .deviceId: .uuid(self.deviceId),
      .appVersion: .string(self.appVersion),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension PodcastApp.Token: Model {
  public static let schemaName = "podcast_app"
  public static let tableName = "tokens"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .installId: .uuid(self.installId)
    case .value: .uuid(self.value)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .installId: .uuid(self.installId),
      .value: .uuid(self.value),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension MusicApp.Install: Model {
  public static let schemaName = "music_app"
  public static let tableName = "installs"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .deviceId: .uuid(self.deviceId)
    case .appVersion: .string(self.appVersion)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .deviceId: .uuid(self.deviceId),
      .appVersion: .string(self.appVersion),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension MusicApp.Token: Model {
  public static let schemaName = "music_app"
  public static let tableName = "tokens"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .installId: .uuid(self.installId)
    case .value: .uuid(self.value)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .installId: .uuid(self.installId),
      .value: .uuid(self.value),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension MusicApp.Event: Model {
  public static let schemaName = "music_app"
  public static let tableName = "events"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .eventId: .string(self.eventId)
    case .level: .string(self.level.rawValue)
    case .domain: .string(self.domain)
    case .detail: .string(self.detail)
    case .deviceId: .uuid(self.deviceId?.rawValue)
    case .modelIdentifier: .string(self.modelIdentifier)
    case .iosVersion: .string(self.iosVersion)
    case .appVersion: .string(self.appVersion)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .eventId: .string(self.eventId),
      .level: .string(self.level.rawValue),
      .domain: .string(self.domain),
      .detail: .string(self.detail),
      .deviceId: .uuid(self.deviceId?.rawValue),
      .modelIdentifier: .string(self.modelIdentifier),
      .iosVersion: .string(self.iosVersion),
      .appVersion: .string(self.appVersion),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension GertieBlocker.BlockRule: @retroactive PostgresJsonable {}

extension Parent: Model {
  public typealias ColumnName = CodingKeys
  public static let schemaName = "parent"
  public static let tableName = "parents"

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self.self)
    case .email: .string(self.email.rawValue)
    case .password: .string(self.password)
    case .emailVerifiedAt: .date(self.emailVerifiedAt)
    case .gclid: .string(self.gclid)
    case .abTestVariant: .string(self.abTestVariant)
    case .referralCode: .string(self.referralCode)
    case .referredByParentId: .uuid(self.referredByParentId?.rawValue)
    case .timeZone: .string(self.timeZone)
    case .dailyReviewEmail: .bool(self.dailyReviewEmail)
    case .lastReviewEmailAt: .date(self.lastReviewEmailAt)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .email: .string(email.rawValue),
      .password: .string(password),
      .emailVerifiedAt: .date(emailVerifiedAt),
      .gclid: .string(gclid),
      .abTestVariant: .string(abTestVariant),
      .referralCode: .string(referralCode),
      .referredByParentId: .uuid(referredByParentId?.rawValue),
      .timeZone: .string(timeZone),
      .dailyReviewEmail: .bool(dailyReviewEmail),
      .lastReviewEmailAt: .date(lastReviewEmailAt),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension StripeSubscription: Model {
  public typealias ColumnName = CodingKeys
  public static let schemaName = "parent"
  public static let tableName = "stripe_subscriptions"

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .tier: .enum(self.tier)
    case .stripeId: .string(self.stripeId.rawValue)
    case .stripeStatus: .string(self.stripeStatus.rawValue)
    case .currentPeriodEnd: .date(self.currentPeriodEnd)
    case .isLegacyPrice: .bool(self.isLegacyPrice)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .tier: .enum(self.tier),
      .stripeId: .string(self.stripeId.rawValue),
      .stripeStatus: .string(self.stripeStatus.rawValue),
      .currentPeriodEnd: .date(self.currentPeriodEnd),
      .isLegacyPrice: .bool(self.isLegacyPrice),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension BillingIdentity: Model {
  public typealias ColumnName = CodingKeys
  public static let schemaName = "parent"
  public static let tableName = "billing_identities"

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .stripeCustomerId: .string(self.stripeCustomerId?.rawValue)
    case .fullTrialStartedAt: .date(self.fullTrialStartedAt)
    case .lastStripeSubscriptionId: .string(self.lastStripeSubscriptionId?.rawValue)
    case .lastPaidTier: .string(self.lastPaidTier?.rawValue)
    case .trialEmailLifecycle: .string(self.trialEmailLifecycle.rawValue)
    case .isComplimentary: .bool(self.isComplimentary)
    case .legacyAmIapPaidAt: .date(self.legacyAmIapPaidAt)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .stripeCustomerId: .string(self.stripeCustomerId?.rawValue),
      .fullTrialStartedAt: .date(self.fullTrialStartedAt),
      .lastStripeSubscriptionId: .string(self.lastStripeSubscriptionId?.rawValue),
      .lastPaidTier: .string(self.lastPaidTier?.rawValue),
      .trialEmailLifecycle: .string(self.trialEmailLifecycle.rawValue),
      .isComplimentary: .bool(self.isComplimentary),
      .legacyAmIapPaidAt: .date(self.legacyAmIapPaidAt),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension Parent.Notification: Model {
  public static let schemaName = "parent"
  public static let tableName = "notifications"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .methodId: .uuid(self.methodId)
    case .trigger: .string(self.trigger.rawValue)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .methodId: .uuid(self.methodId),
      .trigger: .string(self.trigger.rawValue),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension Parent.DashToken: Model {
  public static let tableName = "dash_tokens"
  public static let schemaName = "parent"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .value: .uuid(self.value)
    case .createdAt: .date(self.createdAt)
    case .deletedAt: .date(self.deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .value: .uuid(self.value),
      .createdAt: .currentTimestamp,
      .deletedAt: .date(self.deletedAt),
    ]
  }
}

extension Parent.NotificationMethod.Config: PostgresJsonable {}

extension Parent.NotificationMethod: Model {
  public static let schemaName = "parent"
  public static let tableName = "notification_methods"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .config: .json(self.config.toPostgresJson)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .config: .json(self.config.toPostgresJson),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension AppCategory: Model {
  public static let schemaName = "macos"
  public static let tableName = "app_categories"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .name: .string(self.name)
    case .slug: .string(self.slug)
    case .description: .string(self.description)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .name: .string(self.name),
      .slug: .string(self.slug),
      .description: .string(self.description),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension AppBundleId: Model {
  public static let schemaName = "macos"
  public static let tableName = "app_bundle_ids"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .bundleId: .string(self.bundleId)
    case .identifiedAppId: .uuid(self.identifiedAppId)
    case .count: .int(self.count)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .bundleId: .string(self.bundleId),
      .identifiedAppId: .uuid(self.identifiedAppId),
      .count: .int(self.count),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension UserBlockedApp: Model {
  public static let schemaName = "child"
  public static let tableName = "blocked_mac_apps"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .identifier: .string(self.identifier)
    case .childId: .uuid(self.childId)
    case .schedule: .json(self.schedule?.toPostgresJson)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .identifier: .string(self.identifier),
      .childId: .uuid(self.childId),
      .schedule: .json(self.schedule?.toPostgresJson),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension ComputerUser: Model {
  public static let schemaName = "child"
  public static let tableName = "computer_users"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .computerId: .uuid(self.computerId)
    case .childId: .uuid(self.childId)
    case .isAdmin: .bool(self.isAdmin)
    case .appVersion: .string(self.appVersion)
    case .fullUsername: .string(self.fullUsername)
    case .numericId: .int(self.numericId)
    case .username: .string(self.username)
    case .updatedAt: .date(self.updatedAt)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .childId: .uuid(self.childId),
      .computerId: .uuid(self.computerId),
      .appVersion: .string(self.appVersion),
      .username: .string(self.username),
      .fullUsername: .string(self.fullUsername),
      .isAdmin: .bool(self.isAdmin),
      .numericId: .int(self.numericId),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension Computer: Model {
  public static let schemaName = "parent"
  public static let tableName = "computers"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .customName: .string(self.customName)
    case .modelIdentifier: .string(self.modelIdentifier)
    case .serialNumber: .string(self.serialNumber)
    case .appReleaseChannel: .enum(self.appReleaseChannel)
    case .filterVersion: .varchar(self.filterVersion?.string)
    case .osVersion: .varchar(self.osVersion?.string)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .customName: .string(self.customName),
      .modelIdentifier: .string(self.modelIdentifier),
      .serialNumber: .string(self.serialNumber),
      .appReleaseChannel: .enum(self.appReleaseChannel),
      .filterVersion: .varchar(self.filterVersion?.string),
      .osVersion: .varchar(self.osVersion?.string),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension IdentifiedApp: Model {
  public static let schemaName = "macos"
  public static let tableName = "identified_apps"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .categoryId: .uuid(self.categoryId)
    case .name: .string(self.name)
    case .slug: .string(self.slug)
    case .launchable: .bool(self.launchable)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .categoryId: .uuid(self.categoryId),
      .name: .string(self.name),
      .slug: .string(self.slug),
      .launchable: .bool(self.launchable),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension Keychain: Model {
  public static let schemaName = "parent"
  public static let tableName = "keychains"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .name: .string(self.name)
    case .description: .string(self.description)
    case .warning: .string(self.warning)
    case .isPublic: .bool(self.isPublic)
    case .rootDomain: .string(self.rootDomain)
    case .brandColor: .string(self.brandColor)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .name: .string(self.name),
      .description: .string(self.description),
      .warning: .string(self.warning),
      .isPublic: .bool(self.isPublic),
      .rootDomain: .string(self.rootDomain),
      .brandColor: .string(self.brandColor),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension Gertie.Key: @retroactive PostgresJsonable {}

extension Key: Model {
  public static let schemaName = "parent"
  public static let tableName = "keys"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .keychainId: .uuid(self.keychainId)
    case .key: .json(self.key.toPostgresJson)
    case .comment: .string(self.comment)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    case .deletedAt: .date(self.deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .keychainId: .uuid(self.keychainId),
      .key: .json(self.key.toPostgresJson),
      .comment: .string(self.comment),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
      .deletedAt: .date(self.deletedAt),
    ]
  }
}

extension KeystrokeLine: Model {
  public static let schemaName = "macapp"
  public static let tableName = "keystroke_lines"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .computerUserId: .uuid(self.computerUserId)
    case .appName: .string(self.appName)
    case .line: .string(self.line)
    case .filterSuspended: .bool(self.filterSuspended)
    case .flagged: .date(self.flagged)
    case .createdAt: .date(self.createdAt)
    case .deletedAt: .date(self.deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .computerUserId: .uuid(self.computerUserId),
      .appName: .string(self.appName),
      .line: .string(self.line),
      .filterSuspended: .bool(self.filterSuspended),
      .flagged: .date(self.flagged),
      .createdAt: .date(self.createdAt),
      .deletedAt: .date(self.deletedAt),
    ]
  }
}

extension Release: Model {
  public static let schemaName = "macapp"
  public static let tableName = "releases"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .semver: .string(self.semver)
    case .channel: .enum(self.channel)
    case .signature: .string(self.signature)
    case .length: .int(self.length)
    case .revision: .string(self.revision.rawValue)
    case .minVersion: .string(self.minVersion)
    case .requirementPace: .int(self.requirementPace)
    case .notes: .string(self.notes)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .semver: .string(self.semver),
      .channel: .enum(self.channel),
      .signature: .string(self.signature),
      .length: .int(self.length),
      .revision: .string(self.revision.rawValue),
      .minVersion: .string(self.minVersion),
      .requirementPace: .int(self.requirementPace),
      .notes: .string(self.notes),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension Screenshot: Model {
  public static let schemaName = "child"
  public static let tableName = "screenshots"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .computerUserId: .uuid(self.computerUserId)
    case .url: .string(self.url)
    case .width: .int(self.width)
    case .height: .int(self.height)
    case .filterSuspended: .bool(self.filterSuspended)
    case .flagged: .date(self.flagged)
    case .createdAt: .date(self.createdAt)
    case .deletedAt: .date(self.deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .computerUserId: .uuid(self.computerUserId),
      .url: .string(self.url),
      .width: .int(self.width),
      .height: .int(self.height),
      .filterSuspended: .bool(self.filterSuspended),
      .flagged: .date(self.flagged),
      .createdAt: .date(self.createdAt),
      .deletedAt: .date(self.deletedAt),
    ]
  }
}

extension AppScope: @retroactive PostgresJsonable {}

extension MacApp.SuspendFilterRequest: Model {
  public static let schemaName = "macapp"
  public static let tableName = "suspend_filter_requests"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .computerUserId: .uuid(self.computerUserId)
    case .status: .enum(self.status)
    case .scope: .json(self.scope.toPostgresJson)
    case .duration: .int(self.duration.rawValue)
    case .requestComment: .string(self.requestComment)
    case .responseComment: .string(self.responseComment)
    case .extraMonitoring: .string(self.extraMonitoring)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .computerUserId: .uuid(self.computerUserId),
      .status: .enum(self.status),
      .scope: .json(self.scope.toPostgresJson),
      .duration: .int(self.duration.rawValue),
      .requestComment: .string(self.requestComment),
      .responseComment: .string(self.responseComment),
      .extraMonitoring: .string(self.extraMonitoring),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension UnlockRequest: Model {
  public static let schemaName = "macapp"
  public static let tableName = "unlock_requests"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .computerUserId: .uuid(self.computerUserId)
    case .status: .enum(self.status)
    case .requestComment: .string(self.requestComment)
    case .responseComment: .string(self.responseComment)
    case .appBundleId: .string(self.appBundleId)
    case .url: .string(self.url)
    case .hostname: .string(self.hostname)
    case .ipAddress: .string(self.ipAddress)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .computerUserId: .uuid(self.computerUserId),
      .status: .enum(self.status),
      .requestComment: .string(self.requestComment),
      .responseComment: .string(self.responseComment),
      .appBundleId: .string(self.appBundleId),
      .url: .string(self.url),
      .hostname: .string(self.hostname),
      .ipAddress: .string(self.ipAddress),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension Child: Model {
  public static let schemaName = "parent"
  public static let tableName = "children"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .name: .string(self.name)
    case .keyloggingEnabled: .bool(self.keyloggingEnabled)
    case .screenshotsEnabled: .bool(self.screenshotsEnabled)
    case .screenshotsResolution: .int(self.screenshotsResolution)
    case .screenshotsFrequency: .int(self.screenshotsFrequency)
    case .showSuspensionActivity: .bool(self.showSuspensionActivity)
    case .filteringDisabled: .bool(self.filteringDisabled)
    case .downtime: .json(self.downtime?.toPostgresJson)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .name: .string(self.name),
      .keyloggingEnabled: .bool(self.keyloggingEnabled),
      .screenshotsEnabled: .bool(self.screenshotsEnabled),
      .screenshotsResolution: .int(self.screenshotsResolution),
      .screenshotsFrequency: .int(self.screenshotsFrequency),
      .showSuspensionActivity: .bool(self.showSuspensionActivity),
      .filteringDisabled: .bool(self.filteringDisabled),
      .downtime: .json(self.downtime?.toPostgresJson),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension ChildKeychain: Model {
  public static let schemaName = "child"
  public static let tableName = "keychains"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .childId: .uuid(self.childId)
    case .keychainId: .uuid(self.keychainId)
    case .schedule: .json(self.schedule?.toPostgresJson)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .childId: .uuid(self.childId),
      .keychainId: .uuid(self.keychainId),
      .schedule: .json(self.schedule?.toPostgresJson),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension RuleSchedule: @retroactive PostgresJsonable {}
extension PlainTimeWindow: @retroactive PostgresJsonable {}
extension DashAnnouncement.Action: PostgresJsonable {}

extension AlwaysBlockedGroup: Model {
  public static let schemaName = "macapp"
  public static let tableName = "always_blocked_groups"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .name: .string(self.name)
    case .description: .string(self.description)
    case .longDescription: .string(self.longDescription)
    case .recommended: .bool(self.recommended)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .name: .string(self.name),
      .description: .string(self.description),
      .longDescription: .string(self.longDescription),
      .recommended: .bool(self.recommended),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension AlwaysBlockedRule: Model {
  public static let schemaName = "macapp"
  public static let tableName = "always_blocked_rules"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .groupId: .uuid(self.groupId)
    case .rule: .json(self.rule.toPostgresJson)
    case .comment: .string(self.comment)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .groupId: .uuid(self.groupId),
      .rule: .json(self.rule.toPostgresJson),
      .comment: .string(self.comment),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension ChildAlwaysBlockedGroup: Model {
  public static let schemaName = "child"
  public static let tableName = "always_blocked_groups"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .childId: .uuid(self.childId)
    case .groupId: .uuid(self.groupId)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .childId: .uuid(self.childId),
      .groupId: .uuid(self.groupId),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension ChildAlwaysBlockedRule: Model {
  public static let schemaName = "child"
  public static let tableName = "always_blocked_rules"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .childId: .uuid(self.childId)
    case .rule: .json(self.rule.toPostgresJson)
    case .comment: .string(self.comment)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .childId: .uuid(self.childId),
      .rule: .json(self.rule.toPostgresJson),
      .comment: .string(self.comment),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension MacAppToken: Model {
  public static let schemaName = "child"
  public static let tableName = "macapp_tokens"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .childId: .uuid(self.childId)
    case .computerUserId: .uuid(self.computerUserId)
    case .value: .uuid(self.value)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    case .deletedAt: .date(self.deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .childId: .uuid(self.childId),
      .computerUserId: .uuid(self.computerUserId),
      .value: .uuid(self.value),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
      .deletedAt: .date(self.deletedAt),
    ]
  }
}

extension InterestingEvent: Model {
  public static let schemaName = "system"
  public static let tableName = "interesting_events"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .eventId: .string(self.eventId)
    case .kind: .string(self.kind)
    case .context: .string(self.context)
    case .computerUserId: .uuid(self.computerUserId)
    case .parentId: .uuid(self.parentId)
    case .detail: .string(self.detail)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .eventId: .string(self.eventId),
      .kind: .string(self.kind),
      .context: .string(self.context),
      .computerUserId: .uuid(self.computerUserId),
      .parentId: .uuid(self.parentId),
      .detail: .string(self.detail),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension MarketingEmailSend: Model {
  public static let schemaName = "parent"
  public static let tableName = "marketing_email_sends"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .campaign: .string(self.campaign)
    case .variant: .string(self.variant)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .campaign: .string(self.campaign),
      .variant: .string(self.variant),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension RouteTelemetry: Model {
  public static let schemaName = "system"
  public static let tableName = "route_telemetry"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .kind: .string(self.kind)
    case .requestId: .string(self.requestId)
    case .domain: .string(self.domain)
    case .operation: .string(self.operation)
    case .durationMs: .int(self.durationMs)
    case .result: .string(self.result.rawValue)
    case .errorId: .varchar(self.errorId)
    case .errorType: .string(self.errorType)
    case .errorMessage: .string(self.errorMessage)
    case .parentId: .uuid(self.parentId)
    case .ipAddress: .string(self.ipAddress)
    case .userAgent: .string(self.userAgent)
    case .numRequestBytes: .int(self.numRequestBytes)
    case .numResponseBytes: .int(self.numResponseBytes)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .kind: .string(self.kind),
      .requestId: .string(self.requestId),
      .domain: .string(self.domain),
      .operation: .string(self.operation),
      .durationMs: .int(self.durationMs),
      .result: .string(self.result.rawValue),
      .errorId: .varchar(self.errorId),
      .errorType: .string(self.errorType),
      .errorMessage: .string(self.errorMessage),
      .parentId: .uuid(self.parentId),
      .ipAddress: .string(self.ipAddress),
      .userAgent: .string(self.userAgent),
      .numRequestBytes: .int(self.numRequestBytes),
      .numResponseBytes: .int(self.numResponseBytes),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension StripeEvent: Model {
  public static let schemaName = "system"
  public static let tableName = "stripe_events"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .json: .string(self.json)
    case .stripeEventId: .string(self.stripeEventId)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .json: .string(self.json),
      .stripeEventId: .string(self.stripeEventId),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension DeletedEntity: Model {
  public static let schemaName = "system"
  public static let tableName = "deleted_entities"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .type: .string(self.type)
    case .reason: .string(self.reason)
    case .data: .string(self.data)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .type: .string(self.type),
      .reason: .string(self.reason),
      .data: .string(self.data),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension Browser: Model {
  public static let schemaName = "macos"
  public static let tableName = "browsers"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .match: .json(self.match.toPostgresJson)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .match: .json(self.match.toPostgresJson),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension UnidentifiedApp: Model {
  public static let schemaName = "macos"
  public static let tableName = "unidentified_apps"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .bundleId: .string(self.bundleId)
    case .bundleName: .string(self.bundleName)
    case .localizedName: .string(self.localizedName)
    case .launchable: .bool(self.launchable)
    case .count: .int(self.count)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .bundleId: .string(self.bundleId),
      .bundleName: .string(self.bundleName),
      .localizedName: .string(self.localizedName),
      .launchable: .bool(self.launchable),
      .count: .int(self.count),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension BrowserMatch: @retroactive PostgresJsonable {}

extension SecurityEvent: Model {
  public static let schemaName = "system"
  public static let tableName = "security_events"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .computerUserId: .uuid(self.computerUserId)
    case .event: .string(self.event)
    case .detail: .string(self.detail)
    case .ipAddress: .string(self.ipAddress)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .computerUserId: .uuid(self.computerUserId),
      .event: .string(self.event),
      .detail: .string(self.detail),
      .ipAddress: .string(self.ipAddress),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension BlockerApp.BlockGroup: Model {
  public static let schemaName = "blocker_app"
  public static let tableName = "block_groups"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .name: .string(self.name)
    case .description: .string(self.description)
    case .longDescription: .string(self.longDescription)
    case .imageSlug: .string(self.imageSlug)
    case .optIn: .bool(self.optIn)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .name: .string(self.name),
      .description: .string(self.description),
      .longDescription: .string(self.longDescription),
      .imageSlug: .string(self.imageSlug),
      .optIn: .bool(self.optIn),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension BlockerApp.DeviceBlockGroup: Model {
  public static let schemaName = "blocker_app"
  public static let tableName = "device_block_groups"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .deviceId: .uuid(self.deviceId)
    case .blockGroupId: .uuid(self.blockGroupId)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .deviceId: .uuid(self.deviceId),
      .blockGroupId: .uuid(self.blockGroupId),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension BlockerApp.WebPolicyDomain: Model {
  public static let schemaName = "blocker_app"
  public static let tableName = "web_policy_domains"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .deviceId: .uuid(self.deviceId)
    case .domain: .string(self.domain)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .deviceId: .uuid(self.deviceId),
      .domain: .string(self.domain),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension PodcastEvent: Model {
  public static let schemaName = "podcast_app"
  public static let tableName = "events"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .eventId: .string(self.eventId)
    case .level: .string(self.level.rawValue)
    case .domain: .string(self.domain)
    case .modelIdentifier: .string(self.modelIdentifier)
    case .appVersion: .string(self.appVersion)
    case .iosVersion: .string(self.iosVersion)
    case .deviceId: .uuid(self.deviceId?.rawValue)
    case .detail: .string(self.detail)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .eventId: .string(self.eventId),
      .level: .string(self.level.rawValue),
      .domain: .string(self.domain),
      .modelIdentifier: .string(self.modelIdentifier),
      .appVersion: .string(self.appVersion),
      .iosVersion: .string(self.iosVersion),
      .deviceId: .uuid(self.deviceId?.rawValue),
      .detail: .string(self.detail),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension IOSEvent: Model {
  public static let schemaName = "blocker_app"
  public static let tableName = "events"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .eventId: .string(self.eventId)
    case .level: .string(self.level.rawValue)
    case .domain: .string(self.domain)
    case .detail: .string(self.detail)
    case .deviceId: .uuid(self.deviceId?.rawValue)
    case .modelIdentifier: .string(self.modelIdentifier)
    case .iosVersion: .string(self.iosVersion)
    case .appVersion: .string(self.appVersion)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .eventId: .string(self.eventId),
      .level: .string(self.level.rawValue),
      .domain: .string(self.domain),
      .detail: .string(self.detail),
      .deviceId: .uuid(self.deviceId?.rawValue),
      .modelIdentifier: .string(self.modelIdentifier),
      .iosVersion: .string(self.iosVersion),
      .appVersion: .string(self.appVersion),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension SuperAdminToken: Model {
  public static let schemaName = "system"
  public static let tableName = "super_admin_tokens"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .value: .uuid(self.value)
    case .createdAt: .date(self.createdAt)
    case .deletedAt: .date(self.deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .value: .uuid(self.value),
      .createdAt: .currentTimestamp,
      .deletedAt: .date(self.deletedAt),
    ]
  }
}

extension AppStore.Review: Model {
  public static let schemaName = "appstore"
  public static let tableName = "reviews"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .appleId: .string(self.appleId)
    case .app: .string(self.app.rawValue)
    case .rating: .int(self.rating)
    case .title: .string(self.title)
    case .body: .string(self.body)
    case .reviewerNickname: .string(self.reviewerNickname)
    case .territory: .varchar(self.territory)
    case .reviewCreatedAt: .date(self.reviewCreatedAt)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .appleId: .string(self.appleId),
      .app: .string(self.app.rawValue),
      .rating: .int(self.rating),
      .title: .string(self.title),
      .body: .string(self.body),
      .reviewerNickname: .string(self.reviewerNickname),
      .territory: .varchar(self.territory),
      .reviewCreatedAt: .date(self.reviewCreatedAt),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension AppStore.RatingSnapshot: Model {
  public static let schemaName = "appstore"
  public static let tableName = "rating_snapshots"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .app: .string(self.app.rawValue)
    case .averageRating: .double(self.averageRating)
    case .totalCount: .int(self.totalCount)
    case .reviewCount: .int(self.reviewCount)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .app: .string(self.app.rawValue),
      .averageRating: .double(self.averageRating),
      .totalCount: .int(self.totalCount),
      .reviewCount: .int(self.reviewCount),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension AppStore.RatingEvent: Model {
  public static let schemaName = "appstore"
  public static let tableName = "rating_events"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .app: .string(self.app.rawValue)
    case .stars: .int(self.stars)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .app: .string(self.app.rawValue),
      .stars: .int(self.stars),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension SmsSend: Model {
  public static let schemaName = "system"
  public static let tableName = "sms_sends"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .trigger: .varchar(self.trigger)
    case .countryCode: .varchar(self.countryCode)
    case .twilioMessageSid: .varchar(self.twilioMessageSid)
    case .numSegments: .int(self.numSegments)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .trigger: .varchar(self.trigger),
      .countryCode: .varchar(self.countryCode),
      .twilioMessageSid: .varchar(self.twilioMessageSid),
      .numSegments: .int(self.numSegments),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension ShortUrl: Model {
  public static let schemaName = "system"
  public static let tableName = "short_urls"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .shortId: .varchar(self.shortId)
    case .target: .string(self.target)
    case .clickCount: .int(self.clickCount)
    case .createdAt: .date(self.createdAt)
    case .deletedAt: .date(self.deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .shortId: .varchar(self.shortId),
      .target: .string(self.target),
      .clickCount: .int(self.clickCount),
      .createdAt: .currentTimestamp,
      .deletedAt: .date(self.deletedAt),
    ]
  }
}

extension CatalogedApp: Model {
  public static let schemaName = "macos"
  public static let tableName = "mac_apps"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .bundleId: .string(self.bundleId)
    case .name: .string(self.name)
    case .category: .string(self.category)
    case .icon: .bytea(self.icon)
    case .iconContentHash: .string(self.iconContentHash)
    case .iconUploadedAt: .date(self.iconUploadedAt)
    case .iconSourceAppVersion: .string(self.iconSourceAppVersion)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .bundleId: .string(self.bundleId),
      .name: .string(self.name),
      .category: .string(self.category),
      .icon: .bytea(self.icon),
      .iconContentHash: .string(self.iconContentHash),
      .iconUploadedAt: .date(self.iconUploadedAt),
      .iconSourceAppVersion: .string(self.iconSourceAppVersion),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension InstalledMacApp: Model {
  public static let schemaName = "child"
  public static let tableName = "installed_mac_apps"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .childId: .uuid(self.childId)
    case .computerId: .uuid(self.computerId)
    case .macAppId: .uuid(self.macAppId)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .childId: .uuid(self.childId),
      .computerId: .uuid(self.computerId),
      .macAppId: .uuid(self.macAppId),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension Music.ApprovedAlbum: Model {
  public static let schemaName = "music"
  public static let tableName = "approved_albums"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .childId: .uuid(self.childId)
    case .appleMusicAlbumId: .string(self.appleMusicAlbumId.rawValue)
    case .title: .string(self.title)
    case .artistName: .string(self.artistName)
    case .artworkUrl: .string(self.artworkUrl)
    case .trackCount: .int(self.trackCount)
    case .showsArtwork: .bool(self.showsArtwork)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .childId: .uuid(self.childId),
      .appleMusicAlbumId: .string(self.appleMusicAlbumId.rawValue),
      .title: .string(self.title),
      .artistName: .string(self.artistName),
      .artworkUrl: .string(self.artworkUrl),
      .trackCount: .int(self.trackCount),
      .showsArtwork: .bool(self.showsArtwork),
      .createdAt: .currentTimestamp,
    ]
  }
}
