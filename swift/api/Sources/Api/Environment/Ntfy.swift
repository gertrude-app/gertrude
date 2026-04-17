import Dependencies
import Foundation
import XHttp

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct NtfyClient: Sendable {
  var send: @Sendable (
    _ topic: String,
    _ title: String?,
    _ message: String,
    _ click: String?,
  ) async throws -> Void
}

struct NtfyError: Error, CustomStringConvertible {
  let statusCode: Int
  let body: String

  var description: String {
    "Ntfy error (status \(self.statusCode)): \(self.body)"
  }
}

extension NtfyClient: DependencyKey {
  static var liveValue: NtfyClient {
    .init { topic, title, message, click in
      var request = URLRequest(url: URL(string: "https://ntfy.sh/\(topic)")!)
      request.httpMethod = "POST"
      if let title {
        request.setValue(title, forHTTPHeaderField: "Title")
      }
      if let click {
        request.setValue(click, forHTTPHeaderField: "Click")
        if let actions = Self.actionsHeader(click: click) {
          request.setValue(actions, forHTTPHeaderField: "Actions")
        }
      }
      request.httpBody = message.data(using: .utf8)

      let (data, response) = try await XHttp.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else {
        throw NtfyError(statusCode: 0, body: "Invalid response type")
      }
      guard (200 ... 299).contains(httpResponse.statusCode) else {
        let bodyString = String(data: data, encoding: .utf8) ?? "<decode err>"
        throw NtfyError(statusCode: httpResponse.statusCode, body: bodyString)
      }
    }
  }
}

extension DependencyValues {
  var ntfy: NtfyClient {
    get { self[NtfyClient.self] }
    set { self[NtfyClient.self] = newValue }
  }
}

extension NtfyClient: TestDependencyKey {
  static var testValue: NtfyClient {
    .init(send: unimplemented("NtfyClient.send(_:_:_:_:)"))
  }
}

extension NtfyClient {
  private static let topicAlphabet = Array(
    "23456789abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ",
  )

  static func actionsHeader(click: String?) -> String? {
    guard let click, !click.isEmpty else { return nil }
    return "view, Open, \(click)"
  }

  static func generateTopic(randomLength: Int = 10) -> String {
    let random = String((0 ..< randomLength).map { _ in self.topicAlphabet.randomElement()! })
    return "gertrude-\(random)"
  }
}
