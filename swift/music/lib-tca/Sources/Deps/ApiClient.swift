import Dependencies
import DependenciesMacros
import Foundation
import MusicRoute
import PairQL
import PairQLClient

@DependencyClient
struct ApiClient: Sendable {
  var getMusicAppStatus: @Sendable () async throws -> GetMusicAppStatus.Output
  var getApprovedMusicLibrary:
    @Sendable (_ token: UUID) async throws -> GetApprovedMusicLibrary.Output
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
      getApprovedMusicLibrary: { token in
        try await pairql.call(
          GetApprovedMusicLibrary.self,
          authed: .getApprovedMusicLibrary,
          token: token,
        )
      },
    )
  }
}

private let pairql = PairQLClient<MusicRoute>(
  endpoint: { URL(string: .apiEndpoint)! },
  timeout: 10,
)

private extension String {
  static var apiEndpoint: String {
    Bundle.main.object(forInfoDictionaryKey: "API_ENDPOINT") as? String
      ?? "https://api.gertrude.app"
  }
}

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
