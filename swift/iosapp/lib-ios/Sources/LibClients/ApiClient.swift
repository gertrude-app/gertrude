import Dependencies
import DependenciesMacros
import Foundation
import GertieIOS
import IOSRoute
import LibCore
import os.log
import PairQL
import TaggedTime
import XCore

@DependencyClient
public struct ApiClient: Sendable {
  public var connectDevice: @Sendable (_ code: Int, _ vendorId: UUID)
    async throws -> ChildIOSDeviceData_v2
  public var connectedRules: @Sendable ()
    async throws -> ConnectedRules.Output
  public var fetchBlockRules: @Sendable (_ vendorId: UUID, _ disabledGroups: [BlockGroup])
    async throws -> [BlockRule]
  public var fetchDefaultBlockRules: @Sendable (_ vendorId: UUID?)
    async throws -> [BlockRule]
  public var logEvent: @Sendable (_ id: String, _ detail: String?)
    async -> Void
  public var recoveryDirective: @Sendable ()
    async throws -> String?
  public var setAccountConnection: @Sendable (ChildIOSDeviceData_v2?)
    async -> Void
  public var connectAccountFeatureFlag: @Sendable ()
    async throws -> ConnectAccountFeatureFlag.Output
  public var createSupervisionCode: @Sendable ()
    async throws -> CreateSupervisionCode.Output
  public var checkSupervisionStatus: @Sendable (_ code: Int)
    async throws -> CheckSupervisionStatus.Output
  public var selfReportSupervision: @Sendable (_ isSupervised: Bool)
    async throws -> Void
  public var markSetupComplete: @Sendable ()
    async throws -> Void
}

extension ApiClient: TestDependencyKey {
  public static let testValue = ApiClient()
}

extension ApiClient: DependencyKey {
  public static var liveValue: ApiClient {
    let version = Bundle.main
      .infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    return ApiClient(
      connectDevice: { code, vendorId in
        @Dependency(\.device) var device
        let deviceData = await device.data()
        return try await output(
          from: ConnectDevice_v2.self,
          withUnauthed: .connectDevice_v2(.init(
            verificationCode: code,
            vendorId: vendorId,
            modelIdentifier: deviceData.modelIdentifier,
            appVersion: version,
            iosVersion: deviceData.iOSVersion,
          )),
        )
      },
      connectedRules: {
        @Dependency(\.device) var device
        guard let conn = _accountConnection.withLock({ $0 }) else {
          throw ApiClient.Error.missingAccountConnection
        }
        let deviceData = await device.data()
        return try await output(
          from: ConnectedRules_v2.self,
          with: .connectedRules_v2(.init(
            deviceId: conn.deviceId,
            modelIdentifier: deviceData.type.rawValue,
            appVersion: version,
            iosVersion: deviceData.iOSVersion,
          )),
        )
      },
      fetchBlockRules: { vendorId, disabledGroups in
        let legacyRules = try await output(
          from: BlockRules_v2.self,
          withUnauthed: .blockRules_v2(.init(
            disabledGroups: disabledGroups,
            vendorId: vendorId,
            version: version,
          )),
        )
        return legacyRules.map(\.current)
      },
      fetchDefaultBlockRules: { vendorId in
        let legacyRules = try await output(
          from: DefaultBlockRules.self,
          withUnauthed: .defaultBlockRules(.init(
            vendorId: vendorId,
            version: version,
          )),
        )
        return legacyRules.map(\.current)
      },
      logEvent: { id, detail in
        @Dependency(\.device) var device
        let deviceData = await device.data()
        do {
          _ = try await output(
            from: LogIOSEvent_v2.self,
            withUnauthed: .logIOSEvent_v2(.init(
              eventId: id,
              kind: "ios",
              modelIdentifier: deviceData.modelIdentifier,
              iOSVersion: deviceData.iOSVersion,
              appVersion: version,
              vendorId: deviceData.vendorId,
              detail: detail,
            )),
          )
        } catch {
          os_log("[G•] error logging event: %{public}s", String(reflecting: error))
        }
      },
      recoveryDirective: {
        @Dependency(\.locale) var locale
        @Dependency(\.device) var device
        let deviceData = await device.data()
        let result = try await output(
          from: RecoveryDirective.self,
          withUnauthed: .recoveryDirective(.init(
            vendorId: deviceData.vendorId,
            deviceType: deviceData.type.rawValue,
            iOSVersion: deviceData.iOSVersion,
            locale: locale.region?.identifier,
            version: version,
          )),
        )
        return result.directive
      },
      setAccountConnection: { conn in
        _accountConnection.withLock { $0 = conn }
      },
      connectAccountFeatureFlag: {
        try await output(
          from: ConnectAccountFeatureFlag.self,
          withUnauthed: .connectAccountFeatureFlag,
        )
      },
      createSupervisionCode: {
        @Dependency(\.device) var device
        guard let vendorId = await device.vendorId() else {
          throw ApiClient.Error.missingVendorId
        }
        return try await output(
          from: CreateSupervisionCode.self,
          withUnauthed: .createSupervisionCode(.init(
            deviceId: vendorId,
            modelIdentifier: device.modelIdentifier(),
            iosVersion: device.iOSVersion(),
            appVersion: version,
          )),
        )
      },
      checkSupervisionStatus: { code in
        @Dependency(\.device) var device
        guard let vendorId = await device.vendorId() else {
          throw ApiClient.Error.missingVendorId
        }
        return try await output(
          from: CheckSupervisionStatus.self,
          withUnauthed: .checkSupervisionStatus(.init(
            vendorId: vendorId,
            code: code,
          )),
        )
      },
      selfReportSupervision: { isSupervised in
        _ = try await output(
          from: SelfReportSupervision.self,
          with: .selfReportSupervision(.init(isSupervised: isSupervised)),
        )
      },
      markSetupComplete: {
        _ = try await output(
          from: MarkSetupComplete.self,
          with: .markSetupComplete,
        )
      },
    )
  }
}

private let _accountConnection = Mutex<ChildIOSDeviceData_v2?>(nil)

func output<T: Pair>(
  from pair: T.Type,
  with route: AuthedRoute,
) async throws -> T.Output {
  guard let token = _accountConnection.withLock({ $0?.token }) else {
    throw ApiClient.Error.missingAccountConnection
  }
  let (data, res) = try await request(route: .authed(token, route))
  if let httpResponse = res as? HTTPURLResponse,
     httpResponse.statusCode >= 300 {
    if let pqlError = try? JSON.decode(data, as: PqlError.self) {
      throw pqlError
    } else {
      throw ApiClient.Error.unexpectedError(statusCode: httpResponse.statusCode)
    }
  }
  return try JSON.decode(data, as: T.Output.self, [.isoDates])
}

func output<T: Pair>(
  from pair: T.Type,
  withUnauthed route: UnauthedRoute,
) async throws -> T.Output {
  let (data, res) = try await request(route: .unauthed(route))
  if let httpResponse = res as? HTTPURLResponse,
     httpResponse.statusCode >= 300 {
    if let pqlError = try? JSON.decode(data, as: PqlError.self) {
      throw pqlError
    } else {
      throw ApiClient.Error.unexpectedError(statusCode: httpResponse.statusCode)
    }
  }
  return try JSON.decode(data, as: T.Output.self, [.isoDates])
}

public extension ApiClient {
  enum Error: Swift.Error {
    case missingVendorId
    case missingAccountConnection
    case missingDataOrResponse
    case unexpectedError(statusCode: Int)
  }
}

@discardableResult
private func request(route: IOSRoute) async throws -> (Data, URLResponse) {
  let router = IOSRoute.router.baseURL(.pairqlBase)
  var request = try router.request(for: route)
  request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
  request.httpMethod = "POST"
  return try await URLSession.shared.data(for: request)
}

public extension DependencyValues {
  var api: ApiClient {
    get { self[ApiClient.self] }
    set { self[ApiClient.self] = newValue }
  }
}
