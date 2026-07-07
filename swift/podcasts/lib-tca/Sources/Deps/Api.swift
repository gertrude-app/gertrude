import Dependencies
import DependenciesMacros
import Foundation
import GertieApp
import LibCore
import PairQL
import PairQLClient
import PodcastRoute

@DependencyClient
struct ApiClient: Sendable {
  var crossPromos: @Sendable () async throws -> CrossPromos.Output
  var migrateDeviceId: @Sendable (_ oldDeviceId: UUID, _ newVendorId: UUID) async throws -> Void
  var getTrialStatus: @Sendable () async throws -> GetTrialStatus.Output
  var getAccountStatus: @Sendable () async throws -> GetAccountStatus.Output
  var consumePinResetCode: @Sendable (_ code: Int) async throws -> Void
  var createClaimCode: @Sendable () async throws -> CreateClaimCode.Output
  var createDatabaseUpload: @Sendable (_ deviceId: UUID) async throws -> URL
  var verifyPromoCode: @Sendable (_ deviceId: UUID, _ code: String) async throws -> Bool
  var verifyDbDownload: @Sendable (_ deviceId: UUID, _ downloadUrl: String) async throws -> Bool
}

extension ApiClient: DependencyKey {
  static var testValue: ApiClient {
    var client = ApiClient()
    client.crossPromos = { .init(promos: []) }
    return client
  }

  static var liveValue: ApiClient {
    .init(
      crossPromos: {
        guard let metadata = await podcastDeviceMetadata() else {
          return .init(promos: [])
        }

        let input = CrossPromos.Input(
          deviceId: metadata.deviceId,
          appVersion: metadata.appVersion,
          modelIdentifier: metadata.modelIdentifier,
          iosVersion: metadata.iosVersion,
          locale: dep(\.locale).identifier,
        )

        return try await pairql.call(CrossPromos.self, unauthed: .crossPromos(input))
      },
      migrateDeviceId: { oldDeviceId, newVendorId in
        let input = MigratePodcastVendorId.Input(
          oldDeviceId: oldDeviceId,
          newVendorId: newVendorId,
        )
        _ = try await pairql.call(
          MigratePodcastVendorId.self,
          unauthed: .migratePodcastVendorId(input),
        )
      },
      getTrialStatus: {
        guard let deviceId = dep(\.keychain).loadDeviceId() else {
          throw ApiClient.ApiError.noDeviceId
        }
        let device = dep(\.device)
        let (_, iosVersion, modelIdentifier) = await device.data()
        let appVersion = Bundle.main
          .infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let input = GetTrialStatus.Input(
          deviceId: deviceId,
          modelIdentifier: modelIdentifier,
          iosVersion: iosVersion,
          appVersion: appVersion,
        )
        return try await pairql.call(GetTrialStatus.self, unauthed: .getTrialStatus(input))
      },
      getAccountStatus: {
        try await authed(GetAccountStatus.self, .getAccountStatus)
      },
      consumePinResetCode: { code in
        _ = try await authed(
          ConsumePinResetCode.self,
          .consumePinResetCode(.init(code: code)),
        )
      },
      createClaimCode: {
        guard let deviceId = dep(\.keychain).loadDeviceId() else {
          throw ApiClient.ApiError.noDeviceId
        }
        return try await pairql.call(
          CreateClaimCode.self,
          unauthed: .createClaimCode(.init(deviceId: deviceId)),
        )
      },
      createDatabaseUpload: { deviceId in
        let input = CreateDatabaseUpload.Input(installId: deviceId)
        let result = try await pairql.call(
          CreateDatabaseUpload.self,
          unauthed: .createDatabaseUpload(input),
        )
        return result.uploadUrl
      },
      verifyPromoCode: { deviceId, code in
        let input = VerifyPromoCode.Input(installId: deviceId, code: code)
        let result = try await pairql.call(
          VerifyPromoCode.self,
          unauthed: .verifyPromoCode(input),
        )
        return result.success
      },
      verifyDbDownload: { deviceId, downloadUrl in
        let input = VerifyDbDownload.Input(installId: deviceId, downloadUrl: downloadUrl)
        let result = try await pairql.call(
          VerifyDbDownload.self,
          unauthed: .verifyDbDownload(input),
        )
        return result.success
      },
    )
  }
}

private let pairql = PairQLClient<PodcastRoute>(
  endpoint: { GertrudeIOSApp.apiBaseURL() },
  timeout: 10,
)

func authed<P: Pair>(
  _ pair: P.Type,
  _ route: AuthedRoute,
) async throws -> P.Output {
  guard let token = dep(\.keychain).loadAmToken() else {
    throw ApiClient.ApiError.noToken
  }
  return try await pairql.call(pair, authed: route, token: token)
}

private func podcastDeviceMetadata() async -> (
  deviceId: UUID,
  appVersion: String,
  buildNumber: String?,
  modelIdentifier: String,
  iosVersion: String,
)? {
  guard let deviceId = dep(\.keychain).loadDeviceId() else { return nil }
  let device = dep(\.device)
  let (_, iosVersion, modelIdentifier) = await device.data()
  let appVersion = Bundle.main
    .infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
  let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
  return (deviceId, appVersion, buildNumber, modelIdentifier, iosVersion)
}

extension ApiClient {
  enum ApiError: Error {
    case requestFailed
    case noDeviceId
    case noToken
    case unexpectedError(statusCode: Int)
  }
}

extension DependencyValues {
  var api: ApiClient {
    get { self[ApiClient.self] }
    set { self[ApiClient.self] = newValue }
  }
}
