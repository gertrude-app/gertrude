import BlockerRoute
import Dependencies
import DependenciesMacros
import Foundation
import GertieBlocker
import LibCore
import PairQL
import PairQLClient
import TaggedTime
import XCore

@DependencyClient
public struct ApiClient: Sendable {
  public var connectDevice: @Sendable (_ code: Int, _ deviceId: UUID)
    async throws -> ChildIOSDeviceData_v2
  public var connectedRules: @Sendable ()
    async throws -> ConnectedRules.Output
  public var fetchAllBlockGroups: @Sendable (_ deviceId: UUID)
    async throws -> [GetBlockGroups.BlockGroupInfo]
  public var fetchBlockRules: @Sendable (_ deviceId: UUID, _ disabledGroups: [UUID])
    async throws -> [BlockRule]
  public var fetchDefaultBlockRules: @Sendable (_ deviceId: UUID?)
    async throws -> [BlockRule]
  public var recoveryDirective: @Sendable ()
    async throws -> String?
  public var setAccountConnection: @Sendable (ChildIOSDeviceData_v2?)
    async -> Void
  public var connectAccountFeatureFlag: @Sendable ()
    async throws -> ConnectAccountFeatureFlag.Output
  public var createSupervisionClaimCode: @Sendable ()
    async throws -> CreateSupervisionClaimCode.Output
  public var checkSupervisionFlowStatus: @Sendable (_ code: Int)
    async throws -> CheckSupervisionFlowStatus.Output
  public var createBlockerClaimCode: @Sendable ()
    async throws -> CreateBlockerClaimCode.Output
  public var checkBlockerConnectionStatus: @Sendable (_ code: Int)
    async throws -> CheckBlockerConnectionStatus.Output
  public var markSupervisionProfileInstalled: @Sendable ()
    async throws -> Void
  public var crossPromos: @Sendable ()
    async throws -> CrossPromos.Output
}

extension ApiClient: TestDependencyKey {
  public static var testValue: ApiClient {
    var client = ApiClient()
    client.crossPromos = { .init(promos: []) }
    return client
  }
}

extension ApiClient: DependencyKey {
  public static var liveValue: ApiClient {
    let version = Bundle.main
      .infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    return ApiClient(
      connectDevice: { code, deviceId in
        @Dependency(\.device) var device
        let deviceData = await device.data()
        return try await pairql.call(
          ConnectDevice_v2.self,
          unauthed: .connectDevice_v2(.init(
            verificationCode: code,
            vendorId: deviceId,
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
        let result = try await authed(
          ConnectedRules_v2.self,
          .connectedRules_v2(.init(
            deviceId: conn.deviceId,
            modelIdentifier: deviceData.modelIdentifier,
            appVersion: version,
            iosVersion: deviceData.iOSVersion,
          )),
        )
        // context: https://gist.github.com/jaredh159/af45d98eee7f8a33b6b5af945ec23cfc
        return .init(blockRules: result.blockRules.map(\.current), webPolicy: result.webPolicy)
      },
      fetchAllBlockGroups: { deviceId in
        try await pairql.call(
          GetBlockGroups.self,
          unauthed: .getBlockGroups(.init(deviceId: deviceId)),
        )
      },
      fetchBlockRules: { deviceId, disabledGroups in
        try await pairql.call(
          BlockRules_v3.self,
          unauthed: .blockRules_v3(.init(
            deviceId: deviceId,
            appVersion: version,
            disabledGroups: disabledGroups,
          )),
        )
      },
      fetchDefaultBlockRules: { deviceId in
        let legacyRules = try await pairql.call(
          DefaultBlockRules.self,
          unauthed: .defaultBlockRules(.init(
            vendorId: deviceId,
            version: version,
          )),
        )
        return legacyRules.map(\.current)
      },
      recoveryDirective: {
        @Dependency(\.locale) var locale
        @Dependency(\.device) var device
        let deviceData = await device.data()
        let result = try await pairql.call(
          RecoveryDirective.self,
          unauthed: .recoveryDirective(.init(
            vendorId: deviceData.deviceId,
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
        try await pairql.call(
          ConnectAccountFeatureFlag.self,
          unauthed: .connectAccountFeatureFlag,
        )
      },
      createSupervisionClaimCode: {
        @Dependency(\.device) var device
        guard let deviceId = await device.deviceId() else {
          throw ApiClient.Error.missingVendorId
        }
        return try await pairql.call(
          CreateSupervisionClaimCode.self,
          unauthed: .createSupervisionClaimCode(.init(
            deviceId: deviceId,
            modelIdentifier: device.modelIdentifier(),
            iosVersion: device.iOSVersion(),
            appVersion: version,
          )),
        )
      },
      checkSupervisionFlowStatus: { code in
        @Dependency(\.device) var device
        guard let deviceId = await device.deviceId() else {
          throw ApiClient.Error.missingVendorId
        }
        return try await pairql.call(
          CheckSupervisionFlowStatus.self,
          unauthed: .checkSupervisionFlowStatus(.init(
            vendorId: deviceId,
            code: code,
            appVersion: version,
          )),
        )
      },
      createBlockerClaimCode: {
        @Dependency(\.device) var device
        guard let deviceId = await device.deviceId() else {
          throw ApiClient.Error.missingVendorId
        }
        return try await pairql.call(
          CreateBlockerClaimCode.self,
          unauthed: .createBlockerClaimCode(.init(
            deviceId: deviceId,
            modelIdentifier: device.modelIdentifier(),
            iosVersion: device.iOSVersion(),
            appVersion: version,
          )),
        )
      },
      checkBlockerConnectionStatus: { code in
        @Dependency(\.device) var device
        guard let deviceId = await device.deviceId() else {
          throw ApiClient.Error.missingVendorId
        }
        return try await pairql.call(
          CheckBlockerConnectionStatus.self,
          unauthed: .checkBlockerConnectionStatus(.init(
            vendorId: deviceId,
            code: code,
          )),
        )
      },
      markSupervisionProfileInstalled: {
        _ = try await authed(
          MarkSupervisionProfileInstalled.self,
          .markSupervisionProfileInstalled,
        )
      },
      crossPromos: {
        @Dependency(\.device) var device
        @Dependency(\.locale) var locale
        let deviceData = await device.data()
        guard let deviceId = deviceData.deviceId else {
          return .init(promos: [])
        }
        return try await pairql.call(
          CrossPromos.self,
          unauthed: .crossPromos(.init(
            deviceId: deviceId,
            appVersion: version,
            modelIdentifier: deviceData.modelIdentifier,
            iosVersion: deviceData.iOSVersion,
            locale: locale.identifier,
          )),
        )
      },
    )
  }
}

private let _accountConnection = Mutex<ChildIOSDeviceData_v2?>(nil)

private let pairql = PairQLClient<BlockerRoute>(
  endpoint: { URL(string: .gertrudeApi)! },
)

func authed<T: Pair>(
  _ pair: T.Type,
  _ route: AuthedRoute,
) async throws -> T.Output {
  guard let token = _accountConnection.withLock({ $0?.token }) else {
    throw ApiClient.Error.missingAccountConnection
  }
  return try await pairql.call(pair, authed: route, token: token)
}

public extension ApiClient {
  enum Error: Swift.Error {
    case missingVendorId
    case missingAccountConnection
    case missingDataOrResponse
    case unexpectedError(statusCode: Int)
  }
}

public extension DependencyValues {
  var api: ApiClient {
    get { self[ApiClient.self] }
    set { self[ApiClient.self] = newValue }
  }
}
