import Dependencies
import Vapor
import XPostmark

struct PostmarkClient: Sendable {
  var _sendEmail:
    @Sendable (XPostmark.Email) async
    -> Result<Void, XPostmark.Client.Error>
  var _sendTemplateEmail:
    @Sendable (XPostmark.TemplateEmail) async
    -> Result<Void, XPostmark.Client.Error>
  var _sendTemplateEmailBatch:
    @Sendable ([XPostmark.TemplateEmail]) async
    -> Result<[Result<Void, XPostmark.Client.BatchEmail.Error>], XPostmark.Client.Error>
}

extension PostmarkClient: DependencyKey {
  static var liveValue: PostmarkClient {
    let env = Env.fromProcess(mode: try? Vapor.Environment.detect())
    let pmClient = XPostmark.Client.live(apiKey: env.postmark.apiKey)
    return .init(
      _sendEmail: pmClient.sendEmail,
      _sendTemplateEmail: { email in
        if isCypressTestAddress(email.to) {
          with(dependency: \.logger)
            .info("Not sending test email: `\(email.templateAlias)` to: `\(email.to)`")
          return .success(())
        } else {
          return await pmClient.sendTemplateEmail(email)
        }
      },
      _sendTemplateEmailBatch: pmClient.sendTemplateEmailBatch,
    )
  }
}

extension DependencyValues {
  var postmark: PostmarkClient {
    get { self[PostmarkClient.self] }
    set { self[PostmarkClient.self] = newValue }
  }
}

extension PostmarkClient {
  func send(template email: Api.TemplateEmail) async throws {
    var templateModel = email.model.templateModel

    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy"
    templateModel["currentYear"] = formatter.string(from: date)

    var templateEmail = XPostmark.TemplateEmail(
      to: "",
      from: "Gertrude App <noreply@gertrude.app>",
      replyTo: get(dependency: \.env.primarySupportEmail),
      templateAlias: email.model.templateAlias,
      templateModel: templateModel,
      messageStream: nil,
    )
    switch email {
    case .initialSignup(let recipient, _),
         .reSignup(let recipient, _),
         .trialEndingSoon(let recipient, _),
         .trialExpired(let recipient, _),
         .overdueToUnpaid(let recipient, _),
         .paidToOverdue(let recipient, _),
         .passwordReset(let recipient, _),
         .passwordResetNoAccount(let recipient, _),
         .magicLink(let recipient, _),
         .magicLinkNoAccount(let recipient, _),
         .notifySuspendFilter(let recipient, _),
         .notifyUnlockRequest(let recipient, _),
         .notifySecurityEvent(let recipient, _),
         .verifyNotificationEmail(let recipient, _),
         .screenTimeWarning(let recipient, _),
         .iosOnlyMacTrial(let recipient, _),
         .macSetup24h(let recipient, _):
      templateEmail.to = recipient
      templateEmail.templateModel["subjref"] = "".withEmailSubjectDisambiguator
      try await self._sendTemplateEmail(templateEmail)
        .loggingFailure(of: templateEmail.templateAlias, to: recipient)
    case .v2_7_0_Announce:
      break
    case .v2_9_1_Announce(let recipients, _, let dryRun):
      guard get(dependency: \.env).mode == .dev else {
        throw Abort(.forbidden)
      }
      await print(
        self._sendTemplateEmailBatch(
          recipients.map {
            var batchEmail = templateEmail
            batchEmail.to = $0
            batchEmail.templateModel["subjref"] = dryRun ? "".withEmailSubjectDisambiguator : ""
            return batchEmail
          }))
    }
  }

  func sendMarketingBatch(
    templateAlias: String,
    campaignSlug: String,
    recipients: [(email: String, model: [String: String])],
    from: String = "Gertrude App <noreply@gertrude.app>",
    replyTo: String? = nil,
  ) async -> [Result<Void, XPostmark.Client.BatchEmail.Error>] {
    let env = get(dependency: \.env)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy"
    let currentYear = formatter.string(from: Date())
    let effectiveReplyTo = replyTo ?? env.primarySupportEmail

    let physicalAddress = env.get("MARKETING_PHYSICAL_ADDRESS")
    let batch = recipients.map { recipient in
      var model = recipient.model
      model["currentYear"] = currentYear
      model["subjref"] = ""
      if let physicalAddress {
        model["physicalAddress"] = physicalAddress
      }
      return XPostmark.TemplateEmail(
        to: recipient.email,
        from: from,
        replyTo: effectiveReplyTo,
        templateAlias: templateAlias,
        templateModel: model,
        messageStream: "broadcast",
        tag: campaignSlug,
      )
    }

    var results: [Result<Void, XPostmark.Client.BatchEmail.Error>] = []
    for chunk in batch.chunked(into: 450) {
      switch await self._sendTemplateEmailBatch(chunk) {
      case .failure(let err):
        with(dependency: \.logger)
          .error("Error sending marketing batch '\(campaignSlug)': \(err)")
        await with(dependency: \.slack)
          .error("Error sending marketing batch `\(campaignSlug)`: \(String(reflecting: err))")
        results.append(
          contentsOf: chunk.map { _ in
            .failure(.init(errorCode: err.errorCode, message: err.message))
          })
      case .success(let chunkResults):
        results.append(contentsOf: chunkResults)
      }
    }
    return results
  }

  func send(to: String, replyTo: String? = nil, subject: String, html: String) async throws {
    try await self._sendEmail(
      .init(
        to: to,
        from: "Gertrude App <noreply@gertrude.app>",
        replyTo: replyTo,
        subject: subject.withEmailSubjectDisambiguator,
        htmlBody: html,
      ),
    ).loggingFailure()
  }

  func toSuperAdmin(_ email: XPostmark.Email) {
    Task {
      if get(dependency: \.env).mode == .prod {
        try await self._sendEmail(email).loggingFailure()
      }
    }
  }

  func toSuperAdmin(_ subject: String, _ html: String) {
    self.toSuperAdmin(
      .init(
        to: get(dependency: \.env).superAdminEmail,
        from: "Gertrude App <noreply@gertrude.app>",
        replyTo: nil,
        subject: subject.withEmailSubjectDisambiguator,
        htmlBody: html,
      ))
  }

  func unexpected(_ id: String, _ detail: String = "") {
    let search = "https://github.com/search?q=repo%3Agertrude-app%2Fgertrude%20\(id)&type=code"
    return self.toSuperAdmin(
      .init(
        to: get(dependency: \.env).superAdminEmail,
        from: "Gertrude App <noreply@gertrude.app>",
        subject: "Gertrude API unexpected event".withEmailSubjectDisambiguator,
        htmlBody: "id: <code><a href='\(search)'>\(id)</a></code><br/><br/>\(detail)",
      ))
  }
}

extension Result where Success == Void, Failure == XPostmark.Client.Error {
  func loggingFailure() async throws {
    switch self {
    case .failure(let err):
      with(dependency: \.logger).error("Error sending email: \(err)")
      await with(dependency: \.slack).error("Error sending email: \(err)")
      throw err
    case .success:
      break
    }
  }

  func loggingFailure(of template: String, to recipient: String) async throws {
    switch self {
    case .failure(let err):
      with(dependency: \.logger)
        .error("Error sending email \(template) to \(recipient): \(err)")
      await with(dependency: \.slack).error(
        """
          Error sending `\(template)` email to `\(recipient)`
          Detail: \(String(reflecting: err))
        """)
      throw err
    case .success:
      break
    }
  }
}

func isCypressTestAddress(_ email: String) -> Bool {
  email.starts(with: "e2e-user-") && email.hasSuffix("@gertrude.app")
}

func isProdSmokeTestAddress(_ email: String) -> Bool {
  email.contains(".smoke-test-") && email.contains("@inbox.testmail.app")
}

func isJaredTestAddress(_ email: String) -> Bool {
  email.starts(with: "jared+") && email.hasSuffix("@netrivet.com")
}

func isTestAddress(_ email: String) -> Bool {
  isCypressTestAddress(email) || isProdSmokeTestAddress(email)
}

private extension Array {
  func chunked(into size: Int) -> [[Element]] {
    stride(from: 0, to: count, by: size).map {
      Array(self[$0 ..< Swift.min($0 + size, count)])
    }
  }
}
