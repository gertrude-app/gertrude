import Dependencies
import Foundation
import Gertie

extension AdminEvent.SecurityEventPayload: AdminNotifying {
  static var smsSendTrigger: String { "securityEvent" }
  var desc: String {
    let eventWords: String = switch source {
    case .macApp(_, let event):
      event.toWords
    case .dashboard(let event):
      event.toWords
    }
    return "\(eventWords)\(detail.map { ": \($0)" } ?? "")"
  }

  var explanation: String {
    switch source {
    case .macApp(_, let event):
      event.explanation
    case .dashboard(let event):
      event.explanation
    }
  }

  var severity: Gertie.SecurityEvent.Severity {
    switch source {
    case .macApp(_, let event):
      event.severity
    case .dashboard(let event):
      event.severity
    }
  }

  var context: String {
    switch source {
    case .macApp(let childName, _):
      "for child \(childName)"
    case .dashboard:
      "in parent website"
    }
  }

  func sendNtfy(topic: String) async throws {
    let url = "https://parents.gertrude.app/security-events"
    let shortUrl = await self.shortUrl(for: url)
    let message = """
    Security event \(self.context): \(self.desc).

    \(self.explanation)

    \(shortUrl)
    """
    try await with(dependency: \.ntfy)
      .send(topic, "Gertrude security event", message, shortUrl)
  }

  func sendText(to phoneNumber: String) async throws -> TwilioSmsClient.SendResult {
    let who = switch source {
    case .macApp(let childName, _):
      "for \(childName)"
    case .dashboard:
      "in parent website"
    }
    let message = "Gertrude security event \(who): \(desc.truncatedForSms(max: 67)).\n\n\(ShortUrl.securityEvents)"
    return try await with(dependency: \.twilio)
      .send(Text(to: .init(phoneNumber), message: message))
  }

  func sendEmail(to address: String, isFallback: Bool = false) async throws {
    try await with(dependency: \.postmark)
      .send(template: .notifySecurityEvent(
        to: address,
        model: .init(
          context: self.context,
          description: self.desc,
          explanation: self.explanation,
        ),
      ))
  }

  func sendSlack(channel: String, token: String) async throws {
    let text = """
    Security event: `\(desc)` \(context).

    \(explanation)
    """
    try await with(dependency: \.slack)
      .send(Slack(text: text, channel: channel, token: token))
  }
}
