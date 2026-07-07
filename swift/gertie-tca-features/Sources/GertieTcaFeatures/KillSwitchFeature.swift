import ComposableArchitecture
import Dependencies
import Foundation
import GertieApp
import IOSAppsRoute
import PairQLClient
import SwiftUI

#if os(iOS)
  import UIKit
#endif

@Reducer
public struct KillSwitchFeature: Sendable {
  @ObservableState
  public struct State: Equatable {
    public var canPresentSuggested = true
    public var isChecking = false
    public var required: KillSwitchDirective?
    public var suggested: KillSwitchDirective?

    public init(
      canPresentSuggested: Bool = true,
      isChecking: Bool = false,
      required: KillSwitchDirective? = nil,
      suggested: KillSwitchDirective? = nil,
    ) {
      self.canPresentSuggested = canPresentSuggested
      self.isChecking = isChecking
      self.required = required
      self.suggested = suggested
    }
  }

  public enum Action: Equatable {
    case appDidEnterForeground(suggestedPresentationEnabled: Bool)
    case checkFailed
    case checkSucceeded(KillSwitchStatus)
    case suggestedDismissButtonTapped
    case suggestedPresentationAvailabilityChanged(Bool)
    case updateButtonTapped(KillSwitchDirective)
    case viewAppeared(suggestedPresentationEnabled: Bool)
  }

  public let app: GertrudeIOSApp
  public let deviceId: @Sendable () async throws -> UUID

  public init(
    app: GertrudeIOSApp,
    deviceId: @escaping @Sendable () async throws -> UUID,
  ) {
    self.app = app
    self.deviceId = deviceId
  }

  @Dependency(\.killSwitchClient) var client
  @Dependency(\.killSwitchStorage) var storage
  @Dependency(\.date.now) var now
  @Dependency(\.openURL) var openURL

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .viewAppeared(let enabled):
        state.canPresentSuggested = enabled
        let hadCachedRequired = self.restoreCachedRequired(&state)
        return self.checkIfNeeded(&state, force: hadCachedRequired)

      case .appDidEnterForeground(let enabled):
        state.canPresentSuggested = enabled
        let hadCachedRequired = self.restoreCachedRequired(&state)
        return self.checkIfNeeded(&state, force: hadCachedRequired)

      case .suggestedPresentationAvailabilityChanged(let enabled):
        state.canPresentSuggested = enabled
        guard enabled, state.suggested == nil else { return .none }
        guard case .suggested(let directive) = self.storage.load()?.lastStatus else {
          return .none
        }
        if self.canPresentSuggestion(directive) {
          state.suggested = directive
        }
        return .none

      case .checkSucceeded(let status):
        state.isChecking = false
        var cache = self.storage.load() ?? .init()
        cache.lastCheckedAt = self.now
        cache.lastStatus = status
        switch status {
        case .current(let timing):
          state.required = nil
          state.suggested = nil
          cache.clearCachedRequired()
          cache.nextCheckAfter = timing.nextCheckAfter ?? self.now
            .addingTimeInterval(Self.defaultCheckInterval)

        case .required(let directive):
          state.required = directive
          state.suggested = nil
          let build = self.client.currentBuild()
          cache.cachedRequired = directive
          cache.cachedRequiredAppVersion = build.version
          cache.cachedRequiredBuild = build.build
          cache.nextCheckAfter = directive.nextCheckAfter ?? self.now
            .addingTimeInterval(Self.defaultCheckInterval)

        case .suggested(let directive):
          state.required = nil
          cache.clearCachedRequired()
          cache.nextCheckAfter = directive.nextCheckAfter ?? self.now
            .addingTimeInterval(Self.defaultCheckInterval)
          if state.canPresentSuggested, self.canPresentSuggestion(directive, cache: cache) {
            state.suggested = directive
          }
        }
        self.storage.save(cache)
        return .none

      case .checkFailed:
        state.isChecking = false
        var cache = self.storage.load() ?? .init()
        cache.nextCheckAfter = self.now.addingTimeInterval(Self.failedCheckRetryInterval)
        if let required = cache.cachedRequired {
          state.required = required
        }
        self.storage.save(cache)
        return .none

      case .suggestedDismissButtonTapped:
        guard let directive = state.suggested else { return .none }
        state.suggested = nil
        var cache = self.storage.load() ?? .init()
        cache.dismissedSuggestedPolicyId = directive.policyId
        cache.dismissedSuggestedUntil = directive.remindAfter
          ?? self.now.addingTimeInterval(Self.defaultSuggestionReminderInterval)
        self.storage.save(cache)
        return .none

      case .updateButtonTapped(let directive):
        guard let url = URL(string: directive.appStoreUrl) else { return .none }
        return .run { _ in
          await self.openURL(url)
        }
      }
    }
  }

  func checkIfNeeded(_ state: inout State, force: Bool = false) -> EffectOf<Self> {
    guard !state.isChecking else { return .none }
    if !force, let next = self.storage.load()?.nextCheckAfter, next > self.now {
      return .none
    }
    state.isChecking = true
    return .run { send in
      do {
        try await send(.checkSucceeded(self.client.check(
          self.app,
          self.deviceId(),
        )))
      } catch {
        await send(.checkFailed)
      }
    }
  }

  func canPresentSuggestion(
    _ directive: KillSwitchDirective,
    cache: KillSwitchCache? = nil,
  ) -> Bool {
    let cache = cache ?? self.storage.load()
    guard cache?.dismissedSuggestedPolicyId == directive.policyId else { return true }
    guard let dismissedUntil = cache?.dismissedSuggestedUntil else { return true }
    return dismissedUntil <= self.now
  }

  private func restoreCachedRequired(_ state: inout State) -> Bool {
    guard let cache = self.storage.load(), let required = cache.cachedRequired else {
      return false
    }
    if self.cacheMatchesCurrentBuild(cache) {
      state.required = required
      return false
    }
    var cleared = cache
    cleared.clearCachedRequired()
    self.storage.save(cleared)
    return true
  }

  private func cacheMatchesCurrentBuild(_ cache: KillSwitchCache) -> Bool {
    let current = self.client.currentBuild()
    return cache.cachedRequiredAppVersion == current.version
      && cache.cachedRequiredBuild == current.build
  }

  static let defaultCheckInterval: TimeInterval = 60 * 60 * 12
  static let failedCheckRetryInterval: TimeInterval = 60 * 60
  static let defaultSuggestionReminderInterval: TimeInterval = 60 * 60 * 24 * 3
}

public enum KillSwitchDeviceIdError: Error, Equatable {
  case missingDeviceId
}

public struct KillSwitchBuild: Equatable, Sendable {
  public var version: String
  public var build: String?

  public init(version: String, build: String? = nil) {
    self.version = version
    self.build = build
  }
}

public struct KillSwitchClient: Sendable {
  public var check: @Sendable (GertrudeIOSApp, UUID) async throws -> KillSwitchStatus
  public var currentBuild: @Sendable () -> KillSwitchBuild

  public init(
    check: @escaping @Sendable (GertrudeIOSApp, UUID) async throws -> KillSwitchStatus,
    currentBuild: @escaping @Sendable () -> KillSwitchBuild,
  ) {
    self.check = check
    self.currentBuild = currentBuild
  }
}

extension KillSwitchClient: TestDependencyKey {
  public static var testValue: Self {
    .init(
      check: { _, _ in .current() },
      currentBuild: { .init(version: "1.0.0", build: "1") },
    )
  }
}

extension KillSwitchClient: DependencyKey {
  public static var liveValue: Self {
    .init(
      check: { app, deviceId in
        @Dependency(\.locale) var locale
        let iosVersion = await Self.iosVersion()
        let request = KillSwitchCheckRequest(
          app: app,
          deviceId: deviceId,
          appVersion: Self.appVersion,
          buildNumber: Self.buildNumber,
          modelIdentifier: Self.modelIdentifier(),
          iosVersion: iosVersion,
          locale: locale.identifier,
        )
        return try await Self.pairql
          .call(KillSwitchCheck.self, .unauthed(.killSwitchCheck(request)))
          .status
      },
      currentBuild: { .init(version: Self.appVersion, build: Self.buildNumber) },
    )
  }
}

public extension DependencyValues {
  var killSwitchClient: KillSwitchClient {
    get { self[KillSwitchClient.self] }
    set { self[KillSwitchClient.self] = newValue }
  }
}

public struct KillSwitchCache: Codable, Equatable, Sendable {
  public var lastCheckedAt: Date?
  public var nextCheckAfter: Date?
  public var lastStatus: KillSwitchStatus?
  public var cachedRequired: KillSwitchDirective?
  public var cachedRequiredAppVersion: String?
  public var cachedRequiredBuild: String?
  public var dismissedSuggestedPolicyId: String?
  public var dismissedSuggestedUntil: Date?

  public init(
    lastCheckedAt: Date? = nil,
    nextCheckAfter: Date? = nil,
    lastStatus: KillSwitchStatus? = nil,
    cachedRequired: KillSwitchDirective? = nil,
    cachedRequiredAppVersion: String? = nil,
    cachedRequiredBuild: String? = nil,
    dismissedSuggestedPolicyId: String? = nil,
    dismissedSuggestedUntil: Date? = nil,
  ) {
    self.lastCheckedAt = lastCheckedAt
    self.nextCheckAfter = nextCheckAfter
    self.lastStatus = lastStatus
    self.cachedRequired = cachedRequired
    self.cachedRequiredAppVersion = cachedRequiredAppVersion
    self.cachedRequiredBuild = cachedRequiredBuild
    self.dismissedSuggestedPolicyId = dismissedSuggestedPolicyId
    self.dismissedSuggestedUntil = dismissedSuggestedUntil
  }

  mutating func clearCachedRequired() {
    self.cachedRequired = nil
    self.cachedRequiredAppVersion = nil
    self.cachedRequiredBuild = nil
  }
}

public struct KillSwitchStorage: Sendable {
  public var load: @Sendable () -> KillSwitchCache?
  public var save: @Sendable (KillSwitchCache) -> Void

  public init(
    load: @escaping @Sendable () -> KillSwitchCache?,
    save: @escaping @Sendable (KillSwitchCache) -> Void,
  ) {
    self.load = load
    self.save = save
  }
}

extension KillSwitchStorage: TestDependencyKey {
  public static var testValue: Self {
    .init(load: { nil }, save: { _ in })
  }
}

extension KillSwitchStorage: DependencyKey {
  public static var liveValue: Self {
    let box = UserDefaultsBox(defaults: .standard)
    return .init(
      load: {
        guard let data = box.defaults.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(KillSwitchCache.self, from: data)
      },
      save: { cache in
        guard let data = try? JSONEncoder().encode(cache) else { return }
        box.defaults.set(data, forKey: Self.key)
      },
    )
  }

  private static let key = "kill-switch-cache-v1"
}

public extension DependencyValues {
  var killSwitchStorage: KillSwitchStorage {
    get { self[KillSwitchStorage.self] }
    set { self[KillSwitchStorage.self] = newValue }
  }
}

private final class UserDefaultsBox: @unchecked Sendable {
  let defaults: UserDefaults

  init(defaults: UserDefaults) {
    self.defaults = defaults
  }
}

private extension KillSwitchClient {
  static var apiBaseURL: URL {
    GertrudeIOSApp.apiBaseURL()
  }

  static let pairql = PairQLClient<IOSAppsRoute>(
    endpoint: { Self.apiBaseURL },
    timeout: 10,
  )

  static var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
  }

  static var buildNumber: String? {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String
  }

  @MainActor
  static func iosVersion() -> String {
    #if os(iOS)
      UIDevice.current.systemVersion
    #else
      ProcessInfo.processInfo.operatingSystemVersionString
    #endif
  }

  static func modelIdentifier() -> String {
    IOSDeviceInfo.modelIdentifier()
  }
}
