// auto-generated, do not edit
import Foundation
import Tagged

extension ClaimIOSDevice.ChildAssignment {
  private struct _NamedCase: Codable {
    var `case`: String
    static func extract(from decoder: Decoder) throws -> String {
      let container = try decoder.singleValueContainer()
      return try container.decode(_NamedCase.self).case
    }
  }

  private struct _TypeScriptDecodeError: Error {
    var message: String
  }

  private struct _CaseNewChild: Codable {
    var `case` = "newChild"
    var name: String
  }

  private struct _CaseExistingChild: Codable {
    var `case` = "existingChild"
    var id: Tagged<Api.Child, UUID>
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .newChild(let name):
      try _CaseNewChild(name: name).encode(to: encoder)
    case .existingChild(let id):
      try _CaseExistingChild(id: id).encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "newChild":
      let value = try container.decode(_CaseNewChild.self)
      self = .newChild(name: value.name)
    case "existingChild":
      let value = try container.decode(_CaseExistingChild.self)
      self = .existingChild(id: value.id)
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension Parent.NotificationMethod.Config {
  private struct _NamedCase: Codable {
    var `case`: String
    static func extract(from decoder: Decoder) throws -> String {
      let container = try decoder.singleValueContainer()
      return try container.decode(_NamedCase.self).case
    }
  }

  private struct _TypeScriptDecodeError: Error {
    var message: String
  }

  private struct _CaseSlack: Codable {
    var `case` = "slack"
    var channelId: String
    var channelName: String
    var token: String
  }

  private struct _CaseEmail: Codable {
    var `case` = "email"
    var email: String
  }

  private struct _CaseText: Codable {
    var `case` = "text"
    var phoneNumber: String
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .slack(let channelId, let channelName, let token):
      try _CaseSlack(channelId: channelId, channelName: channelName, token: token)
        .encode(to: encoder)
    case .email(let email):
      try _CaseEmail(email: email).encode(to: encoder)
    case .text(let phoneNumber):
      try _CaseText(phoneNumber: phoneNumber).encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "slack":
      let value = try container.decode(_CaseSlack.self)
      self = .slack(channelId: value.channelId, channelName: value.channelName, token: value.token)
    case "email":
      let value = try container.decode(_CaseEmail.self)
      self = .email(email: value.email)
    case "text":
      let value = try container.decode(_CaseText.self)
      self = .text(phoneNumber: value.phoneNumber)
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension DecideFilterSuspensionRequest.Decision {
  private struct _NamedCase: Codable {
    var `case`: String
    static func extract(from decoder: Decoder) throws -> String {
      let container = try decoder.singleValueContainer()
      return try container.decode(_NamedCase.self).case
    }
  }

  private struct _TypeScriptDecodeError: Error {
    var message: String
  }

  private struct _CaseAccepted: Codable {
    var `case` = "accepted"
    var durationInSeconds: Int
    var extraMonitoring: String?
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .accepted(let durationInSeconds, let extraMonitoring):
      try _CaseAccepted(durationInSeconds: durationInSeconds, extraMonitoring: extraMonitoring)
        .encode(to: encoder)
    case .rejected:
      try _NamedCase(case: "rejected").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "accepted":
      let value = try container.decode(_CaseAccepted.self)
      self = .accepted(
        durationInSeconds: value.durationInSeconds,
        extraMonitoring: value.extraMonitoring,
      )
    case "rejected":
      self = .rejected
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension GetAdmin.SubscriptionStatus {
  private struct _NamedCase: Codable {
    var `case`: String
    static func extract(from decoder: Decoder) throws -> String {
      let container = try decoder.singleValueContainer()
      return try container.decode(_NamedCase.self).case
    }
  }

  private struct _TypeScriptDecodeError: Error {
    var message: String
  }

  private struct _CaseTrialing: Codable {
    var `case` = "trialing"
    var daysLeft: Int
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .trialing(let daysLeft):
      try _CaseTrialing(daysLeft: daysLeft).encode(to: encoder)
    case .complimentary:
      try _NamedCase(case: "complimentary").encode(to: encoder)
    case .paid:
      try _NamedCase(case: "paid").encode(to: encoder)
    case .overdue:
      try _NamedCase(case: "overdue").encode(to: encoder)
    case .unpaid:
      try _NamedCase(case: "unpaid").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "trialing":
      let value = try container.decode(_CaseTrialing.self)
      self = .trialing(daysLeft: value.daysLeft)
    case "complimentary":
      self = .complimentary
    case "paid":
      self = .paid
    case "overdue":
      self = .overdue
    case "unpaid":
      self = .unpaid
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension SecurityEventsFeed.FeedEvent {
  private struct _NamedCase: Codable {
    var `case`: String
    static func extract(from decoder: Decoder) throws -> String {
      let container = try decoder.singleValueContainer()
      return try container.decode(_NamedCase.self).case
    }
  }

  private struct _TypeScriptDecodeError: Error {
    var message: String
  }

  private struct _CaseChild: Codable {
    var `case` = "child"
    var id: Tagged<Api.SecurityEvent, UUID>
    var childId: Tagged<Api.Child, UUID>
    var childName: String
    var deviceId: Tagged<Api.Computer, UUID>
    var deviceName: String
    var event: String
    var detail: String?
    var explanation: String
    var severity: SecurityEventsFeed.Severity
    var createdAt: Date
  }

  private struct _CaseAdmin: Codable {
    var `case` = "admin"
    var id: Tagged<Api.SecurityEvent, UUID>
    var event: String
    var detail: String?
    var explanation: String
    var severity: SecurityEventsFeed.Severity
    var ipAddress: String?
    var createdAt: Date
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .child(let unflat):
      try _CaseChild(
        id: unflat.id,
        childId: unflat.childId,
        childName: unflat.childName,
        deviceId: unflat.deviceId,
        deviceName: unflat.deviceName,
        event: unflat.event,
        detail: unflat.detail,
        explanation: unflat.explanation,
        severity: unflat.severity,
        createdAt: unflat.createdAt,
      ).encode(to: encoder)
    case .admin(let unflat):
      try _CaseAdmin(
        id: unflat.id,
        event: unflat.event,
        detail: unflat.detail,
        explanation: unflat.explanation,
        severity: unflat.severity,
        ipAddress: unflat.ipAddress,
        createdAt: unflat.createdAt,
      ).encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "child":
      let value = try container.decode(_CaseChild.self)
      self = .child(.init(
        id: value.id,
        childId: value.childId,
        childName: value.childName,
        deviceId: value.deviceId,
        deviceName: value.deviceName,
        event: value.event,
        detail: value.detail,
        explanation: value.explanation,
        severity: value.severity,
        createdAt: value.createdAt,
      ))
    case "admin":
      let value = try container.decode(_CaseAdmin.self)
      self = .admin(.init(
        id: value.id,
        event: value.event,
        detail: value.detail,
        explanation: value.explanation,
        severity: value.severity,
        ipAddress: value.ipAddress,
        createdAt: value.createdAt,
      ))
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

public extension UserActivity.Item {
  private struct _NamedCase: Codable {
    var `case`: String
    static func extract(from decoder: Decoder) throws -> String {
      let container = try decoder.singleValueContainer()
      return try container.decode(_NamedCase.self).case
    }
  }

  private struct _TypeScriptDecodeError: Error {
    var message: String
  }

  private struct _CaseScreenshot: Codable {
    var `case` = "screenshot"
    var id: Tagged<Api.Screenshot, UUID>
    var ids: [Tagged<Api.Screenshot, UUID>]
    var url: String
    var width: Int
    var height: Int
    var duringSuspension: Bool
    var flagged: Bool
    var createdAt: Date
    var deletedAt: Date?
  }

  private struct _CaseKeystrokeLine: Codable {
    var `case` = "keystrokeLine"
    var id: Tagged<Api.KeystrokeLine, UUID>
    var ids: [Tagged<Api.KeystrokeLine, UUID>]
    var appName: String
    var line: String
    var duringSuspension: Bool
    var flagged: Bool
    var createdAt: Date
    var deletedAt: Date?
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .screenshot(let unflat):
      try _CaseScreenshot(
        id: unflat.id,
        ids: unflat.ids,
        url: unflat.url,
        width: unflat.width,
        height: unflat.height,
        duringSuspension: unflat.duringSuspension,
        flagged: unflat.flagged,
        createdAt: unflat.createdAt,
        deletedAt: unflat.deletedAt,
      ).encode(to: encoder)
    case .keystrokeLine(let unflat):
      try _CaseKeystrokeLine(
        id: unflat.id,
        ids: unflat.ids,
        appName: unflat.appName,
        line: unflat.line,
        duringSuspension: unflat.duringSuspension,
        flagged: unflat.flagged,
        createdAt: unflat.createdAt,
        deletedAt: unflat.deletedAt,
      ).encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "screenshot":
      let value = try container.decode(_CaseScreenshot.self)
      self = .screenshot(.init(
        id: value.id,
        ids: value.ids,
        url: value.url,
        width: value.width,
        height: value.height,
        duringSuspension: value.duringSuspension,
        flagged: value.flagged,
        createdAt: value.createdAt,
        deletedAt: value.deletedAt,
      ))
    case "keystrokeLine":
      let value = try container.decode(_CaseKeystrokeLine.self)
      self = .keystrokeLine(.init(
        id: value.id,
        ids: value.ids,
        appName: value.appName,
        line: value.line,
        duringSuspension: value.duringSuspension,
        flagged: value.flagged,
        createdAt: value.createdAt,
        deletedAt: value.deletedAt,
      ))
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension ChildComputerStatus {
  private struct _NamedCase: Codable {
    var `case`: String
    static func extract(from decoder: Decoder) throws -> String {
      let container = try decoder.singleValueContainer()
      return try container.decode(_NamedCase.self).case
    }
  }

  private struct _TypeScriptDecodeError: Error {
    var message: String
  }

  private struct _CaseFilterSuspended: Codable {
    var `case` = "filterSuspended"
    var resuming: Date?
  }

  private struct _CaseDowntime: Codable {
    var `case` = "downtime"
    var ending: Date?
  }

  private struct _CaseDowntimePaused: Codable {
    var `case` = "downtimePaused"
    var resuming: Date?
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .filterSuspended(let resuming):
      try _CaseFilterSuspended(resuming: resuming).encode(to: encoder)
    case .downtime(let ending):
      try _CaseDowntime(ending: ending).encode(to: encoder)
    case .downtimePaused(let resuming):
      try _CaseDowntimePaused(resuming: resuming).encode(to: encoder)
    case .offline:
      try _NamedCase(case: "offline").encode(to: encoder)
    case .filterOff:
      try _NamedCase(case: "filterOff").encode(to: encoder)
    case .filterOn:
      try _NamedCase(case: "filterOn").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "filterSuspended":
      let value = try container.decode(_CaseFilterSuspended.self)
      self = .filterSuspended(resuming: value.resuming)
    case "downtime":
      let value = try container.decode(_CaseDowntime.self)
      self = .downtime(ending: value.ending)
    case "downtimePaused":
      let value = try container.decode(_CaseDowntimePaused.self)
      self = .downtimePaused(resuming: value.resuming)
    case "offline":
      self = .offline
    case "filterOff":
      self = .filterOff
    case "filterOn":
      self = .filterOn
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension Plan {
  private struct _NamedCase: Codable {
    var `case`: String
    static func extract(from decoder: Decoder) throws -> String {
      let container = try decoder.singleValueContainer()
      return try container.decode(_NamedCase.self).case
    }
  }

  private struct _TypeScriptDecodeError: Error {
    var message: String
  }

  private struct _CaseFree: Codable {
    var `case` = "free"
    var kind: Plan.FreeKind
  }

  private struct _CaseLight: Codable {
    var `case` = "light"
    var status: BillingStatus.Light
  }

  private struct _CaseFull: Codable {
    var `case` = "full"
    var status: BillingStatus.Full
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .free(let kind):
      try _CaseFree(kind: kind).encode(to: encoder)
    case .light(let status):
      try _CaseLight(status: status).encode(to: encoder)
    case .full(let status):
      try _CaseFull(status: status).encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "free":
      let value = try container.decode(_CaseFree.self)
      self = .free(kind: value.kind)
    case "light":
      let value = try container.decode(_CaseLight.self)
      self = .light(status: value.status)
    case "full":
      let value = try container.decode(_CaseFull.self)
      self = .full(status: value.status)
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension Plan.FreeKind {
  private struct _NamedCase: Codable {
    var `case`: String
    static func extract(from decoder: Decoder) throws -> String {
      let container = try decoder.singleValueContainer()
      return try container.decode(_NamedCase.self).case
    }
  }

  private struct _TypeScriptDecodeError: Error {
    var message: String
  }

  private struct _CaseLapsedLight: Codable {
    var `case` = "lapsedLight"
    var stripeId: Tagged<Api.Subscription, Swift.String>
    var hasTrialedFull: Bool
  }

  private struct _CaseLapsedFull: Codable {
    var `case` = "lapsedFull"
    var stripeId: Tagged<Api.Subscription, Swift.String>
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .lapsedLight(let stripeId, let hasTrialedFull):
      try _CaseLapsedLight(stripeId: stripeId, hasTrialedFull: hasTrialedFull).encode(to: encoder)
    case .lapsedFull(let stripeId):
      try _CaseLapsedFull(stripeId: stripeId).encode(to: encoder)
    case .standard:
      try _NamedCase(case: "standard").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "lapsedLight":
      let value = try container.decode(_CaseLapsedLight.self)
      self = .lapsedLight(stripeId: value.stripeId, hasTrialedFull: value.hasTrialedFull)
    case "lapsedFull":
      let value = try container.decode(_CaseLapsedFull.self)
      self = .lapsedFull(stripeId: value.stripeId)
    case "standard":
      self = .standard
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension BillingStatus.Full {
  private struct _NamedCase: Codable {
    var `case`: String
    static func extract(from decoder: Decoder) throws -> String {
      let container = try decoder.singleValueContainer()
      return try container.decode(_NamedCase.self).case
    }
  }

  private struct _TypeScriptDecodeError: Error {
    var message: String
  }

  private struct _CaseTrialing: Codable {
    var `case` = "trialing"
    var kind: BillingStatus.Full.TrialKind
    var until: Date
  }

  private struct _CaseTrialExpired: Codable {
    var `case` = "trialExpired"
    var kind: BillingStatus.Full.TrialKind
  }

  private struct _CasePaid: Codable {
    var `case` = "paid"
    var stripeId: Tagged<Api.Subscription, Swift.String>
    var monthlyPriceInCents: Int
  }

  private struct _CaseOverdue: Codable {
    var `case` = "overdue"
    var stripeId: Tagged<Api.Subscription, Swift.String>
    var monthlyPriceInCents: Int
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .trialing(let kind, let until):
      try _CaseTrialing(kind: kind, until: until).encode(to: encoder)
    case .trialExpired(let kind):
      try _CaseTrialExpired(kind: kind).encode(to: encoder)
    case .paid(let stripeId, let monthlyPriceInCents):
      try _CasePaid(stripeId: stripeId, monthlyPriceInCents: monthlyPriceInCents)
        .encode(to: encoder)
    case .overdue(let stripeId, let monthlyPriceInCents):
      try _CaseOverdue(stripeId: stripeId, monthlyPriceInCents: monthlyPriceInCents)
        .encode(to: encoder)
    case .complimentary:
      try _NamedCase(case: "complimentary").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "trialing":
      let value = try container.decode(_CaseTrialing.self)
      self = .trialing(kind: value.kind, until: value.until)
    case "trialExpired":
      let value = try container.decode(_CaseTrialExpired.self)
      self = .trialExpired(kind: value.kind)
    case "paid":
      let value = try container.decode(_CasePaid.self)
      self = .paid(stripeId: value.stripeId, monthlyPriceInCents: value.monthlyPriceInCents)
    case "overdue":
      let value = try container.decode(_CaseOverdue.self)
      self = .overdue(stripeId: value.stripeId, monthlyPriceInCents: value.monthlyPriceInCents)
    case "complimentary":
      self = .complimentary
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension BillingStatus.Full.TrialKind {
  private struct _NamedCase: Codable {
    var `case`: String
    static func extract(from decoder: Decoder) throws -> String {
      let container = try decoder.singleValueContainer()
      return try container.decode(_NamedCase.self).case
    }
  }

  private struct _TypeScriptDecodeError: Error {
    var message: String
  }

  private struct _CaseFromLight: Codable {
    var `case` = "fromLight"
    var stripeId: Tagged<Api.Subscription, Swift.String>
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .fromLight(let stripeId):
      try _CaseFromLight(stripeId: stripeId).encode(to: encoder)
    case .full:
      try _NamedCase(case: "full").encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "fromLight":
      let value = try container.decode(_CaseFromLight.self)
      self = .fromLight(stripeId: value.stripeId)
    case "full":
      self = .full
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}

extension BillingStatus.Light {
  private struct _NamedCase: Codable {
    var `case`: String
    static func extract(from decoder: Decoder) throws -> String {
      let container = try decoder.singleValueContainer()
      return try container.decode(_NamedCase.self).case
    }
  }

  private struct _TypeScriptDecodeError: Error {
    var message: String
  }

  private struct _CasePaid: Codable {
    var `case` = "paid"
    var stripeId: Tagged<Api.Subscription, Swift.String>
    var hasTrialedFull: Bool
  }

  private struct _CaseOverdue: Codable {
    var `case` = "overdue"
    var stripeId: Tagged<Api.Subscription, Swift.String>
    var hasTrialedFull: Bool
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .paid(let stripeId, let hasTrialedFull):
      try _CasePaid(stripeId: stripeId, hasTrialedFull: hasTrialedFull).encode(to: encoder)
    case .overdue(let stripeId, let hasTrialedFull):
      try _CaseOverdue(stripeId: stripeId, hasTrialedFull: hasTrialedFull).encode(to: encoder)
    }
  }

  init(from decoder: Decoder) throws {
    let caseName = try _NamedCase.extract(from: decoder)
    let container = try decoder.singleValueContainer()
    switch caseName {
    case "paid":
      let value = try container.decode(_CasePaid.self)
      self = .paid(stripeId: value.stripeId, hasTrialedFull: value.hasTrialedFull)
    case "overdue":
      let value = try container.decode(_CaseOverdue.self)
      self = .overdue(stripeId: value.stripeId, hasTrialedFull: value.hasTrialedFull)
    default:
      throw _TypeScriptDecodeError(message: "Unexpected case name: `\(caseName)`")
    }
  }
}
