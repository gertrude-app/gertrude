import Core
import Dependencies
import Foundation
import Gertie

@testable import Filter

class TestFilter: NetworkFilter {
  struct State: DecisionState {
    var userKeychains: [uid_t: [RuleKeychain]] = [:] {
      didSet { self.rebuildKeychainIndexes() }
    }

    var userKeychainIndexes: [uid_t: KeychainIndex] = [:]
    var userDowntime: [uid_t: Downtime] = [:]
    var userAlwaysBlocked: [uid_t: [BlockRule]] = [:]

    mutating func rebuildKeychainIndexes() {
      self.userKeychainIndexes = self.userKeychains.mapValues { KeychainIndex(keychains: $0) }
    }

    var appIdManifest = AppIdManifest()
    var exemptUsers: Set<uid_t> = []
    var filteringDisabledUsers: Set<uid_t> = []
    var suspensions: [uid_t: FilterSuspension] = [:]
    var appCache: [String: AppDescriptor] = [:]
    var macappsAliveUntil: [uid_t: Date] = [:]
  }

  var state = State()

  @Dependency(\.security) var security
  @Dependency(\.date.now) var now
  @Dependency(\.calendar) var calendar

  func appCache(get bundleId: String) -> AppDescriptor? {
    self.state.appCache[bundleId]
  }

  func appCache(insert: AppDescriptor, for bundleId: String) {
    self.state.appCache[bundleId] = insert
  }

  static func scenario(
    userIdFromAuditToken userId: uid_t? = 502,
    userKeychains: [uid_t: [RuleKeychain]] = [502: [.mock]],
    userDowntime: [uid_t: PlainTimeWindow] = [:],
    userAlwaysBlocked: [uid_t: [BlockRule]] = [:],
    macappsAliveUntil: [uid_t: Date] = [502: .distantFuture, 503: .distantFuture],
    date: Dependencies.DateGenerator = .init { Date() },
    appIdManifest: AppIdManifest = .init(
      apps: ["chrome": ["com.chrome"]],
      displayNames: ["chrome": "Chrome"],
      categories: ["browser": ["chrome"]],
    ),
    exemptUsers: Set<uid_t> = [],
    filteringDisabledUsers: Set<uid_t> = [],
    suspensions: [uid_t: FilterSuspension] = [:],
  ) -> TestFilter {
    withDependencies {
      $0.security.userIdFromAuditToken = { token in
        token.flatMap { _ in userId }
      }
      $0.date = date
      $0.calendar = Calendar(identifier: .gregorian)
    } operation: {
      let filter = TestFilter()
      var state = State()
      state.userDowntime = userDowntime.mapValues { Downtime(window: $0) }
      state.userAlwaysBlocked = userAlwaysBlocked
      var normalizedManifest = appIdManifest
      normalizedManifest.normalizeBundleIds()
      state.appIdManifest = normalizedManifest
      state.exemptUsers = exemptUsers
      state.filteringDisabledUsers = filteringDisabledUsers
      state.suspensions = suspensions
      state.macappsAliveUntil = macappsAliveUntil
      state.userKeychains = userKeychains
      filter.state = state
      return filter
    }
  }

  func log(event: FilterLogs.Event) {}
}
