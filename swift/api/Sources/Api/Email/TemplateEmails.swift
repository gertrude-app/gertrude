import Foundation

struct InitialSignup: TemplateEmailModel {
  static var subject: String { "Action Required: Confirm your email" }
  static var layout: EmailLayout { .topLogo }
  var dashboardUrl: String
  var token: UUID
  var redirect: String?
  var templateModel: [String: String] { [
    "dashboardUrl": self.dashboardUrl,
    "token": self.token.lowercased,
    "redirect": self.redirect ?? "",
  ] }
}

struct PasswordReset: TemplateEmailModel {
  static var subject: String { "Gertrude app password reset" }
  var dashboardUrl: String
  var token: UUID
  var templateModel: [String: String] { [
    "dashboardUrl": self.dashboardUrl,
    "token": self.token.lowercased,
  ] }
}

struct PasswordResetNoAccount: TemplateEmailModel {
  static var subject: String { "Gertrude App password reset" }
}

struct MagicLink: TemplateEmailModel {
  static var subject: String { "Gertrude App magic link" }
  static var layout: EmailLayout { .topLogo }
  var url: String
  var templateModel: [String: String] { ["url": self.url] }
}

struct MagicLinkNoAccount: TemplateEmailModel {
  static var subject: String { "Gertrude App magic link" }
}

struct NotifySuspendFilter: TemplateEmailModel {
  static var subject: String { "[Gertrude App] New suspend filter request from {{userName}}" }
  var url: String
  var userName: String
  var isFallback: Bool
  var templateModel: [String: String] { [
    "url": self.url,
    "userName": self.userName,
    "fallbackNotice": self.isFallback ? EMAIL_NOTIFICATION_FALLBACK : "",
  ] }
}

struct NotifyUnlockRequest: TemplateEmailModel {
  static var subject: String { "[Gertrude App] {{subject}}" }
  var subject: String
  var url: String
  var userName: String
  var unlockRequests: String
  var isFallback: Bool
  var templateModel: [String: String] { [
    "subject": self.subject,
    "url": self.url,
    "userName": self.userName,
    "unlockRequests": self.unlockRequests,
    "fallbackNotice": self.isFallback ? EMAIL_NOTIFICATION_FALLBACK : "",
  ] }
}

struct NotifySecurityEvent: TemplateEmailModel {
  static var subject: String { "[Gertrude App] Security event {{context}}" }
  var context: String
  var description: String
  var explanation: String
  var templateModel: [String: String] { [
    "context": self.context,
    "description": self.description,
    "explanation": self.explanation,
  ] }
}

struct ReSignup: TemplateEmailModel {
  static var subject: String { "Gertrude Signup Request" }
  var dashboardUrl: String
  var templateModel: [String: String] { ["dashboardUrl": self.dashboardUrl] }
}

struct VerifyNotificationEmail: TemplateEmailModel {
  static var subject: String { "Gertrude app verification code" }
  var code: Int
  var templateModel: [String: String] { ["code": "\(self.code)"] }
}

struct V2_7_0_Announce: TemplateEmailModel {
  static var layout: EmailLayout { .topLogo }
  static var displayName: String { "v2.7.0 Announcement" }
  static var subject: String { "Gertrude v2.7.0 is here!" }
}

struct V2_9_1_Announce: TemplateEmailModel {
  static var layout: EmailLayout { .topLogo }
  static var displayName: String { "v2.9.0 Announcement" }
  static var subject: String { "Gertrude v2.9.0 is here!" }
}

struct IosOnlyMacTrial: TemplateEmailModel {
  static var layout: EmailLayout { .personal }
  static var displayName: String { "iOS-Only Mac Trial" }
  static var subject: String { "The Mac app I built for my own kids" }

  var deviceFragment: String
  var templateModel: [String: String] { ["deviceFragment": self.deviceFragment] }
}

struct MacSetup24h: TemplateEmailModel {
  static var subject: String { "Finish setting up Gertrude on {{childName}}’s Mac" }
  static var alias: String { "mac-setup-24h" }

  var childName: String
  var dashboardUrl: String
  var primaryCtaUrl: String
  var templateModel: [String: String] { [
    "childName": self.childName,
    "dashboardUrl": self.dashboardUrl,
    "primaryCtaUrl": self.primaryCtaUrl,
  ] }
}

struct DailyReviewDigest: TemplateEmailModel {
  static var subject: String { "{{subjectSummary}} to review on Gertrude" }
  static var layout: EmailLayout { .topLogo }

  var subjectSummary: String
  var intro: String
  var childRows: String
  var reviewUrl: String
  var manageUrl: String
  var templateModel: [String: String] { [
    "subjectSummary": self.subjectSummary,
    "intro": self.intro,
    "childRows": self.childRows,
    "reviewUrl": self.reviewUrl,
    "manageUrl": self.manageUrl,
  ] }
}

struct ScreenTimeWarning: TemplateEmailModel {
  static var subject: String {
    "Action needed: Gertrude may not be fully protecting {{childName}}’s computer"
  }

  var childName: String
  var computerName: String
  var templateModel: [String: String] { [
    "childName": self.childName,
    "computerName": self.computerName,
  ] }
}

enum AccountLifecycle {
  struct FullTrialContext: Sendable {
    var billingUrl: String
    var graceEndsOn: String
    var currentTier: StripeSubscription.Tier?
    var pastDueTier: StripeSubscription.Tier?

    var templateModel: [String: String] {
      let planNotice: String
      if let currentTier {
        let features = currentTier == .medium
          ? "Gertrude Music, Gertrude Podcasts, and iPhone/iPad supervision"
          : "Gertrude Podcasts and iPhone/iPad supervision"
        planNotice = "Your \(currentTier.rawValue.capitalized) plan isn’t changing. "
          + "It still includes \(features). You don’t need Full to keep these features."
      } else if let pastDueTier {
        planNotice = "Your \(pastDueTier.rawValue.capitalized) subscription has a separate payment "
          + "issue. Ending this Full trial does not change that. Review your billing settings "
          + "to update your payment method."
      } else {
        planNotice = "Gertrude Blocker’s free features on children’s iPhones and iPads "
          + "remain available."
      }
      return [
        "billingUrl": self.billingUrl,
        "graceEndsOn": self.graceEndsOn,
        "planNotice": planNotice,
        "currentPlan": self.currentTier?.rawValue.capitalized ?? "",
        "pastDuePlan": self.pastDueTier?.rawValue.capitalized ?? "",
      ]
    }
  }

  struct TrialEndingSoon: TemplateEmailModel {
    static var subject: String { "Your Gertrude Full trial ends in {{remainingText}}" }
    var length: Int
    var remaining: Int
    var context: FullTrialContext
    var templateModel: [String: String] {
      self.context.templateModel.merging([
        "length": "\(self.length)",
        "remaining": "\(self.remaining)",
        "remainingText": self.remaining == 1 ? "1 day" : "\(self.remaining) days",
      ]) { _, new in new }
    }
  }

  struct TrialExpired: TemplateEmailModel {
    static var subject: String { "Your Gertrude Full trial has ended" }
    var length: Int
    var context: FullTrialContext
    var templateModel: [String: String] {
      self.context.templateModel.merging(["length": "\(self.length)"]) { _, new in new }
    }
  }

  struct TrialExpiredNoMac: TemplateEmailModel {
    static var subject: String { "Your Gertrude Full trial has ended{{subjectSuffix}}" }
    var context: FullTrialContext
    var templateModel: [String: String] {
      self.context.templateModel.merging([
        "subjectSuffix": self.context.pastDueTier == nil ? " — no action needed" : "",
      ]) { _, new in new }
    }
  }

  struct TrialGraceEnded: TemplateEmailModel {
    static var subject: String { "Your Gertrude Full trial grace period has ended" }
    var context: FullTrialContext
    var templateModel: [String: String] { self.context.templateModel }
  }

  struct OverdueToUnpaid: TemplateEmailModel {
    static var subject: String { "[action required] Gertrude paid features disabled" }
  }

  struct PaidToOverdue: TemplateEmailModel {
    static var subject: String { "[action required] Gertrude payment failed" }
  }
}

let EMAIL_NOTIFICATION_FALLBACK = """
<br /><br /><br />
<p>
  👋 <b>Psst!</b> We're sending this notification <b>as an email</b> to your primary
  account address because you currently <b>don’t have any notifications set up.</b> If
  you’d rather receive events like these delivered as <b>text</b> or
  <b>Slack</b> messages, or to a different email address, you can configure all of that in
  the <a href="https://parents.gertrude.app/settings">Settings</a> screen.
</p>
"""
