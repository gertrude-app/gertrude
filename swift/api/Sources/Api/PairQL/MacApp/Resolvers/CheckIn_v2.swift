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
    async let alwaysBlocked = loadAlwaysBlockedRules(for: context.child.id, in: context.db)

    let computerUser = try await syncComputerUser(from: input, in: context)

    let computer = try await syncComputer(from: input, for: computerUser, in: context)

    let channel = computer.appReleaseChannel
    async let latestRelease = resolveLatestRelease(channel, input.appVersion, context.db)

    async let resolvedFilterSuspension = resolveFilterSuspension(input, computerUser, context)

    async let resolvedUnlockRequests = resolveUnlockRequests(input, computerUser, context)

    try await upsertNamedApps(from: input, in: context)

    let needsIconUpload = try await syncInstalledAppsAndIcons(input, computerUser, context)

    await handleScreenTimeConflict(from: input, for: computerUser, in: context)

    let adminAccountStatus = try await resolveAdminAccountStatus(for: parent, in: context)

    return try await Output(
      adminAccountStatus: adminAccountStatus,
      appManifest: appManifest,
      keychains: keychains,
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
  static func loadRuleKeychains(
    in context: MacApp.ChildContext,
  ) async throws -> [RuleKeychain] {
    var keychains = try await ruleKeychains(for: context.child.id, in: context.db)
    try await self.appendAutoIncludedKeychain(to: &keychains, in: context)
    return keychains
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
  ) async throws -> ComputerUser {
    var computerUser = try await context.computerUser()

    if !input.appVersion.isEmpty, input.appVersion != computerUser.appVersion {
      computerUser.appVersion = input.appVersion
      try await context.db.update(computerUser)
    }

    if let userIsAdmin = input.userIsAdmin,
       computerUser.isAdmin != userIsAdmin {
      computerUser.isAdmin = userIsAdmin
      try await context.db.update(computerUser)
    }

    return computerUser
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
    let bindings = self.namedAppBindings(from: namedApps, identifiedBundleIds: identifiedBundleIds)

    guard !bindings.isEmpty else {
      return
    }

    _ = try await context.db.customQuery(
      UpsertNamedApps.self,
      withBindings: bindings,
    )
  }

  static func namedAppBindings(
    from namedApps: [RunningApp],
    identifiedBundleIds: Set<String>,
  ) -> [Postgres.Data] {
    var bindings: [Postgres.Data] = []

    for var namedApp in namedApps.uniqued(on: \.bundleId) {
      guard !identifiedBundleIds.contains(namedApp.bundleId) else { continue }
      namedApp.dbPrepare()
      bindings.append(.string(namedApp.bundleId))
      bindings.append(.string(namedApp.bundleName))
      bindings.append(.string(namedApp.localizedName))
      bindings.append(.bool(namedApp.launchable))
    }

    return bindings
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
    guard !payload.bindings.isEmpty else {
      return nil
    }

    let upserted = try await context.db.customQuery(
      UpsertCatalogedApps.self,
      withBindings: payload.bindings,
    )

    if !upserted.isEmpty {
      try await self.replaceInstalledApps(upserted, for: computerUser, in: context)
    }

    let iconsNeeded = upserted.compactMap { row in
      let clientHash = payload.hashLookup[row.bundleId]
      return row.iconContentHash == nil || row.iconContentHash != clientHash ? row.bundleId : nil
    }
    return iconsNeeded.isEmpty ? nil : iconsNeeded
  }

  static func catalogedAppPayload(
    from installedApps: [InstalledAppInfo],
  ) -> (bindings: [Postgres.Data], hashLookup: [String: String]) {
    var bindings: [Postgres.Data] = []
    var hashLookup: [String: String] = [:]

    for app in installedApps.uniqued(on: \.bundleId) {
      bindings.append(.uuid(UUID()))
      bindings.append(.string(app.bundleId))
      bindings.append(.string(app.name))
      bindings.append(.string(app.category))
      hashLookup[app.bundleId] = app.iconContentHash
    }

    return (bindings, hashLookup)
  }

  static func replaceInstalledApps(
    _ upserted: [UpsertCatalogedApps],
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
        macAppId: .init(row.id),
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
    let subscription = try await parent.subscription(in: context.db)
    return switch Plan(subscription: subscription) {
    case .full(.trialExpired), .full(.overdue):
      .needsAttention
    case .full:
      .active
    case .light, .free:
      .inactive
    }
  }
}

// helpers

func loadAlwaysBlockedRules(
  for childId: Child.Id,
  in db: any DuetSQL.Client,
) async throws -> [BlockRule] {
  async let childGroups = ChildAlwaysBlockedGroup.query()
    .where(.childId == childId)
    .all(in: db)
  async let customRules = ChildAlwaysBlockedRule.query()
    .where(.childId == childId)
    .all(in: db)

  let groupIds = try await childGroups.map(\.groupId)
  let groupRules = groupIds.isEmpty ? [] : try await AlwaysBlockedRule.query()
    .where(.groupId |=| groupIds)
    .all(in: db)

  return try await groupRules.map(\.rule) + customRules.map(\.rule)
}

// TODO: this is major N+1 territory, write a custom query w/ join for perf
// @see also userKeychainSummaries(for:in:)
func ruleKeychains(
  for childId: Child.Id,
  in db: any DuetSQL.Client,
) async throws -> [RuleKeychain] {
  let childKeychains = try await ChildKeychain.query()
    .where(.childId == childId)
    .all(in: db)
  let keychains = try await Keychain.query()
    .where(.id |=| childKeychains.map(\.keychainId))
    .all(in: db)
  return try await keychains.concurrentMap { keychain in
    let keys = try await keychain.keys(in: db)
    return .init(
      id: keychain.id.rawValue,
      schedule: childKeychains.first { $0.keychainId == keychain.id }?.schedule,
      keys: keys.map { .init(id: $0.id.rawValue, key: $0.key) },
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

  let currentSemver = Semver(currentAppVersion)!
  var latest = CheckIn_v2.LatestRelease(semver: currentSemver.string)

  for release in releases {
    if currentSemver.isBehind(release),
       release.channel.isAtLeastAsStable(as: channel) {
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

struct UpsertNamedApps: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    typealias UA = UnidentifiedApp
    var stmt = SQL.Statement("""
      INSERT INTO \(table: UA.self) (
        id,
        \(UA.columnName(.bundleId)),
        \(UA.columnName(.bundleName)),
        \(UA.columnName(.localizedName)),
        \(UA.columnName(.launchable)),
        \(UA.columnName(.count)),
        created_at
      ) VALUES (
    """)
    for i in (0 ..< bindings.count).striding(by: 4) {
      // id
      stmt.components.append(.sql("'\(UUID().lowercased)', "))
      // bundle id
      stmt.components.append(.binding(bindings[i]))
      // bundle name
      stmt.components.append(.sql(", "))
      stmt.components.append(.binding(bindings[i + 1]))
      // localized name
      stmt.components.append(.sql(", "))
      stmt.components.append(.binding(bindings[i + 2]))
      // launchable
      stmt.components.append(.sql(", "))
      stmt.components.append(.binding(bindings[i + 3]))
      // count, created_at
      stmt.components.append(.sql(", 1, CURRENT_TIMESTAMP), ("))
    }
    stmt.components.removeLast()
    stmt.components.append(.sql(", 1, CURRENT_TIMESTAMP)\n"))
    stmt.components.append(.sql("""
      ON CONFLICT (\(UA.columnName(.bundleId)))
      DO UPDATE SET
        \(UA.columnName(.bundleName))    = EXCLUDED.\(UA.columnName(.bundleName)),
        \(UA.columnName(.localizedName)) = EXCLUDED.\(UA.columnName(.localizedName)),
        \(UA.columnName(.launchable))    = EXCLUDED.\(UA.columnName(.launchable))
    """))
    return stmt
  }
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

struct UpsertCatalogedApps: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    typealias CA = CatalogedApp
    var stmt = SQL.Statement("""
      INSERT INTO \(table: CA.self) (
        \(CA.columnName(.id)),
        \(CA.columnName(.bundleId)),
        \(CA.columnName(.name)),
        \(CA.columnName(.category)),
        created_at,
        updated_at
      ) VALUES (
    """)
    for i in stride(from: 0, to: bindings.count, by: 4) {
      stmt.components.append(.binding(bindings[i]))
      stmt.components.append(.sql(", "))
      stmt.components.append(.binding(bindings[i + 1]))
      stmt.components.append(.sql(", "))
      stmt.components.append(.binding(bindings[i + 2]))
      stmt.components.append(.sql(", "))
      stmt.components.append(.binding(bindings[i + 3]))
      stmt.components.append(.sql(", CURRENT_TIMESTAMP, CURRENT_TIMESTAMP), ("))
    }
    stmt.components.removeLast()
    stmt.components.append(.sql(", CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)\n"))
    stmt.components.append(.sql("""
      ON CONFLICT (\(CA.columnName(.bundleId)))
      DO UPDATE SET
        \(CA.columnName(.name))     = EXCLUDED.\(CA.columnName(.name)),
        \(CA.columnName(.category)) = EXCLUDED.\(CA.columnName(.category)),
        \(CA.columnName(.updatedAt)) = CURRENT_TIMESTAMP
      RETURNING
        \(CA.columnName(.id)),
        \(CA.columnName(.bundleId)),
        \(CA.columnName(.iconContentHash))
    """))
    return stmt
  }

  var id: UUID
  var bundleId: String
  var iconContentHash: String?
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
