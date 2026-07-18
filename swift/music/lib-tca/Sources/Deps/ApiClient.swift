import Dependencies
import DependenciesMacros
import Foundation
import GertieApp
import MusicRoute
import PairQL
import PairQLClient

@DependencyClient
struct ApiClient: Sendable {
  var getMusicAppStatus: @Sendable () async throws -> GetMusicAppStatus.Output
  var getMusicOnboardingConfig: @Sendable () async throws -> GetMusicOnboardingConfig.Output
  var getApprovedMusicLibrary:
    @Sendable (_ token: UUID, _ knownRevision: Int64?) async throws
    -> GetApprovedMusicLibrary_v3.Output
}

extension ApiClient: DependencyKey {
  static var liveValue: ApiClient {
    .init(
      getMusicAppStatus: {
        @Dependency(\.device) var device
        let (deviceId, iosVersion, modelIdentifier, appVersion) = await device.data()
        guard let deviceId else {
          throw ApiClient.ApiError.noDeviceId
        }
        return try await pairql.call(
          GetMusicAppStatus.self,
          unauthed: .getMusicAppStatus(.init(
            deviceId: deviceId,
            modelIdentifier: modelIdentifier,
            iosVersion: iosVersion,
            appVersion: appVersion,
          )),
        )
      },
      getMusicOnboardingConfig: {
        try await pairql.call(
          GetMusicOnboardingConfig.self,
          unauthed: .getMusicOnboardingConfig,
        )
      },
      getApprovedMusicLibrary: { token, knownRevision in
        let input = GetApprovedMusicLibrary_v3.Input(knownRevision: knownRevision)
        return try await pairql.call(
          GetApprovedMusicLibrary_v3.self,
          authed: .getApprovedMusicLibrary_v3(input),
          token: token,
        )
      },
    )
  }
}

private let pairql = PairQLClient<MusicRoute>(
  endpoint: { GertrudeIOSApp.apiBaseURL() },
  timeout: 10,
)

extension ApiClient {
  enum ApiError: Error {
    case noDeviceId
    case unexpectedError(statusCode: Int)
  }
}

extension DependencyValues {
  var api: ApiClient {
    get { self[ApiClient.self] }
    set { self[ApiClient.self] = newValue }
  }
}
