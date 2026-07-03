import Dependencies
import DependenciesMacros
import Foundation
import GertieBlocker
import IOSRoute
import LibCore
import os.log

@DependencyClient
public struct SharedStorageClient: Sendable {
  public var loadAccountConnection: @Sendable () -> ChildIOSDeviceData_v2?
  public var saveAccountConnection: @Sendable (ChildIOSDeviceData_v2) -> Void

  public var loadProtectionMode: @Sendable () -> ProtectionMode?
  public var saveProtectionMode: @Sendable (ProtectionMode) -> Void

  public var loadDisabledBlockGroupIds: @Sendable () -> [UUID]?
  public var saveDisabledBlockGroupIds: @Sendable ([UUID]) -> Void
  public var loadAllBlockGroups: @Sendable () -> [GetBlockGroups.BlockGroupInfo]?
  public var saveAllBlockGroups: @Sendable ([GetBlockGroups.BlockGroupInfo]) -> Void

  public var loadFirstLaunchDate: @Sendable () -> Date?
  public var saveFirstLaunchDate: @Sendable (Date) -> Void

  public var loadDebugLogs: @Sendable () -> [String]?
  public var saveDebugLogs: @Sendable ([String]) -> Void

  public var loadPendingSupervisionCode: @Sendable () -> CreateSupervisionClaimCode.Output?
  public var savePendingSupervisionCode: @Sendable (CreateSupervisionClaimCode.Output) -> Void
  public var clearPendingSupervisionCode: @Sendable () -> Void

  public var loadDismissedCrossPromoIds: @Sendable () -> [String]?
  public var saveDismissedCrossPromoIds: @Sendable ([String]) -> Void
  public var loadCrossPromoLastShownAt: @Sendable () -> Date?
  public var saveCrossPromoLastShownAt: @Sendable (Date) -> Void

  public var loadSuspensionExpiration: @Sendable () -> Date?
  public var saveSuspensionExpiration: @Sendable (Date) -> Void
  public var clearSuspensionExpiration: @Sendable () -> Void
  public var loadScreenshotLastSaved: @Sendable () -> Date?
  public var saveScreenshotLastSaved: @Sendable (Date) -> Void

  public var migrateLegacyData: @Sendable () async -> Bool = { false }
}

@DependencyClient
public struct SharedStorageReaderClient: Sendable {
  public var loadAccountConnection: @Sendable () -> ChildIOSDeviceData_v2?
  public var loadProtectionMode: @Sendable () -> ProtectionMode?
  public var loadDisabledBlockGroupIds: @Sendable () -> [UUID]?
  public var loadFirstLaunchDate: @Sendable () -> Date?
  public var loadDebugLogs: @Sendable () -> [String]?
  public var loadSuspensionExpiration: @Sendable () -> Date?
  public var loadScreenshotLastSaved: @Sendable () -> Date?
}

package enum Key: String {
  case accountConnection_v2 = "v1.7.0--account-connection-v2"
  case debugLogs = "v1.5.0--debug-logs"
  case legacyProtectionMode = "ProtectionMode.v1.3.0"
  case protectionMode = "v1.5.0--protection-mode"
  case disabledBlockGroups = "disabledBlockGroups.v1.3.0"
  case disabledBlockGroupIds = "v1.8.0--disabled-block-group-ids"
  case allBlockGroups = "v1.8.0--all-block-groups"
  case legacyV1StorageKey = "blockRules.v1"
  case firstLaunchDate
  case pendingSupervisionCode = "v1.7.0--pending-supervision-code"
  case dismissedCrossPromoIds = "v1.9.0--dismissed-cross-promo-ids"
  case crossPromoLastShownAt = "v1.9.0--cross-promo-last-shown-at"
  case suspensionExpiration = "v1.10.0--suspension-expiration"
  case screenshotLastSaved = "v1.10.0--screenshot-last-saved"
}

extension SharedStorageClient: DependencyKey {
  public static var liveValue: SharedStorageClient {
    let reader = SharedStorageReaderClient.liveValue
    return .init(
      loadAccountConnection: reader.loadAccountConnection,
      saveAccountConnection: { saveCodable($0, forKey: .accountConnection_v2) },
      loadProtectionMode: reader.loadProtectionMode,
      saveProtectionMode: { saveCodable($0, forKey: .protectionMode) },
      loadDisabledBlockGroupIds: reader.loadDisabledBlockGroupIds,
      saveDisabledBlockGroupIds: { saveCodable($0, forKey: .disabledBlockGroupIds) },
      loadAllBlockGroups: { loadCodable(forKey: .allBlockGroups) },
      saveAllBlockGroups: { saveCodable($0, forKey: .allBlockGroups) },
      loadFirstLaunchDate: reader.loadFirstLaunchDate,
      saveFirstLaunchDate: { saveDate($0, forKey: .firstLaunchDate) },
      loadDebugLogs: reader.loadDebugLogs,
      saveDebugLogs: { saveCodable($0, forKey: .debugLogs) },
      loadPendingSupervisionCode: { loadCodable(forKey: .pendingSupervisionCode) },
      savePendingSupervisionCode: { saveCodable($0, forKey: .pendingSupervisionCode) },
      clearPendingSupervisionCode: { removeKey(.pendingSupervisionCode) },
      loadDismissedCrossPromoIds: { loadCodable(forKey: .dismissedCrossPromoIds) },
      saveDismissedCrossPromoIds: { saveCodable($0, forKey: .dismissedCrossPromoIds) },
      loadCrossPromoLastShownAt: { loadDate(forKey: .crossPromoLastShownAt) },
      saveCrossPromoLastShownAt: { saveDate($0, forKey: .crossPromoLastShownAt) },
      loadSuspensionExpiration: reader.loadSuspensionExpiration,
      saveSuspensionExpiration: { saveDate($0, forKey: .suspensionExpiration) },
      clearSuspensionExpiration: { removeKey(.suspensionExpiration) },
      loadScreenshotLastSaved: reader.loadScreenshotLastSaved,
      saveScreenshotLastSaved: { saveDate($0, forKey: .screenshotLastSaved) },
      migrateLegacyData: { await migrateLegacyStorage() },
    )
  }
}

extension SharedStorageClient: TestDependencyKey {
  public static let testValue = SharedStorageClient()
}

public extension SharedStorageClient {
  func saveDebugLog(_ log: String) {
    var logs = self.loadDebugLogs() ?? []
    logs.append(log)
    self.saveDebugLogs(logs)
  }
}

extension SharedStorageReaderClient: DependencyKey {
  public static let liveValue = SharedStorageReaderClient(
    loadAccountConnection: { loadCodable(forKey: .accountConnection_v2) },
    loadProtectionMode: { loadCodable(forKey: .protectionMode) },
    loadDisabledBlockGroupIds: { loadCodable(forKey: .disabledBlockGroupIds) },
    loadFirstLaunchDate: { loadDate(forKey: .firstLaunchDate) },
    loadDebugLogs: { loadCodable(forKey: .debugLogs) },
    loadSuspensionExpiration: { loadDate(forKey: .suspensionExpiration) },
    loadScreenshotLastSaved: { loadDate(forKey: .screenshotLastSaved) },
  )
}

extension SharedStorageReaderClient: TestDependencyKey {
  public static let testValue = SharedStorageReaderClient()
}

func migrateLegacyStorage() async -> Bool {
  @Dependency(\.groupDefaults) var defaults
  if defaults.data(forKey: Key.disabledBlockGroupIds.rawValue) == nil {
    let legacyGroups: [BlockGroup]? = loadCodable(forKey: .disabledBlockGroups)
    let isUpgrader = legacyGroups != nil
      || defaults.data(forKey: Key.legacyV1StorageKey.rawValue) != nil
    if isUpgrader {
      var uuids = (legacyGroups ?? []).map(\.legacyUUID)
      // don't auto opt-in upgraders to new Apple Music group released March 2026
      uuids.append(UUID(uuidString: "236c92c9-a06c-4f68-9f1a-74e76163ae07")!)
      saveCodable(uuids, forKey: .disabledBlockGroupIds)
      @Dependency(\.api) var api
      await api.logEvent(id: "04376893", detail: "migrated block groups to UUIDs")
    }
  }

  if defaults.data(forKey: Key.protectionMode.rawValue) != nil {
    return false // fast path, they have current data, we're done
  }

  @Dependency(\.api) var api

  // migrate 1.3.x data to 1.5.x
  if let v13x: ProtectionMode.Legacy = loadCodable(forKey: .legacyProtectionMode) {
    let current = v13x.toCurrent()
    saveCodable(current, forKey: .protectionMode)
    var disabledGroups: [BlockGroup] = loadCodable(forKey: .disabledBlockGroups) ?? []
    if !disabledGroups.contains(.spotifyImages) {
      disabledGroups.append(.spotifyImages)
    }
    saveCodable(disabledGroups, forKey: .disabledBlockGroups)
    await api.logEvent(id: "edd6e55f", detail: "migrated v1.3.x -> 1.5.x")
    return true
  }

  if defaults.data(forKey: Key.legacyProtectionMode.rawValue) != nil {
    await api.logEvent(id: "fdab6cff", detail: "unexpected migration error")
    return false
  }

  if defaults.data(forKey: Key.legacyV1StorageKey.rawValue) == nil {
    // no data, nothing to migrate, probably initial launch
    return false
  }

  // migrate < 1.3.x very old data, from 1.0/1 -> 1.5
  @Dependency(\.device) var device
  saveCodable([BlockGroup.spotifyImages], forKey: .disabledBlockGroups)
  if let defaultRules = try? await api.fetchDefaultBlockRules(device.deviceId()) {
    await api.logEvent(id: "c732e0ab", detail: "migrated v1.1.x -> 1.5.x")
    saveCodable(ProtectionMode.normal(defaultRules), forKey: .protectionMode)
  } else {
    saveCodable(
      // setting to .onboarding will produce faster api re-check to recover from this state
      ProtectionMode.onboarding(BlockRule.Legacy.defaults.map(\.current)),
      forKey: .protectionMode,
    )
    await api.logEvent(id: "8d4a445b", detail: "error migrating v1.1.x -> 1.5.x")
  }
  return true
}

private func saveCodable(_ value: some Codable, forKey key: Key) {
  @Dependency(\.groupDefaults) var defaults
  if let data = try? JSONEncoder().encode(value) {
    defaults.setData(data: data, forKey: key.rawValue)
  }
}

private func loadCodable<T: Codable>(forKey key: Key) -> T? {
  @Dependency(\.groupDefaults) var defaults
  guard let data = defaults.data(forKey: key.rawValue) else { return nil }
  return try? JSONDecoder().decode(T.self, from: data)
}

private func saveDate(_ date: Date, forKey key: Key) {
  @Dependency(\.groupDefaults) var defaults
  defaults.setDate(date: date, forKey: key.rawValue)
}

private func loadDate(forKey key: Key) -> Date? {
  @Dependency(\.groupDefaults) var defaults
  return defaults.date(forKey: key.rawValue)
}

private func removeKey(_ key: Key) {
  @Dependency(\.groupDefaults) var defaults
  defaults.remove(forKey: key.rawValue)
}

public extension DependencyValues {
  var sharedStorage: SharedStorageClient {
    get { self[SharedStorageClient.self] }
    set { self[SharedStorageClient.self] = newValue }
  }
}

public extension DependencyValues {
  var sharedStorageReader: SharedStorageReaderClient {
    get { self[SharedStorageReaderClient.self] }
    set { self[SharedStorageReaderClient.self] = newValue }
  }
}

extension SharedStorageClient {
  func osLogBufferedDebugLogs(prefix: String) {
    let allLogs = self.loadDebugLogs() ?? []
    for (i, logs) in allLogs.chunked(into: 6).enumerated() {
      os_log(
        "[G•] %{public}s buffered logs %d:\n%{public}s",
        i + 1,
        prefix,
        logs.joined(separator: "\n"),
      )
    }
  }
}

package extension ProtectionMode {
  enum Legacy: Codable {
    case onboarding([BlockRule.Legacy])
    case normal([BlockRule.Legacy])
    case emergencyLockdown

    func toCurrent() -> ProtectionMode {
      switch self {
      case .onboarding(let rules):
        .onboarding(rules.map(\.current))
      case .normal(let rules):
        .normal(rules.map(\.current))
      case .emergencyLockdown:
        .emergencyLockdown
      }
    }
  }
}
