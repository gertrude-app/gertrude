import Foundation

struct RemotePolicyDecision: Decodable, Sendable {
  let allow: Bool
  let reason: String
}

actor IPCPolicyClient {
  let baseURL: URL
  let session: URLSession

  init(baseURL: URL = URL(string: "http://127.0.0.1:7717")!) {
    self.baseURL = baseURL
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 0.5
    config.timeoutIntervalForResource = 0.5
    config.urlCache = nil
    config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    config.httpAdditionalHeaders = ["Connection": "close"]
    self.session = URLSession(configuration: config)
  }

  func decide(host: String, kind: String) async -> (RemotePolicyDecision, TimeInterval)? {
    var comps = URLComponents(url: self.baseURL, resolvingAgainstBaseURL: false)!
    comps.path = "/allow"
    comps.queryItems = [
      URLQueryItem(name: "host", value: host),
      URLQueryItem(name: "kind", value: kind),
    ]
    guard let url = comps.url else { return nil }
    let start = Date()
    do {
      let (data, _) = try await self.session.data(from: url)
      let elapsed = Date().timeIntervalSince(start)
      let decoded = try JSONDecoder().decode(RemotePolicyDecision.self, from: data)
      return (decoded, elapsed)
    } catch {
      return nil
    }
  }
}
