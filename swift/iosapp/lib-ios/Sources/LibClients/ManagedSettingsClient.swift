import Dependencies
import DependenciesMacros
import Foundation
import LibCore

#if os(iOS)
  @preconcurrency import FamilyControls
  @preconcurrency import ManagedSettings
#endif

/// Shield operations on a dedicated named `ManagedSettingsStore`. The interface
/// traffics in encoded `FamilyActivitySelection` data (the opaque, device-bound
/// tokens survive only as their Codable representation) so it compiles on every
/// platform and the selection can round-trip through the app-group defaults from
/// the app (which owns the `FamilyActivityPicker` UI) into the controller
/// extension (which owns reconcile writes). Store writes are fire-and-forget
/// property assignments with no error channel — each method returns a
/// human-readable outcome string for witnesses; verification is observational.
@DependencyClient
public struct ManagedSettingsClient: Sendable {
  public var shieldApps: @Sendable (_ selection: Data) -> String = { _ in "unimplemented" }
  public var shieldAllExcept: @Sendable (_ selection: Data) -> String = { _ in "unimplemented" }
  public var shieldWebDomains: @Sendable (_ selection: Data) -> String = { _ in "unimplemented" }
  public var clearShields: @Sendable () -> Void
  public var shieldsDescription: @Sendable () -> String = { "unimplemented" }
}

extension ManagedSettingsClient: DependencyKey {
  public static var liveValue: ManagedSettingsClient {
    #if os(iOS)
      let store = LockIsolated(ManagedSettingsStore(named: .init("shields-lab")))
      return ManagedSettingsClient(
        shieldApps: { data in
          guard let selection = decode(data) else { return "ERR decode-failed" }
          store.withValue {
            $0.shield.applications = selection.applicationTokens.isEmpty
              ? nil : selection.applicationTokens
          }
          return "applications=\(selection.applicationTokens.count)"
        },
        shieldAllExcept: { data in
          guard let selection = decode(data) else { return "ERR decode-failed" }
          store.withValue {
            $0.shield.applicationCategories = .all(except: selection.applicationTokens)
          }
          return "all-except=\(selection.applicationTokens.count)"
        },
        shieldWebDomains: { data in
          guard let selection = decode(data) else { return "ERR decode-failed" }
          store.withValue {
            $0.shield.webDomains = selection.webDomainTokens.isEmpty
              ? nil : selection.webDomainTokens
          }
          return "webDomains=\(selection.webDomainTokens.count)"
        },
        clearShields: {
          store.withValue {
            $0.shield.applications = nil
            $0.shield.applicationCategories = nil
            $0.shield.webDomains = nil
            $0.shield.webDomainCategories = nil
          }
        },
        shieldsDescription: {
          store.withValue {
            let apps = $0.shield.applications?.count ?? 0
            let categories = $0.shield.applicationCategories != nil
            let webDomains = $0.shield.webDomains?.count ?? 0
            return "apps=\(apps) categoriesPolicy=\(categories) webDomains=\(webDomains)"
          }
        },
      )
    #else
      return ManagedSettingsClient(
        shieldApps: { _ in "no-op (non-iOS)" },
        shieldAllExcept: { _ in "no-op (non-iOS)" },
        shieldWebDomains: { _ in "no-op (non-iOS)" },
        clearShields: {},
        shieldsDescription: { "no-op (non-iOS)" },
      )
    #endif
  }
}

#if os(iOS)
  private func decode(_ data: Data) -> FamilyActivitySelection? {
    try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
  }
#endif

extension ManagedSettingsClient: TestDependencyKey {
  public static let testValue = ManagedSettingsClient()
}

public extension DependencyValues {
  var managedSettings: ManagedSettingsClient {
    get { self[ManagedSettingsClient.self] }
    set { self[ManagedSettingsClient.self] = newValue }
  }
}
