import DuetSQL
import Gertie
import MacAppRoute

extension CheckIn_v2: Resolver {
  static func resolve(with input: Input, in context: MacApp.ChildContext) async throws -> Output {
    async let appManifest = getCachedAppIdManifest()
    async let parent = context.child.parent(in: context.db)
    async let browsers = Browser.query().all(in: context.db)
    async let blockedApps = context.child.blockedApps(in: context.db)
    async let keychains = loadRuleKeychains(in: context)
    async let alwaysBlocked = loadAlwaysBlockedRules(in: context)

    let (computerUser, upgradedFrom) = try await syncComputerUser(from: input, in: context)
    slackOnUpgrade(from: input, oldVersion: upgradedFrom, in: context)

    let computer = try await syncComputer(from: input, for: computerUser, in: context)

    let channel = computer.appReleaseChannel
    async let latestRelease = resolveLatestRelease(channel, input.appVersion, context.db)

    async let resolvedFilterSuspension = resolveFilterSuspension(input, computerUser, context)

    async let resolvedUnlockRequests = resolveUnlockRequests(input, computerUser, context)

    try await upsertNamedApps(from: input, in: context)

    let needsIconUpload = try await syncInstalledAppsAndIcons(input, computerUser, context)

    await handleScreenTimeConflict(from: input, for: computerUser, in: context)

    let adminAccountStatus = try await resolveAdminAccountStatus(for: parent, in: context)

    var resolvedKeychains = try await keychains
    filterLegacyIncompatibleRegexKeys(in: &resolvedKeychains, appVersion: input.appVersion)

    return try await Output(
      adminAccountStatus: adminAccountStatus,
      appManifest: appManifest,
      keychains: resolvedKeychains,
      latestRelease: latestRelease,
      updateReleaseChannel: channel,
      userData: .init(
        id: context.child.id.rawValue,
        token: context.token.value.rawValue,
        deviceId: computerUser.id.rawValue,
        name: context.child.name,
        keyloggingEnabled: context.child.keyloggingEnabled,
        screenshotsEnabled: context.child.screenshotsEnabled,
        screenshotFrequency: context.child.screenshotsFrequency,
        screenshotSize: context.child.screenshotsResolution,
        downtime: context.child.downtime,
        blockedApps: blockedApps.map(\.blockedApp),
        filteringDisabled: context.child.filteringDisabled ? true : false,
        connectedAt: computerUser.createdAt,
      ),
      browsers: browsers.map(\.match),
      resolvedFilterSuspension: resolvedFilterSuspension,
      resolvedUnlockRequests: resolvedUnlockRequests,
      trustedTime: get(dependency: \.date.now).timeIntervalSince1970,
      needsIconUpload: needsIconUpload,
      alwaysBlocked: alwaysBlocked.isEmpty ? nil : alwaysBlocked,
    )
  }
}

private extension CheckIn_v2 {
  // @see ./docs/notes/001-regex-keys-macapp.md for context
  static let lenientDecodeMacAppVersion: Semver = "2.9.3"
  static let iconRefreshInterval: TimeInterval = .days(90)

  static func loadRuleKeychains(
    in context: MacApp.ChildContext,
  ) async throws -> [RuleKeychain] {
    var keychains = try await ruleKeychains(for: context.child.id, in: context.db)
    try await self.appendAutoIncludedKeychain(to: &keychains, in: context)
    return keychains
  }

  static func filterLegacyIncompatibleRegexKeys(
    in keychains: inout [RuleKeychain],
    appVersion: String,
  ) {
    if let semver = Semver(appVersion), semver >= lenientDecodeMacAppVersion {
      return
    }
    keychains = keychains.map { keychain in
      let kept = keychain.keys.filter { entry in
        guard case .domainRegex(let pattern, _) = entry.key else {
          return true
        }
        return self.legacyDomainRegexCompatible(pattern.string)
      }
      return RuleKeychain(id: keychain.id, schedule: keychain.schedule, keys: kept)
    }
  }

  static func legacyDomainRegexCompatible(_ pattern: String) -> Bool {
    pattern.contains("*") &&
      Gertie.Key.Domain(pattern.replacingOccurrences(of: "*", with: "a")) != nil
  }

  static func appendAutoIncludedKeychain(
    to keychains: inout [RuleKeychain],
    in context: MacApp.ChildContext,
  ) async throws {
    guard !keychains.isEmpty, keychains.allSatisfy(\.keys.isEmpty) == false else {
      return
    }

    let autoId = context.env.get("AUTO_INCLUDED_KEYCHAIN_ID")
      .flatMap(UUID.init(uuidString:)) ?? context.uuid()
    guard let autoKeychain = try? await context.db.find(Keychain.Id(autoId)) else {
      return
    }

    let autoKeys = try await autoKeychain.keys(in: context.db)
    keychains.append(.init(
      id: autoId,
      keys: autoKeys.map { .init(id: $0.id.rawValue, key: $0.key) },
    ))
  }

  static func syncComputerUser(
    from input: Input,
    in context: MacApp.ChildContext,
  ) async throws -> (computerUser: ComputerUser, oldAppVersion: String?) {
    var computerUser = try await context.computerUser()
    let oldVersion: String?

    if !input.appVersion.isEmpty, input.appVersion != computerUser.appVersion {
      oldVersion = computerUser.appVersion
      computerUser.appVersion = input.appVersion
      try await context.db.update(computerUser)
    } else {
      oldVersion = nil
    }

    if let userIsAdmin = input.userIsAdmin,
       computerUser.isAdmin != userIsAdmin {
      computerUser.isAdmin = userIsAdmin
      try await context.db.update(computerUser)
    }

    return (computerUser, oldVersion)
  }

  static func slackOnUpgrade(
    from input: Input,
    oldVersion: String?,
    in context: MacApp.ChildContext,
  ) {
    guard let oldVersion, !input.appVersion.isEmpty else {
      return
    }

    Task {
      let parent = try await context.child.parent(in: context.db)
      await get(dependency: \.slack).internal(
        .macosLogs,
        """
        Mac app updated for child *\(context.child.name)*
        Parent: \(parent.adminSiteLink(.slack))
        Versions: `\(oldVersion)` -> `\(input.appVersion)`
        """,
      )
    }
  }

  static func syncComputer(
    from input: Input,
    for computerUser: ComputerUser,
    in context: MacApp.ChildContext,
  ) async throws -> Computer {
    var computer = try await computerUser.computer(in: context.db)

    if let filterVersionSemver = input.filterVersion,
       let filterVersion = Semver(filterVersionSemver),
       filterVersion != computer.filterVersion {
      computer.filterVersion = filterVersion
      try await context.db.update(computer)
    }

    if let osVersionSemver = input.osVersion,
       let osVersion = Semver(osVersionSemver),
       osVersion != computer.osVersion {
      computer.osVersion = osVersion
      try await context.db.update(computer)
    }

    return computer
  }

  static func resolveFilterSuspension(
    _ input: Input,
    _ computerUser: ComputerUser,
    _ context: MacApp.ChildContext,
  ) async throws -> ResolvedFilterSuspension? {
    guard let suspensionReqId = input.pendingFilterSuspension,
          let resolved = try? await MacApp.SuspendFilterRequest.query()
          .where(.id == suspensionReqId)
          .where(.computerUserId == computerUser.id)
          .where(.status != .enum(RequestStatus.pending))
          .first(in: context.db)
    else {
      return nil
    }

    return .init(
      id: resolved.id.rawValue,
      decision: resolved.decision ?? .rejected,
      comment: resolved.responseComment,
    )
  }

  static func resolveUnlockRequests(
    _ input: Input,
    _ computerUser: ComputerUser,
    _ context: MacApp.ChildContext,
  ) async throws -> [ResolvedUnlockRequest]? {
    guard let unlockIds = input.pendingUnlockRequests, !unlockIds.isEmpty else {
      return nil
    }

    let resolved = try await UnlockRequest.query()
      .where(.id |=| unlockIds)
      .where(.computerUserId == computerUser.id)
      .where(.status != .enum(RequestStatus.pending))
      .all(in: context.db)

    guard !resolved.isEmpty else {
      return nil
    }

    return resolved.map { .init(
      id: $0.id.rawValue,
      status: $0.status,
      target: $0.target ?? "",
      comment: $0.responseComment,
    ) }
  }

  static func upsertNamedApps(
    from input: Input,
    in context: MacApp.ChildContext,
  ) async throws {
    guard let namedApps = input.namedApps, !namedApps.isEmpty else {
      return
    }

    let identifiedRows = try await context.db.customQuery(IdentifiedBundleIds.self)
    let identifiedBundleIds = Set(identifiedRows.map(\.bundleId))
    let apps = self.namedApps(from: namedApps, identifiedBundleIds: identifiedBundleIds)

    guard !apps.isEmpty else {
      return
    }

    try await context.db.upsert(
      apps,
      conflictOn: [.bundleId],
      do: .update(set: [.bundleName, .localizedName, .launchable]),
    )
  }

  static func namedApps(
    from namedApps: [RunningApp],
    identifiedBundleIds: Set<String>,
  ) -> [UnidentifiedApp] {
    var apps: [UnidentifiedApp] = []

    for var namedApp in namedApps.uniqued(on: \.bundleId) {
      guard !identifiedBundleIds.contains(namedApp.bundleId) else { continue }
      namedApp.dbPrepare()
      apps.append(UnidentifiedApp(
        bundleId: namedApp.bundleId,
        bundleName: namedApp.bundleName,
        localizedName: namedApp.localizedName,
        launchable: namedApp.launchable,
      ))
    }

    return apps
  }

  static func syncInstalledAppsAndIcons(
    _ input: Input,
    _ computerUser: ComputerUser,
    _ context: MacApp.ChildContext,
  ) async throws -> [String]? {
    try await self.syncInstalledApps(
      from: input.installedApps,
      for: computerUser,
      in: context,
    )
  }

  static func syncInstalledApps(
    from installedApps: [InstalledAppInfo]?,
    for computerUser: ComputerUser,
    in context: MacApp.ChildContext,
  ) async throws -> [String]? {
    guard let installedApps, !installedApps.isEmpty else {
      return nil
    }

    let payload = self.catalogedAppPayload(from: installedApps)
    guard !payload.apps.isEmpty else {
      return nil
    }

    let upserted = try await context.db.upsert(
      payload.apps,
      conflictOn: [.bundleId],
      do: .update(set: [.name, .category, .updatedAt]),
      returning: [.id, .bundleId, .iconContentHash, .iconUploadedAt, .iconSourceAppVersion],
      as: CatalogedAppIconInfo.self,
    )

    if !upserted.isEmpty {
      try await self.replaceInstalledApps(upserted, for: computerUser, in: context)
    }

    let iconsNeeded = upserted.compactMap { row in
      let clientHash = payload.hashLookup[row.bundleId]
      let clientAppVersion = payload.appVersionLookup[row.bundleId]
      return self.needsIconUpload(
        row,
        clientHash: clientHash,
        clientAppVersion: clientAppVersion,
      ) ? row.bundleId : nil
    }
    return iconsNeeded.isEmpty ? nil : iconsNeeded
  }

  static func catalogedAppPayload(
    from installedApps: [InstalledAppInfo],
  ) -> (
    apps: [CatalogedApp],
    hashLookup: [String: String],
    appVersionLookup: [String: String],
  ) {
    var apps: [CatalogedApp] = []
    var hashLookup: [String: String] = [:]
    var appVersionLookup: [String: String] = [:]

    for app in installedApps.uniqued(on: \.bundleId) {
      apps.append(CatalogedApp(
        bundleId: app.bundleId,
        name: app.name,
        category: app.category,
      ))
      hashLookup[app.bundleId] = app.iconContentHash
      if let appVersion = app.appVersion {
        appVersionLookup[app.bundleId] = appVersion
      }
    }

    return (apps, hashLookup, appVersionLookup)
  }

  static func needsIconUpload(
    _ row: CatalogedAppIconInfo,
    clientHash: String?,
    clientAppVersion: String?,
  ) -> Bool {
    guard let serverHash = row.iconContentHash,
          let iconUploadedAt = row.iconUploadedAt else {
      return true
    }
    guard serverHash != clientHash else {
      return false
    }
    guard get(dependency: \.date.now).timeIntervalSince(iconUploadedAt) >= self.iconRefreshInterval
    else {
      return false
    }
    guard let clientAppVersion,
          let comparison = LooseAppVersion.compare(clientAppVersion, row.iconSourceAppVersion)
    else {
      return row.iconSourceAppVersion == nil
    }
    return comparison == .orderedDescending
  }

  static func replaceInstalledApps(
    _ upserted: [CatalogedAppIconInfo],
    for computerUser: ComputerUser,
    in context: MacApp.ChildContext,
  ) async throws {
    try await InstalledMacApp.query()
      .where(.childId == computerUser.childId .&& .computerId == computerUser.computerId)
      .delete(in: context.db, force: true)
    try await context.db.create(upserted.map { row in
      InstalledMacApp(
        childId: computerUser.childId,
        computerId: computerUser.computerId,
        macAppId: row.id,
      )
    })
  }

  static func handleScreenTimeConflict(
    from input: Input,
    for computerUser: ComputerUser,
    in context: MacApp.ChildContext,
  ) async {
    if input.screentimeConflictDetected == true {
      let bgTask = await logScreenTimeConflict(computerUser: computerUser, in: context)
      if context.env.mode == .test {
        await bgTask.value
      }
    } else if input.screentimeConflictDetected == false {
      let bgTask = Task {
        await clearScreenTimeAnnouncement(computerUserId: computerUser.id, in: context)
      }
      if context.env.mode == .test {
        await bgTask.value
      }
    }
  }

  static func resolveAdminAccountStatus(
    for parent: Parent,
    in context: MacApp.ChildContext,
  ) async throws -> AdminAccountStatus {
    let now = get(dependency: \.date.now)
    let billing = try await parent.billingAccountSnapshot(in: context.db, at: now)
    return billing.macAppAccessStatus
  }
}

// helpers

func loadAlwaysBlockedRules(
  in context: MacApp.ChildContext,
) async throws -> [BlockRule] {
  async let childGroups = ChildAlwaysBlockedGroup.query()
    .where(.childId == context.child.id)
    .all(in: context.db)
  async let customRules = ChildAlwaysBlockedRule.query()
    .where(.childId == context.child.id)
    .all(in: context.db)

  let groupIds = try await childGroups.map(\.groupId)
  let groupRules = groupIds.isEmpty ? [] : try await AlwaysBlockedRule.query()
    .where(.groupId |=| groupIds)
    .all(in: context.db)

  let rules = try await groupRules.map(\.rule) + customRules.map(\.rule)
  // filtering-disabled children opted into monitoring-only, so sni enforcement is moot
  if context.child.filteringDisabled { return rules }
  // try to prevent sni obfuscation/hiding, which interferes with hostname detection
  return rules + [.hostnameOrSubdomain(value: "cloudflare-ech.com")]
}

func ruleKeychains(
  for childId: Child.Id,
  in db: any DuetSQL.Client,
) async throws -> [RuleKeychain] {
  let childKeychains = try await ChildKeychain.query()
    .where(.childId == childId)
    .all(in: db)
  guard !childKeychains.isEmpty else { return [] }

  let keychainIds = childKeychains.map(\.keychainId)
  async let keychainsAsync = Keychain.query()
    .where(.id |=| keychainIds)
    .all(in: db)
  async let keysAsync = Key.query()
    .where(.keychainId |=| keychainIds)
    .all(in: db)

  let keychains = try await keychainsAsync
  let keysByKeychain = try await Dictionary(grouping: keysAsync, by: \.keychainId)
  return keychains.map { keychain in
    .init(
      id: keychain.id.rawValue,
      schedule: childKeychains.first { $0.keychainId == keychain.id }?.schedule,
      keys: (keysByKeychain[keychain.id] ?? [])
        .map { .init(id: $0.id.rawValue, key: $0.key) },
    )
  }
}

func resolveLatestRelease(
  _ channel: ReleaseChannel,
  _ currentAppVersion: String,
  _ db: any Client,
) async throws -> CheckIn_v2.LatestRelease {
  var query = Release.query().orderBy(.semver, .asc)

  // special case, bug in 2.7.0/1 was fixed by a db change
  // to screenshot rate, so don't force them to update
  // but people behind 2.7.x should go up to >=2.7.2
  // delete next time we ship a version we want all to upgrade to
  if currentAppVersion == "2.7.0" || currentAppVersion == "2.7.1" {
    query = query.where(.semver != "2.7.2")
  }

  let releases = try await query.all(in: db)
  let hidden = AppcastRoute.hiddenReleases(forRequestingAppVersion: currentAppVersion)

  let currentSemver = Semver(currentAppVersion)!
  var latest = CheckIn_v2.LatestRelease(semver: currentSemver.string)

  for release in releases {
    if currentSemver.isBehind(release),
       release.channel.isAtLeastAsStable(as: channel),
       !hidden.contains(release.semver) {
      latest.semver = release.semver
      if let pace = release.requirementPace, latest.pace == nil {
        latest.pace = .init(
          nagOn: release.createdAt.advanced(by: .days(pace)),
          requireOn: release.createdAt.advanced(by: .days(pace * 2)),
        )
      }
    }
  }

  return latest
}

extension RunningApp {
  mutating func dbPrepare() {
    if self.bundleName == self.bundleId {
      self.bundleName = nil
    }
    if self.localizedName == self.bundleId {
      self.localizedName = nil
    }
    if self.localizedName != nil, self.localizedName == self.bundleName {
      self.localizedName = nil
    }
  }
}

func logScreenTimeConflict(
  computerUser: ComputerUser,
  in context: MacApp.ChildContext,
) async -> Task<Void, Never> {
  let bgTask = Task {
    let fourteenDaysAgo = get(dependency: \.date.now) - .days(14)
    let recentEvents = try? await InterestingEvent.query()
      .where(.eventId == "3c86deaa")
      .where(.computerUserId == computerUser.id)
      .where(.createdAt >= fourteenDaysAgo)
      .all(in: context.db)

    if recentEvents?.isEmpty == true,
       let computer = try? await computerUser.computer(in: context.db),
       let parent = try? await context.child.parent(in: context.db) {
      let computerName = computer.customName ?? computer.modelIdentifier
      let parentLink = AdminLink().slack(to: .parent(parent.id), text: parent.email.rawValue)
      let msg = "New Screen Time conflict detected for \(parentLink), child: `\(context.child.name)`, computer: `\(computerName)`"
      await get(dependency: \.slack).internal(.info, msg)
    }

    _ = try? await context.db.create(InterestingEvent(
      eventId: "3c86deaa",
      kind: "event",
      context: "macapp",
      computerUserId: computerUser.id,
      detail: "screentime conflict reported in check in",
    ))
    await notifyScreenTimeConflict(computerUser: computerUser, in: context)
  }
  return bgTask
}

struct ParentWarningAnnouncement: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    var stmt = SQL.Statement("""
      SELECT da.id, c.\(Child.columnName(.parentId))
      FROM \(DashAnnouncement.tableName) da
      JOIN \(Child.tableName) c
        ON c.\(Child.columnName(.parentId)) = da.\(DashAnnouncement.columnName(.parentId))
      WHERE c.id =
    """)
    stmt.components.append(.binding(bindings[0]))
    stmt.components
      .append(.sql(" AND da.\(DashAnnouncement.columnName(.kind)) = 'warning' LIMIT 1"))
    return stmt
  }

  var id: DashAnnouncement.Id
  var parentId: Parent.Id
}

struct CatalogedAppIconInfo: Decodable, Sendable {
  var id: CatalogedApp.Id
  var bundleId: String
  var iconContentHash: String?
  var iconUploadedAt: Date?
  var iconSourceAppVersion: String?
}

enum LooseAppVersion {
  static func compare(_ lhs: String, _ rhs: String?) -> ComparisonResult? {
    let lhs = lhs.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !lhs.isEmpty else { return nil }
    guard let rhs = rhs?.trimmingCharacters(in: .whitespacesAndNewlines),
          !rhs.isEmpty else {
      return .orderedDescending
    }
    guard let lhsParts = parts(lhs), let rhsParts = parts(rhs) else {
      return lhs == rhs ? .orderedSame : .orderedDescending
    }
    for i in 0 ..< max(lhsParts.count, rhsParts.count) {
      let lhs = i < lhsParts.count ? lhsParts[i] : 0
      let rhs = i < rhsParts.count ? rhsParts[i] : 0
      if lhs < rhs { return .orderedAscending }
      if lhs > rhs { return .orderedDescending }
    }
    return .orderedSame
  }

  private static func parts(_ version: String) -> [Int]? {
    let trimmed = version.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    let candidate = trimmed
      .split(whereSeparator: { $0.isWhitespace || $0 == "(" })
      .first?
      .drop { $0 == "v" || $0 == "V" } ?? ""
    let parts = candidate
      .split(separator: ".", omittingEmptySubsequences: false)
      .map { segment -> Int? in
        let digits = segment.prefix { $0.isNumber }
        return digits.isEmpty ? nil : Int(digits)
      }
    guard !parts.isEmpty, parts.allSatisfy({ $0 != nil }) else {
      return nil
    }
    return parts.compactMap(\.self)
  }
}

func clearScreenTimeAnnouncement(
  computerUserId: ComputerUser.Id,
  in context: MacApp.ChildContext,
) async {
  do {
    let results = try await context.db.customQuery(
      ParentWarningAnnouncement.self,
      withBindings: [.uuid(context.child.id.rawValue)],
    )

    guard let result = results.first else {
      // no announcement to clear, bail
      return
    }

    let children = try await Child.query()
      .where(.parentId == result.parentId)
      .all(in: context.db)

    let otherComputerUserIds = try await children
      .concurrentMap { try await $0.computerUsers(in: context.db) }
      .flatMap(\.self)
      .map(\.id)
      .filter { $0 != computerUserId }

    if !otherComputerUserIds.isEmpty {
      let oneDayAgo = get(dependency: \.date.now) - .days(1)
      let numRecentConflictEvents = try await InterestingEvent.query()
        .where(.computerUserId |=| otherComputerUserIds)
        .where(.eventId |=| ["3c86deaa", "933aa385"])
        .where(.createdAt >= oneDayAgo)
        .count(in: context.db)

      if numRecentConflictEvents > 0 {
        // likely another child/computer has the problem, don't clear
        return
      }
    }

    try await context.db.delete(DashAnnouncement.self, byId: result.id)
  } catch {
    await get(dependency: \.slack).error(
      "Failed to clear Screen Time conflict announcement: \(error)",
    )
  }
}
