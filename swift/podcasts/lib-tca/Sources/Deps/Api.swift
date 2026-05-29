import Dependencies
import DependenciesMacros
import Foundation
import LibCore
import PairQL
import PodcastRoute

@DependencyClient
struct ApiClient: Sendable {
  var logEvent: @Sendable (
    _ id: String,
    _ kind: EventKind,
    _ label: String,
    _ detail: String?,
  ) async throws -> Void
  var migrateDeviceId: @Sendable (_ oldDeviceId: UUID, _ newVendorId: UUID) async throws -> Void
  var getTrialStatus: @Sendable () async throws -> GetTrialStatus.Output
  var getAccountStatus: @Sendable () async throws -> GetAccountStatus.Output
  var createClaimCode: @Sendable () async throws -> CreateClaimCode.Output
  var createDatabaseUpload: @Sendable (_ deviceId: UUID) async throws -> URL
  var verifyPromoCode: @Sendable (_ deviceId: UUID, _ code: String) async throws -> Bool
  var verifyDbDownload: @Sendable (_ deviceId: UUID, _ downloadUrl: String) async throws -> Bool
}

extension ApiClient: DependencyKey {
  static var liveValue: ApiClient {
    .init(
      logEvent: { id, kind, label, detail in
        guard let deviceId = dep(\.keychain).loadDeviceId() else { return }
        let device = dep(\.device)
        let (_, iosVersion, modelIdentifier) = await device.data()

        let appVersion = Bundle.main
          .infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

        let input = LogPodcastEvent_v3.Input(
          eventId: id,
          kind: kind.string,
          label: label,
          detail: detail,
          deviceId: deviceId,
          modelIdentifier: modelIdentifier,
          appVersion: appVersion,
          iosVersion: iosVersion,
        )

        _ = try await output(
          from: LogPodcastEvent_v3.self,
          withUnauthed: .logPodcastEvent_v3(input),
        )
      },
      migrateDeviceId: { oldDeviceId, newVendorId in
        let input = MigratePodcastVendorId.Input(
          oldDeviceId: oldDeviceId,
          newVendorId: newVendorId,
        )
        _ = try await output(
          from: MigratePodcastVendorId.self,
          withUnauthed: .migratePodcastVendorId(input),
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
        return try await output(from: GetTrialStatus.self, withUnauthed: .getTrialStatus(input))
      },
      getAccountStatus: {
        try await output(from: GetAccountStatus.self, with: .getAccountStatus)
      },
      createClaimCode: {
        guard let deviceId = dep(\.keychain).loadDeviceId() else {
          throw ApiClient.ApiError.noDeviceId
        }
        return try await output(
          from: CreateClaimCode.self,
          withUnauthed: .createClaimCode(.init(deviceId: deviceId)),
        )
      },
      createDatabaseUpload: { deviceId in
        let input = CreateDatabaseUpload.Input(installId: deviceId)
        let result = try await output(
          from: CreateDatabaseUpload.self,
          withUnauthed: .createDatabaseUpload(input),
        )
        return result.uploadUrl
      },
      verifyPromoCode: { deviceId, code in
        let input = VerifyPromoCode.Input(installId: deviceId, code: code)
        let result = try await output(
          from: VerifyPromoCode.self,
          withUnauthed: .verifyPromoCode(input),
        )
        return result.success
      },
      verifyDbDownload: { deviceId, downloadUrl in
        let input = VerifyDbDownload.Input(installId: deviceId, downloadUrl: downloadUrl)
        let result = try await output(
          from: VerifyDbDownload.self,
          withUnauthed: .verifyDbDownload(input),
        )
        return result.success
      },
    )
  }
}

func output<P: Pair>(
  from pair: P.Type,
  withUnauthed route: UnauthedRoute,
) async throws -> P.Output {
  try await send(.unauthed(route))
}

func output<P: Pair>(
  from pair: P.Type,
  with route: AuthedRoute,
) async throws -> P.Output {
  guard let token = dep(\.keychain).loadAmToken() else {
    throw ApiClient.ApiError.noToken
  }
  return try await send(.authed(token, route))
}

private func send<Output: PairOutput>(_ route: PodcastRoute) async throws -> Output {
  let apiEndpoint = Bundle.main.infoDictionary?["API_ENDPOINT"] as? String
    ?? "https://api.gertrude.app"
  let router = PodcastRoute.router.baseURL("\(apiEndpoint)/pairql/gertrude-am")
  var request = try router.request(for: route)
  request.httpMethod = "POST"
  request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
  request.timeoutInterval = 10

  let (data, response) = try await URLSession.shared.data(for: request)

  guard let httpResponse = response as? HTTPURLResponse else {
    throw ApiClient.ApiError.requestFailed
  }

  if httpResponse.statusCode >= 300 {
    if let pqlError = try? JSON.decode(data, as: PqlError.self) {
      throw pqlError
    }
    throw ApiClient.ApiError.unexpectedError(statusCode: httpResponse.statusCode)
  }

  return try JSON.decode(data, as: Output.self, [.isoDates])
}

extension ApiClient {
  enum ApiError: Error {
    case requestFailed
    case noDeviceId
    case noToken
    case unexpectedError(statusCode: Int)
  }
}

enum EventKind {
  case error(String? = nil)
  case unexpected(String? = nil)
  case info(String? = nil)
  case subscription(String? = nil)
  case debug

  var apiId: String? {
    switch self {
    case .error(let id),
         .unexpected(let id),
         .info(let id),
         .subscription(let id):
      id
    default: nil
    }
  }

  var string: String {
    switch self {
    case .error: "error"
    case .unexpected: "unexpected"
    case .info: "info"
    case .debug: "debug"
    case .subscription: "subscription"
    }
  }

  enum Db: String {
    case error
    case unexpected
    case info
    case debug
    case subscription
  }

  var toDb: EventKind.Db {
    switch self {
    case .error: .error
    case .unexpected: .unexpected
    case .info: .info
    case .debug: .debug
    case .subscription: .subscription
    }
  }
}

@discardableResult
func log(
  _ kind: EventKind,
  _ label: String,
  detail: String? = nil,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  file: StaticString = #file,
  line: UInt = #line,
) -> Task<Void, Never> {
  Task {
    do {
      if let apiId = kind.apiId {
        try await dep(\.api).logEvent(apiId, kind, label, detail)
      }
      dep(\.db).insertEvent(
        kind: kind.toDb,
        label: label,
        detail: detail,
        apiId: kind.apiId,
      )
    } catch {
      reportIssue(
        "Failed to log event kind \(kind), label: \(label), detail: \(detail ?? "nil"): \(error)",
        fileID: fileID,
        filePath: filePath,
        line: line,
      )
    }
  }
}

extension DependencyValues {
  var api: ApiClient {
    get { self[ApiClient.self] }
    set { self[ApiClient.self] = newValue }
  }
}
