import Dependencies
import Foundation
import XHttp

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct KeychainCrawlerClient: Sendable {
  var validateDomain: @Sendable (_ domain: String) async throws -> Bool
  var analyze: @Sendable (_ domain: String) async throws -> CrawlerResponse
}

struct CrawlerResponse: Decodable, Equatable, Sendable {
  var name: String
  var description: String
  var domain: String
  var recommendedKeys: [RecommendedKey]
  var rejectedDomains: [RejectedDomain]
  var llmFlagged: [LlmFlagged]
  var warnings: [String]

  struct RecommendedKey: Decodable, Equatable, Sendable {
    var type: String
    var domain: String
    var comment: String?
  }

  struct RejectedDomain: Decodable, Equatable, Sendable {
    var domain: String
    var reason: String
  }

  struct LlmFlagged: Decodable, Equatable, Sendable {
    var domain: String
    var concern: String
  }
}

extension KeychainCrawlerClient: DependencyKey {
  static var liveValue: KeychainCrawlerClient {
    .init(validateDomain: { domain in
      guard let url = URL(string: "https://\(domain)") else { return false }
      var request = URLRequest(url: url)
      request.httpMethod = "GET"
      request.timeoutInterval = 8
      request.setValue(
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        forHTTPHeaderField: "User-Agent",
      )
      request.setValue(
        "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
        forHTTPHeaderField: "Accept",
      )
      request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
      return await ReachabilityProbe.probe(request)
    }, analyze: { domain in
      let env = get(dependency: \.env.keychainCrawler)
      let url = "\(env.url)/analyze"
      return try await HTTP.sendJson(
        body: ["url": domain],
        to: url,
        decoding: CrawlerResponse.self,
        auth: .bearer(env.authToken),
        keyDecodingStrategy: .convertFromSnakeCase,
        timeoutInterval: .seconds(120),
      )
    })
  }
}

extension KeychainCrawlerClient: TestDependencyKey {
  static var testValue: KeychainCrawlerClient {
    .init(
      validateDomain: unimplemented("KeychainCrawlerClient.validateDomain()", placeholder: true),
      analyze: unimplemented("KeychainCrawlerClient.analyze()"),
    )
  }
}

extension DependencyValues {
  var keychainCrawler: KeychainCrawlerClient {
    get { self[KeychainCrawlerClient.self] }
    set { self[KeychainCrawlerClient.self] = newValue }
  }
}

private final class ReachabilityProbe: NSObject, URLSessionDataDelegate, @unchecked Sendable {
  private var continuation: CheckedContinuation<Bool, Never>?
  private var receivedHttpResponse = false
  private let lock = NSLock()

  static func probe(_ request: URLRequest) async -> Bool {
    let delegate = ReachabilityProbe()
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 8
    config.timeoutIntervalForResource = 8
    let session = URLSession(
      configuration: config,
      delegate: delegate,
      delegateQueue: nil,
    )
    defer { session.finishTasksAndInvalidate() }
    return await withCheckedContinuation { continuation in
      delegate.lock.lock()
      delegate.continuation = continuation
      delegate.lock.unlock()
      session.dataTask(with: request).resume()
    }
  }

  func urlSession(
    _ session: URLSession,
    dataTask: URLSessionDataTask,
    didReceive response: URLResponse,
    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void,
  ) {
    self.lock.lock()
    if response is HTTPURLResponse {
      self.receivedHttpResponse = true
    }
    self.lock.unlock()
    completionHandler(.cancel)
  }

  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didCompleteWithError error: Error?,
  ) {
    self.lock.lock()
    let success = self.receivedHttpResponse
    let cont = self.continuation
    self.continuation = nil
    self.lock.unlock()
    cont?.resume(returning: success)
  }
}
