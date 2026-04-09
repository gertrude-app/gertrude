import Dependencies
import Foundation
import Gertie
import MacAppRoute

public struct ApiClient: Sendable {
  public var checkIn: @Sendable (CheckIn_v2.Input) async throws -> CheckIn_v2.Output
  public var clearUserToken: @Sendable () async -> Void
  public var connectUser: @Sendable (ConnectUser.Input) async throws -> UserData
  public var createOnboardingAppKeys: @Sendable (CreateOnboardingAppKeys.Input) async throws -> Void
  public var createOnboardingBlockedApps: @Sendable (CreateOnboardingBlockedApps.Input)
    async throws -> Void
  public var disableFilterForChild: @Sendable () async throws -> Void
  public var setDowntimeSchedule: @Sendable (SetDowntimeSchedule.Input) async throws -> Void
  public var createKeystrokeLines: @Sendable (CreateKeystrokeLines.Input) async throws -> Void
  public var createSuspendFilterRequest: @Sendable (CreateSuspendFilterRequest_v2.Input)
    async throws -> UUID
  public var createUnlockRequests: @Sendable (CreateUnlockRequests_v3.Input) async throws -> [UUID]
  public var getUserToken: @Sendable () async throws -> UUID?
  public var logFilterEvents: @Sendable (LogFilterEvents.Input) async -> Void
  public var logInterestingEvent: @Sendable (LogInterestingEvent.Input) async -> Void
  public var logSecurityEvent: @Sendable (LogSecurityEvent.Input, UUID?) async -> Void
  public var recentAppVersions: @Sendable () async throws -> [String: String]
  public var reportBrowsers: @Sendable (ReportBrowsers.Input) async throws -> Void
  public var setAccountActive: @Sendable (Bool) async -> Void
  public var setUserToken: @Sendable (UUID) async -> Void
  public var trustedNetworkTimestamp: @Sendable () async throws -> Double
  public var uploadAppIcon: @Sendable (UploadAppIcon.Input) async throws -> Void
  public var uploadScreenshot: @Sendable (UploadScreenshotData) async throws -> Void

  public init(
    checkIn: @escaping @Sendable (CheckIn_v2.Input) async throws -> CheckIn_v2.Output,
    clearUserToken: @escaping @Sendable () async -> Void,
    connectUser: @escaping @Sendable (ConnectUser.Input) async throws -> UserData,
    createOnboardingAppKeys: @escaping @Sendable (CreateOnboardingAppKeys.Input)
    async throws -> Void,
    createOnboardingBlockedApps: @escaping @Sendable (CreateOnboardingBlockedApps.Input)
    async throws -> Void,
    disableFilterForChild: @escaping @Sendable () async throws -> Void,
    setDowntimeSchedule: @escaping @Sendable (SetDowntimeSchedule.Input) async throws -> Void,
    createKeystrokeLines: @escaping @Sendable (CreateKeystrokeLines.Input) async throws -> Void,
    createSuspendFilterRequest: @escaping @Sendable (CreateSuspendFilterRequest_v2.Input)
    async throws -> UUID,
    createUnlockRequests: @escaping @Sendable (CreateUnlockRequests_v3.Input)
    async throws -> [UUID],
    getUserToken: @escaping @Sendable () async throws -> UUID?,
    logFilterEvents: @escaping @Sendable (LogFilterEvents.Input) async -> Void,
    logInterestingEvent: @escaping @Sendable (LogInterestingEvent.Input) async -> Void,
    logSecurityEvent: @escaping @Sendable (LogSecurityEvent.Input, UUID?) async -> Void,
    recentAppVersions: @escaping @Sendable () async throws -> [String: String],
    reportBrowsers: @escaping @Sendable (ReportBrowsers.Input) async throws -> Void,
    setAccountActive: @escaping @Sendable (Bool) async -> Void,
    setUserToken: @escaping @Sendable (UUID) async -> Void,
    trustedNetworkTimestamp: @escaping @Sendable () async throws -> Double,
    uploadAppIcon: @escaping @Sendable (UploadAppIcon.Input) async throws -> Void,
    uploadScreenshot: @escaping @Sendable (UploadScreenshotData) async throws -> Void,
  ) {
    self.checkIn = checkIn
    self.clearUserToken = clearUserToken
    self.connectUser = connectUser
    self.createOnboardingAppKeys = createOnboardingAppKeys
    self.createOnboardingBlockedApps = createOnboardingBlockedApps
    self.disableFilterForChild = disableFilterForChild
    self.setDowntimeSchedule = setDowntimeSchedule
    self.createKeystrokeLines = createKeystrokeLines
    self.createSuspendFilterRequest = createSuspendFilterRequest
    self.createUnlockRequests = createUnlockRequests
    self.getUserToken = getUserToken
    self.logFilterEvents = logFilterEvents
    self.logInterestingEvent = logInterestingEvent
    self.logSecurityEvent = logSecurityEvent
    self.recentAppVersions = recentAppVersions
    self.reportBrowsers = reportBrowsers
    self.setAccountActive = setAccountActive
    self.setUserToken = setUserToken
    self.trustedNetworkTimestamp = trustedNetworkTimestamp
    self.uploadAppIcon = uploadAppIcon
    self.uploadScreenshot = uploadScreenshot
  }
}

extension ApiClient: EndpointOverridable {
  public static let endpointDefault = AppConfiguration.apiBaseURL.appendingPathComponent("pairql")

  public static let endpointOverride = LockIsolated<URL?>(nil)
}

public extension ApiClient {
  struct UploadScreenshotData: Sendable, Equatable {
    public var image: Data
    public var width: Int
    public var height: Int
    public var filterSuspended: Bool
    public var createdAt: Date

    public init(image: Data, width: Int, height: Int, filterSuspended: Bool, createdAt: Date) {
      self.image = image
      self.width = width
      self.height = height
      self.filterSuspended = filterSuspended
      self.createdAt = createdAt
    }
  }
}

public extension ApiClient {
  enum Error: Swift.Error, Equatable {
    case accountInactive
    case missingUserToken
    case missingDataOrResponse
    case unexpectedError(statusCode: Int)
  }
}

extension ApiClient: TestDependencyKey {
  public static let testValue = Self(
    checkIn: unimplemented("ApiClient.checkIn"),
    clearUserToken: unimplemented("ApiClient.clearUserToken"),
    connectUser: unimplemented("ApiClient.connectUser"),
    createOnboardingAppKeys: unimplemented("ApiClient.createOnboardingAppKeys"),
    createOnboardingBlockedApps: unimplemented("ApiClient.createOnboardingBlockedApps"),
    disableFilterForChild: unimplemented("ApiClient.disableFilterForChild"),
    setDowntimeSchedule: unimplemented("ApiClient.setDowntimeSchedule"),
    createKeystrokeLines: unimplemented("ApiClient.createKeystrokeLines"),
    createSuspendFilterRequest: unimplemented("ApiClient.createSuspendFilterRequest"),
    createUnlockRequests: unimplemented("ApiClient.createUnlockRequests"),
    getUserToken: unimplemented("ApiClient.getUserToken"),
    logFilterEvents: unimplemented("ApiClient.logFilterEvents"),
    logInterestingEvent: unimplemented("ApiClient.logInterestingEvent"),
    logSecurityEvent: unimplemented("ApiClient.logSecurityEvent"),
    recentAppVersions: unimplemented("ApiClient.recentAppVersions"),
    reportBrowsers: unimplemented("ApiClient.reportBrowsers"),
    setAccountActive: unimplemented("ApiClient.setAccountActive"),
    setUserToken: unimplemented("ApiClient.setUserToken"),
    trustedNetworkTimestamp: unimplemented("ApiClient.trustedNetworkTimestamp"),
    uploadAppIcon: unimplemented("ApiClient.uploadAppIcon"),
    uploadScreenshot: unimplemented("ApiClient.uploadScreenshot"),
  )

  public static let mock = Self(
    checkIn: { _ in throw Error.unexpectedError(statusCode: 999) },
    clearUserToken: {},
    connectUser: { _ in throw Error.unexpectedError(statusCode: 888) },
    createOnboardingAppKeys: { _ in },
    createOnboardingBlockedApps: { _ in },
    disableFilterForChild: {},
    setDowntimeSchedule: { _ in },
    createKeystrokeLines: { _ in },
    createSuspendFilterRequest: { _ in .init() },
    createUnlockRequests: { _ in [] },
    getUserToken: { nil },
    logFilterEvents: { _ in },
    logInterestingEvent: { _ in },
    logSecurityEvent: { _, _ in },
    recentAppVersions: { [:] },
    reportBrowsers: { _ in },
    setAccountActive: { _ in },
    setUserToken: { _ in },
    trustedNetworkTimestamp: { 0.0 },
    uploadAppIcon: { _ in },
    uploadScreenshot: { _ in },
  )
}

public extension DependencyValues {
  var api: ApiClient {
    get { self[ApiClient.self] }
    set { self[ApiClient.self] = newValue }
  }
}
