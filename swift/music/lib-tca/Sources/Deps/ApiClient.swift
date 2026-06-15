import Dependencies
import DependenciesMacros
import Foundation
import MusicRoute
import PairQL

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
        return try await output(
          from: GetMusicAppStatus.self,
          withUnauthed: .getMusicAppStatus(.init(
            deviceId: deviceId,
            modelIdentifier: modelIdentifier,
            iosVersion: iosVersion,
            appVersion: appVersion,
          )),
        )
      },
      getApprovedMusicLibrary: { token in
        try await output(
          from: GetApprovedMusicLibrary.self,
          withAuthed: .getApprovedMusicLibrary,
          token: token,
        )
      },
    )
  }
}

func output<T: Pair>(
  from pair: T.Type,
  withUnauthed route: UnauthedRoute,
) async throws -> T.Output {
  try await output(from: pair, route: .unauthed(route))
}

func output<T: Pair>(
  from pair: T.Type,
  withAuthed route: AuthedRoute,
  token: UUID,
) async throws -> T.Output {
  try await output(from: pair, route: .authed(token, route))
}

private func output<T: Pair>(from _: T.Type, route: MusicRoute) async throws -> T.Output {
  let (data, response) = try await request(route: route)
  if let httpResponse = response as? HTTPURLResponse,
     httpResponse.statusCode >= 300 {
    if let pqlError = try? JSONDecoder().decode(PqlError.self, from: data) {
      throw pqlError
    } else {
      throw ApiClient.ApiError.unexpectedError(statusCode: httpResponse.statusCode)
    }
  }
  return try jsonDecoder.decode(T.Output.self, from: data)
}

@discardableResult
private func request(route: MusicRoute) async throws -> (Data, URLResponse) {
  let router = MusicRoute.router.baseURL(.musicPairqlBase)
  var request = try router.request(for: route)
  request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
  request.httpMethod = "POST"
  request.timeoutInterval = 10
  return try await URLSession.shared.data(for: request)
}

private let jsonDecoder: JSONDecoder = {
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .iso8601
  return decoder
}()

private extension String {
  static var musicPairqlBase: String {
    "\(apiEndpoint)/pairql/gertrude-music"
  }

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
