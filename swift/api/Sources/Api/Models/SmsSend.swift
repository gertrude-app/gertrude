import Dependencies
import Duet
import Foundation

struct SmsSend: Codable, Sendable {
  var id: Id
  var parentId: Parent.Id
  var trigger: String
  var countryCode: String
  var twilioMessageSid: String?
  var numSegments: Int?
  var createdAt = Date()

  init(
    id: Id = .init(),
    parentId: Parent.Id,
    trigger: String,
    countryCode: String,
    twilioMessageSid: String? = nil,
    numSegments: Int? = nil,
  ) {
    self.id = id
    self.parentId = parentId
    self.trigger = trigger
    self.countryCode = countryCode
    self.twilioMessageSid = twilioMessageSid
    self.numSegments = numSegments
  }
}

extension SmsSend {
  /// Fire-and-forget audit write. DB failures are logged to #unexpectedErrors;
  /// never throws, never awaits — safe to call from hot notification paths.
  static func createDetached(
    parentId: Parent.Id,
    trigger: String,
    phoneNumber: String,
    twilioResult: TwilioSmsClient.SendResult,
  ) {
    Task {
      do {
        try await get(dependency: \.db).create(SmsSend(
          parentId: parentId,
          trigger: trigger,
          countryCode: extractCountryCode(from: phoneNumber),
          twilioMessageSid: twilioResult.messageSid,
          numSegments: twilioResult.numSegments,
        ))
      } catch {
        slackErr("9a63bf38 \(trigger), \(twilioResult.messageSid), \(error)")
      }
      if let segments = twilioResult.numSegments, segments > 1 {
        slackErr("d6cf22c5 \(trigger), \(segments), \(twilioResult.messageSid)")
      }
    }
  }
}

extension String {
  func truncatedForSms(max: Int = 25) -> String {
    self.count <= max ? self : "\(self.prefix(max - 2)).."
  }
}

func extractCountryCode(from phoneNumber: String) -> String {
  var number = phoneNumber
  if number.hasPrefix("+") {
    number = String(number.dropFirst())
  }
  if number.hasPrefix("1") || number.hasPrefix("7") {
    return String(number.prefix(1))
  }
  return String(number.prefix(2))
}
