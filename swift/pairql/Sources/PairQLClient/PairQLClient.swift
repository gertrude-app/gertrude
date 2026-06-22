import Foundation
import XCore

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@_exported import PairQL

public enum PairQLTransportError: Error, Equatable {
  case unexpected(statusCode: Int)
  case missingDataOrResponse
}

public struct PairQLClient<Route: PairQLClientRoute>: Sendable {
  public var endpoint: @Sendable () -> URL
  public var session: @Sendable () -> URLSession
  public var timeout: TimeInterval?

  public init(
    endpoint: @escaping @Sendable () -> URL,
    session: @escaping @Sendable () -> URLSession = { .shared },
    timeout: TimeInterval? = nil,
  ) {
    self.endpoint = endpoint
    self.session = session
    self.timeout = timeout
  }

  public func call<P: Pair>(_ pair: P.Type, _ route: Route) async throws -> P.Output {
    let root = self.endpoint().absoluteString
    let base = root.hasSuffix("/")
      ? "\(root)pairql/\(Route.domain)"
      : "\(root)/pairql/\(Route.domain)"
    var request = try Route.router.baseURL(base).request(for: route)
    request.httpMethod = "POST"
    request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    if let timeout = self.timeout {
      request.timeoutInterval = timeout
    }
    let (data, response) = try await self.data(for: request)
    if let http = response as? HTTPURLResponse, http.statusCode >= 300 {
      if let pqlError = try? JSON.decode(data, as: PqlError.self) {
        throw pqlError
      }
      throw PairQLTransportError.unexpected(statusCode: http.statusCode)
    }
    return try JSON.decode(data, as: P.Output.self, [.isoDates])
  }

  private func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    let session = self.session()
    if #available(macOS 12.0, iOS 15.0, *) {
      return try await session.data(for: request)
    } else {
      return try await withCheckedThrowingContinuation { continuation in
        session.dataTask(with: request) { data, response, error in
          if let error {
            continuation.resume(throwing: error)
          } else if let data, let response {
            continuation.resume(returning: (data, response))
          } else {
            continuation.resume(throwing: PairQLTransportError.missingDataOrResponse)
          }
        }.resume()
      }
    }
  }
}

public extension PairQLClient where Route: AuthSplitRoute {
  func call<P: Pair>(_ pair: P.Type, unauthed route: Route.Unauthed) async throws -> P.Output {
    try await self.call(pair, .unauthed(route))
  }

  func call<P: Pair>(
    _ pair: P.Type,
    authed route: Route.Authed,
    token: UUID,
  ) async throws -> P.Output {
    try await self.call(pair, .authed(token, route))
  }
}
