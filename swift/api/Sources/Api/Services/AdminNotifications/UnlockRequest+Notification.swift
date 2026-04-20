import Dependencies
import Foundation

extension AdminEvent.UnlockRequestSubmitted: AdminNotifying {
  static var smsSendTrigger: String { "unlockRequest" }

  func sendNtfy(topic: String) async throws {
    let request = requestIds.count > 1
      ? "\(requestIds.count) unlock requests"
      : "unlock request"
    let shortUrl = await self.shortUrl(for: self.url)
    let message = "\(request.capitalized) from \(self.userName)\n\n\(shortUrl)"
    try await with(dependency: \.ntfy)
      .send(topic, "Gertrude", message, shortUrl)
  }

  func sendText(to phoneNumber: String) async throws -> TwilioSmsClient.SendResult {
    let request = requestIds.count > 1
      ? "\(requestIds.count) unlock requests"
      : "unlock request"
    let linkUrl = await (try? with(dependency: \.db)
      .create(ShortUrl(target: self.url)).publicUrl) ?? self.url
    let name = self.userName.sanitizedForSms()
    let message = "Gertrude: \(request) from \(name).\n\n\(linkUrl)"
    return try await with(dependency: \.twilio)
      .send(Text(to: .init(phoneNumber), message: message))
  }

  func sendSlack(channel: String, token: String) async throws {
    let newRequest =
      requestIds.count > 1
        ? "\(requestIds.count) new *unlock requests*"
        : "New *unlock request*"

    let text = """
    \(newRequest) from user `\(userName)`.\
     \(Slack.link(to: url, withText: "Click here")) to view the details and approve or deny.
    """

    try await with(dependency: \.slack)
      .send(Slack(text: text, channel: channel, token: token))
  }

  func sendEmail(to address: String, isFallback: Bool = false) async throws {
    let subject = requestIds.count > 1
      ? "\(requestIds.count) new unlock requests from \(self.userName)"
      : "New unlock request from \(self.userName)"

    let unlockRequests = requestIds.count > 1
      ? "\(requestIds.count) new <b>unlock requests</b>"
      : "a new <b>unlock request</b>"

    try await with(dependency: \.postmark)
      .send(template: .notifyUnlockRequest(
        to: address,
        model: .init(
          subject: subject,
          url: self.url,
          userName: self.userName,
          unlockRequests: unlockRequests,
          isFallback: isFallback,
        ),
      ))
  }
}

// helpers

extension AdminEvent.UnlockRequestSubmitted {
  private var url: String {
    "\(dashboardUrl)/children/\(userId.lowercased)/unlock-requests"
  }
}
