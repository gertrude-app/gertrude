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

  func sendText(to phoneNumber: String) async throws -> TwilioSmsClient.SendResult {
    let message = """
    [Gertrude] Security event: "\(desc)" \(context).

    \(explanation)
    """

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
