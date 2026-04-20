import Dependencies
import Foundation

extension AdminEvent.SuspendFilterRequestSubmitted: AdminNotifying {
  static var smsSendTrigger: String { "suspendFilterRequest" }

  func sendEmail(to address: String, isFallback: Bool = false) async throws {
    try await with(dependency: \.postmark)
      .send(template: .notifySuspendFilter(
        to: address,
        model: .init(url: self.url, userName: self.childName, isFallback: isFallback),
      ))
  }

  func sendSlack(channel: String, token: String) async throws {
    let text = """
    New *suspend filter request* from user `\(self.childName)`.\
     \(Slack.link(to: self.url, withText: "Click here")) to view the details and approve or deny.
    """
    try await with(dependency: \.slack)
      .send(Slack(text: text, channel: channel, token: token))
  }

  func sendNtfy(topic: String) async throws {
    let shortUrl = await self.shortUrl(for: self.url)
    let message = "Suspend filter request from \(self.childName)\n\n\(shortUrl)"
    try await with(dependency: \.ntfy)
      .send(topic, "Gertrude", message, shortUrl)
  }

  func sendText(to phoneNumber: String) async throws -> TwilioSmsClient.SendResult {
    let linkUrl = await (try? with(dependency: \.db)
      .create(ShortUrl(target: self.url)).publicUrl) ?? self.url
    let message = "Gertrude: suspend filter request from \(self.childName).\n\n\(linkUrl)"
    return try await with(dependency: \.twilio)
      .send(Text(to: .init(rawValue: phoneNumber), message: message))
  }

  var url: String {
    switch self.context {
    case .macapp(computerUserId: let computerUserId, requestId: let requestId):
      "\(dashboardUrl)/children/\(computerUserId.lowercased)/suspend-filter-requests/\(requestId.lowercased)"
    case .iosapp:
      "\(dashboardUrl)/TODO" // TODO: ios filter suspension urls
    }
  }
}
