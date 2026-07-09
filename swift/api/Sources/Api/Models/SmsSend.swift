import Dependencies
import DuetSQL
import Foundation

@DuetModel(schema: "system", table: "sms_sends")
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

  func sanitizedForSms() -> String {
    var result = ""
    for scalar in self.unicodeScalars {
      if let replacement = nonGsm7Replacements[scalar] {
        result += replacement
      } else if scalar.isASCII || gsm7BasicChars.contains(scalar) {
        result.unicodeScalars.append(scalar)
      } else if scalar.isLatinLetter,
                let base = scalar.decomposed.first,
                base.isASCII,
                base.isLatinLetter {
        result.unicodeScalars.append(base)
      } else {
        result.unicodeScalars.append(scalar)
      }
    }
    return result
  }
}

private let nonGsm7Replacements: [Unicode.Scalar: String] = [
  "\u{2013}": "-", // en-dash
  "\u{2014}": "-", // em-dash
  "\u{2015}": "-", // horizontal bar
  "\u{2018}": "'", // left single quote
  "\u{2019}": "'", // right single quote
  "\u{201A}": "'", // single low-9 quote
  "\u{201B}": "'", // single high-reversed-9 quote
  "\u{201C}": "\"", // left double quote
  "\u{201D}": "\"", // right double quote
  "\u{201E}": "\"", // double low-9 quote
  "\u{201F}": "\"", // double high-reversed-9 quote
  "\u{2026}": "...", // ellipsis
  "\u{00A0}": " ", // non-breaking space
  "\u{2212}": "-", // minus sign
  "\u{2010}": "-", // hyphen
  "\u{2011}": "-", // non-breaking hyphen
]

private let gsm7BasicChars: Set<Unicode.Scalar> = [
  "\u{00A3}", // £
  "\u{00A5}", // ¥
  "\u{00E8}", // è
  "\u{00E9}", // é
  "\u{00F9}", // ù
  "\u{00EC}", // ì
  "\u{00F2}", // ò
  "\u{00C7}", // Ç
  "\u{00D8}", // Ø
  "\u{00F8}", // ø
  "\u{00C5}", // Å
  "\u{00E5}", // å
  "\u{0394}", // Δ
  "\u{03A6}", // Φ
  "\u{0393}", // Γ
  "\u{039B}", // Λ
  "\u{03A9}", // Ω
  "\u{03A0}", // Π
  "\u{03A8}", // Ψ
  "\u{03A3}", // Σ
  "\u{0398}", // Θ
  "\u{039E}", // Ξ
  "\u{00C6}", // Æ
  "\u{00E6}", // æ
  "\u{00DF}", // ß
  "\u{00C9}", // É
  "\u{00A4}", // ¤
  "\u{00A1}", // ¡
  "\u{00C4}", // Ä
  "\u{00D6}", // Ö
  "\u{00D1}", // Ñ
  "\u{00DC}", // Ü
  "\u{00A7}", // §
  "\u{00BF}", // ¿
  "\u{00E4}", // ä
  "\u{00F6}", // ö
  "\u{00F1}", // ñ
  "\u{00FC}", // ü
  "\u{00E0}", // à
  "\u{00C0}", // À (extension char but commonly accepted)
  "\u{00E7}", // ç
]

private extension Unicode.Scalar {
  var decomposed: [Unicode.Scalar] {
    var result: [Unicode.Scalar] = []
    for scalar in String(self).decomposedStringWithCanonicalMapping.unicodeScalars {
      result.append(scalar)
    }
    return result
  }

  var isLatinLetter: Bool {
    switch self.properties.generalCategory {
    case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter:
      true
    default:
      false
    }
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
