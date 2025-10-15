import Dependencies
import DependenciesMacros
import Foundation
import LibCore

@DependencyClient
struct ApiClient: Sendable {
  var logEvent: @Sendable (
    _ id: String,
    _ kind: EventKind,
    _ label: String,
    _ detail: String?
  ) async throws -> Void
}

extension ApiClient {
  struct LogEventInput: Codable {
    var eventId: String
    var kind: String
    var label: String
    var detail: String?
    var installId: UUID?
    var deviceType: String
    var appVersion: String
    var iosVersion: String
  }
}

extension ApiClient: DependencyKey {
  static var liveValue: ApiClient {
    let apiEndpoint = Bundle.main.infoDictionary?["API_ENDPOINT"] as? String
      ?? "https://api.gertrude.app"

    return .init(
      logEvent: { id, kind, label, detail in

        let (iosVersion, deviceType) = await MainActor.run { (
          UIDevice.current.systemVersion,
          UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        ) }

        let appVersion = Bundle.main
          .infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

        let input = LogEventInput(
          eventId: id,
          kind: kind.string,
          label: label,
          detail: detail,
          installId: dep(\.keychain).loadInstallId(),
          deviceType: deviceType,
          appVersion: appVersion,
          iosVersion: iosVersion,
        )

        var request =
          URLRequest(url: URL(string: "\(apiEndpoint)/pairql/gertrude-am/LogPodcastEvent")!)
        request.httpMethod = "POST"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(input)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200 ... 299).contains(httpResponse.statusCode) else {
          throw ApiError.requestFailed
        }
      }
    )
  }
}

extension ApiClient {
  enum ApiError: Error {
    case requestFailed
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
  line: UInt = #line
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
        line: line
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
