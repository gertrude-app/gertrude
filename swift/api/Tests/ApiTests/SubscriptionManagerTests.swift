import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class SubscriptionManagerTests: ApiTestCase, @unchecked Sendable {

  // MARK: - delete unverified parents

  func testDeletesUnverifiedParentsOlderThanThreeDays() async throws {
    var stale = try await self.db.create(Parent.random {
      $0.emailVerifiedAt = nil
    })
    var recent = try await self.db.create(Parent.random {
      $0.emailVerifiedAt = nil
    })
    var verified = try await self.db.create(Parent.random {
      $0.emailVerifiedAt = .reference - .days(1)
    })
    try await stale.modifyCreatedAt(.exact(.reference - .days(4)))
    try await recent.modifyCreatedAt(.exact(.reference - .days(2)))
    try await verified.modifyCreatedAt(.exact(.reference - .days(10)))

    let priorDeletions = try await DeletedEntity.query().count(in: self.db)
    let logs = try await SubscriptionManager().deleteUnverifiedParents()
    expect(logs.count >= 1).toEqual(true)

    let surviving = try await Parent.query().all(in: self.db)
    let survivingIds = surviving.map(\.id)
    expect(survivingIds.contains(stale.id)).toEqual(false)
    expect(survivingIds.contains(recent.id)).toEqual(true)
    expect(survivingIds.contains(verified.id)).toEqual(true)

    let postDeletions = try await DeletedEntity.query().all(in: self.db)
    expect(postDeletions.count > priorDeletions).toEqual(true)
    expect(postDeletions.contains { $0.reason == "email never verified" }).toEqual(true)
  }

  // MARK: - trial email progression (pure decision)

  func testNoEmailBeforeT18() {
    expect(nextTrialEmailDecision(
      lifecycle: .none,
      trialStartedAt: .reference,
      hasConnectedMac: true,
      now: .reference + .days(17),
    )).toBeNil()
  }

  func testEndingSoonAtExactlyT18() {
    expect(nextTrialEmailDecision(
      lifecycle: .none,
      trialStartedAt: .reference,
      hasConnectedMac: true,
      now: .reference + .days(18),
    )).toEqual(.init(
      send: .trialEndingSoon(length: 21, remaining: 3),
      nextLifecycle: .endingSoonSent,
    ))
  }

  func testNoMacDoesNotGetEndingSoonReminder() {
    expect(nextTrialEmailDecision(
      lifecycle: .none,
      trialStartedAt: .reference,
      hasConnectedMac: false,
      now: .reference + .days(18),
    )).toBeNil()
  }

  func testLateEndingSoonReminderUsesActualRemainingDays() {
    expect(nextTrialEmailDecision(
      lifecycle: .none,
      trialStartedAt: .reference,
      hasConnectedMac: true,
      now: .reference + .days(20),
    )).toEqual(.init(
      send: .trialEndingSoon(length: 21, remaining: 1),
      nextLifecycle: .endingSoonSent,
    ))
  }

  func testTrialExpiredAtT21DoesNotSendAnOutdatedEndingSoonEmail() {
    for lifecycle in [BillingIdentity.TrialEmailLifecycle.none, .endingSoonSent] {
      expect(nextTrialEmailDecision(
        lifecycle: lifecycle,
        trialStartedAt: .reference,
        hasConnectedMac: true,
        now: .reference + .days(21),
      )).toEqual(.init(send: .trialExpired(length: 21), nextLifecycle: .expiredSent))
    }
  }

  func testNoMacGetsOneInformationalEmailAtT21() {
    for lifecycle in [BillingIdentity.TrialEmailLifecycle.none, .endingSoonSent] {
      expect(nextTrialEmailDecision(
        lifecycle: lifecycle,
        trialStartedAt: .reference,
        hasConnectedMac: false,
        now: .reference + .days(21),
      )).toEqual(.init(send: .trialExpiredNoMac, nextLifecycle: .finalSent))
    }
  }

  func testFinalSentAtT28SendsTrialGraceEndedNotNonpaymentEmail() {
    for lifecycle in [BillingIdentity.TrialEmailLifecycle.none, .endingSoonSent, .expiredSent] {
      expect(nextTrialEmailDecision(
        lifecycle: lifecycle,
        trialStartedAt: .reference,
        hasConnectedMac: true,
        now: .reference + .days(28),
      )).toEqual(.init(send: .trialGraceEnded, nextLifecycle: .finalSent))
    }
  }

  func testDisconnectedMacDoesNotGetAFollowupAfterTrialExpiredEmail() {
    expect(nextTrialEmailDecision(
      lifecycle: .expiredSent,
      trialStartedAt: .reference,
      hasConnectedMac: false,
      now: .reference + .days(28),
    )).toEqual(.init(send: nil, nextLifecycle: .finalSent))
  }

  func testFinalLifecycleNoMoreEmails() {
    expect(nextTrialEmailDecision(
      lifecycle: .finalSent,
      trialStartedAt: .reference,
      hasConnectedMac: true,
      now: .reference + .days(50),
    )).toBeNil()
  }

  func testStaleTrialShortCircuitsToFinalSentWithoutEmail() {
    for lifecycle in [BillingIdentity.TrialEmailLifecycle.none, .endingSoonSent, .expiredSent] {
      for hasMac in [false, true] {
        expect(nextTrialEmailDecision(
          lifecycle: lifecycle,
          trialStartedAt: .reference,
          hasConnectedMac: hasMac,
          now: .reference + .days(36),
        )).toEqual(.init(send: nil, nextLifecycle: .finalSent))
      }
    }
  }

  func testNotYetStaleAtFinalStillSendsTrialGraceEnded() {
    expect(nextTrialEmailDecision(
      lifecycle: .expiredSent,
      trialStartedAt: .reference,
      hasConnectedMac: true,
      now: .reference + .days(34),
    )).toEqual(.init(send: .trialGraceEnded, nextLifecycle: .finalSent))
  }

  // MARK: - trial email progression (integration)

  func testMacTrialSequenceForFreeLightAndMediumPlans() async throws {
    let tiers: [StripeSubscription.Tier?] = [nil, .light, .medium]
    let stages: [(Int, String, BillingIdentity.TrialEmailLifecycle)] = [
      (18, "trial-ending-soon-v2", .endingSoonSent),
      (21, "trial-expired-v2", .expiredSent),
      (28, "trial-grace-ended", .finalSent),
    ]
    for tier in tiers {
      let parent = try await self.parent()
      _ = try await parent.withOnboardedChild()
      _ = try await self.db.create(BillingIdentity(
        parentId: parent.id,
        fullTrialStartedAt: .reference,
      ))
      if let tier {
        _ = try await self.db.create(StripeSubscription(
          parentId: parent.id,
          tier: tier,
          stripeId: .init("sub_\(parent.id)"),
          stripeStatus: .active,
          currentPeriodEnd: .reference + .days(180),
        ))
      }
      for (index, stage) in stages.enumerated() {
        let (day, alias, lifecycle) = stage
        _ = try await withDependencies {
          $0.date.now = .reference + .days(day)
        } operation: {
          try await SubscriptionManager().advanceTrialEmails()
        }
        let emails = self.sent.emails.filter { $0.to == parent.email.rawValue }
        expect(emails.count).toEqual(index + 1)
        let email = try XCTUnwrap(emails.last)
        expect(email.template).toEqual(alias)
        expect(email.templateModel["currentPlan"]).toEqual(tier?.rawValue.capitalized ?? "")
        expect(email.templateModel["pastDuePlan"]).toEqual("")
        expect(email.templateModel["billingUrl"]).toEqual(
          get(dependency: \.env.dashboardUrl).withoutTrailingSlashes + "/settings",
        )
        let notice = email.templateModel["planNotice"] ?? ""
        expect(notice.contains("plan isn’t changing")).toEqual(tier != nil)
        expect(notice.contains("Gertrude Music")).toEqual(tier == .medium)
        let identity = try await parent.model.billingIdentity(in: self.db)!
        expect(identity.trialEmailLifecycle).toEqual(lifecycle)
      }
    }
  }

  func testTrialEmailBillingLinksRespectAccountSiteBeta() async throws {
    let stages = [
      (18, true, "trial-ending-soon-v2"),
      (21, true, "trial-expired-v2"),
      (21, false, "trial-expired-no-mac"),
      (28, true, "trial-grace-ended"),
    ]
    for betaEnabled in [false, true] {
      for (day, hasMac, alias) in stages {
        let parent = try await self.parent(with: \.accountSiteBetaEnabled, of: betaEnabled)
        if hasMac { _ = try await parent.withOnboardedChild() }
        _ = try await self.db.create(BillingIdentity(
          parentId: parent.id,
          fullTrialStartedAt: .reference,
        ))

        _ = try await withDependencies {
          $0.date.now = .reference + .days(day)
          $0.env.dashboardUrl = "https://dashboard.example/"
          $0.env.accountDashboardUrl = "https://account.example/"
        } operation: {
          try await SubscriptionManager().advanceTrialEmails()
        }

        let emails = self.sent.emails.filter { $0.to == parent.email.rawValue }
        expect(emails.count).toEqual(1)
        let email = try XCTUnwrap(emails.first)
        expect(email.template).toEqual(alias)
        expect(email.templateModel["billingUrl"]).toEqual(betaEnabled
          ? "https://account.example/settings/billing"
          : "https://dashboard.example/settings")
      }
    }
  }

  func testUpdatedTrialTemplatesSyncToVersionedAliases() {
    expect(AccountLifecycle.TrialEndingSoon.pmTemplateInput().Alias)
      .toEqual("trial-ending-soon-v2")
    expect(AccountLifecycle.TrialExpired.pmTemplateInput().Alias)
      .toEqual("trial-expired-v2")
  }

  func testTrialEmailBillingUrlsPreserveLeadingSlashesAndRemoveTrailingSlashes() async throws {
    let cases = [
      ("https://account.example", "https://account.example"),
      ("https://account.example/", "https://account.example"),
      ("https://account.example///", "https://account.example"),
      ("/account", "/account"),
      ("/account/", "/account"),
      ("/account///", "/account"),
      ("/", ""),
    ]
    for betaEnabled in [false, true] {
      for (baseUrl, expectedBaseUrl) in cases {
        let parent = try await self.parent(with: \.accountSiteBetaEnabled, of: betaEnabled)
        _ = try await self.db.create(BillingIdentity(
          parentId: parent.id,
          fullTrialStartedAt: .reference - .days(21),
        ))
        _ = try await withDependencies {
          $0.env.dashboardUrl = baseUrl
          $0.env.accountDashboardUrl = baseUrl
        } operation: {
          try await SubscriptionManager().advanceTrialEmails()
        }
        let email = try XCTUnwrap(self.sent.emails.first { $0.to == parent.email.rawValue })
        let path = betaEnabled ? "/settings/billing" : "/settings"
        expect(email.templateModel["billingUrl"]).toEqual(expectedBaseUrl + path)
      }
    }
  }

  func testIosOnlyFreeLightAndMediumPlansGetOnlyOneInformationalEmail() async throws {
    let tiers: [StripeSubscription.Tier?] = [nil, .light, .medium]
    for tier in tiers {
      let child = try await self.childWithIOSDevice()
      let parent = child.parent
      _ = try await self.db.create(BillingIdentity(
        parentId: parent.id,
        fullTrialStartedAt: .reference,
      ))
      if let tier {
        _ = try await self.db.create(StripeSubscription(
          parentId: parent.id,
          tier: tier,
          stripeId: .init("sub_\(parent.id)"),
          stripeStatus: .active,
          currentPeriodEnd: .reference + .days(180),
        ))
      }
      for day in [18, 20] {
        _ = try await withDependencies {
          $0.date.now = .reference + .days(day)
        } operation: {
          try await SubscriptionManager().advanceTrialEmails()
        }
        expect(self.sent.emails.contains { $0.to == parent.email.rawValue }).toBeFalse()
      }
      for day in [21, 22, 28, 34] {
        _ = try await withDependencies {
          $0.date.now = .reference + .days(day)
        } operation: {
          try await SubscriptionManager().advanceTrialEmails()
        }
      }
      let emails = self.sent.emails.filter { $0.to == parent.email.rawValue }
      expect(emails.count).toEqual(1)
      let email = try XCTUnwrap(emails.first)
      expect(email.template).toEqual("trial-expired-no-mac")
      expect(email.templateModel["subjectSuffix"]).toEqual(" — no action needed")
      expect(email.templateModel["currentPlan"]).toEqual(tier?.rawValue.capitalized ?? "")
      expect((email.templateModel["planNotice"] ?? "").contains("Gertrude Music"))
        .toEqual(tier == .medium)
      let identity = try await parent.model.billingIdentity(in: self.db)!
      expect(identity.trialEmailLifecycle).toEqual(.finalSent)
    }
  }

  func testPastDueLowerPlansAreNotPromisedUninterruptedPaidFeatures() async throws {
    for tier in [StripeSubscription.Tier.light, .medium] {
      for hasMac in [false, true] {
        let child = try await self.childWithIOSDevice()
        let parent = child.parent
        if hasMac { _ = try await parent.withOnboardedChild() }
        _ = try await self.db.create(BillingIdentity(
          parentId: parent.id,
          fullTrialStartedAt: .reference - .days(21),
        ))
        _ = try await self.db.create(StripeSubscription(
          parentId: parent.id,
          tier: tier,
          stripeId: .init("sub_\(parent.id)"),
          stripeStatus: .pastDue,
          currentPeriodEnd: .reference - .days(2),
        ))
        _ = try await SubscriptionManager().advanceTrialEmails()
        let email = try XCTUnwrap(self.sent.emails.first { $0.to == parent.email.rawValue })
        expect(email.template).toEqual(hasMac ? "trial-expired-v2" : "trial-expired-no-mac")
        expect(email.templateModel["currentPlan"]).toEqual("")
        expect(email.templateModel["pastDuePlan"]).toEqual(tier.rawValue.capitalized)
        let notice = email.templateModel["planNotice"] ?? ""
        expect(notice.contains("separate payment issue")).toBeTrue()
        expect(notice.contains("plan isn’t changing")).toBeFalse()
        if !hasMac { expect(email.templateModel["subjectSuffix"]).toEqual("") }
      }
    }
  }

  func testNoMacEmailOnlyWarnsWhenConnectedPodcastsAccessEndsWithFullTrial() async throws {
    struct Scenario {
      let name: String
      var installedDaysAgo = 60
      var connected = true
      var tier: StripeSubscription.Tier?
      var legacyPaidAt: Date?
      var sendDelay = 0
      var accessEnded = false
    }
    let scenarios = [
      Scenario(name: "full trial is the only access", accessEnded: true),
      Scenario(
        name: "podcasts trial ends at the same time",
        installedDaysAgo: 30,
        accessEnded: true,
      ),
      Scenario(name: "podcasts trial continues", installedDaysAgo: 29),
      Scenario(name: "podcasts trial ended later", installedDaysAgo: 29, sendDelay: 2),
      Scenario(name: "legacy purchase continues", legacyPaidAt: .reference - .days(100)),
      Scenario(
        name: "legacy purchase expired",
        legacyPaidAt: .reference - .days(500),
        accessEnded: true,
      ),
      Scenario(name: "paid light continues", tier: .light),
      Scenario(name: "paid medium continues", tier: .medium),
      Scenario(name: "podcasts installed but not connected", connected: false),
    ]
    for scenario in scenarios {
      let child = try await self.child()
      let (_, install) = try await self.claimedPodcastInstall(
        for: child,
        installedDaysAgo: scenario.installedDaysAgo,
      )
      if scenario.connected {
        try await self.db.create(PodcastApp.Token(installId: install.id))
      }
      if let tier = scenario.tier {
        try await self.addPaidSubscription(for: child.parent.id, tier: tier)
      }
      var identity = try await child.parent.model.ensureBillingIdentity(in: self.db)
      identity.fullTrialStartedAt = .reference - .days(21)
      identity.legacyAmIapPaidAt = scenario.legacyPaidAt
      try await self.db.update(identity)

      _ = try await withDependencies {
        $0.date.now = .reference + .days(scenario.sendDelay)
      } operation: {
        try await SubscriptionManager().advanceTrialEmails()
      }

      let emails = self.sent.emails.filter { $0.to == child.parent.email.rawValue }
      XCTAssertEqual(emails.count, 1, scenario.name)
      let email = try XCTUnwrap(emails.first)
      XCTAssertEqual(email.template, "trial-expired-no-mac", scenario.name)
      XCTAssertEqual(
        email.templateModel["subjectSuffix"],
        scenario.accessEnded ? "" : " — no action needed",
        scenario.name,
      )
      XCTAssertEqual(
        email.templateModel["impactNotice"]?.contains("won’t affect"),
        !scenario.accessEnded,
        scenario.name,
      )
      XCTAssertEqual(
        email.templateModel["billingLinkText"],
        scenario.accessEnded
          ? "subscribe to Light here"
          : "review the Full plan in your billing settings",
        scenario.name,
      )
    }
  }

  func testNoMacEmailWarnsIfAnyConnectedPodcastsDeviceLosesAccess() async throws {
    let child = try await self.child()
    for daysAgo in [1, 60] {
      let (_, install) = try await self.claimedPodcastInstall(for: child, installedDaysAgo: daysAgo)
      try await self.db.create(PodcastApp.Token(installId: install.id))
    }
    try await self.db.create(BillingIdentity(
      parentId: child.parent.id,
      fullTrialStartedAt: .reference - .days(21),
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()

    let email = try XCTUnwrap(self.sent.emails.first { $0.to == child.parent.email.rawValue })
    expect(email.templateModel["subjectSuffix"]).toEqual("")
    expect(email.templateModel["impactNotice"]?.contains("You don’t need Full for Podcasts"))
      .toEqual(true)
  }

  func testPaidFullParentMarkedAsSkipped() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference - .days(18),
      trialEmailLifecycle: .none,
    ))
    _ = try await self.db.create(StripeSubscription(
      parentId: parent.id,
      tier: .full,
      stripeId: .init("sub_full"),
      stripeStatus: .active,
      currentPeriodEnd: .reference + .days(15),
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()

    let identity = try await parent.model.billingIdentity(in: self.db)!
    expect(identity.trialEmailLifecycle).toEqual(.skipped)
    expect(self.sent.emails.contains(where: { $0.to == parent.email.rawValue })).toBeFalse()
  }

  func testLapsedFullParentMarkedAsSkippedViaLastPaidTier() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      stripeCustomerId: .init("cus_lapsed_full"),
      fullTrialStartedAt: .reference - .days(50),
      lastStripeSubscriptionId: .init("sub_old_full"),
      lastPaidTier: .full,
      trialEmailLifecycle: .none,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()

    let identity = try await parent.model.billingIdentity(in: self.db)!
    expect(identity.trialEmailLifecycle).toEqual(.skipped)
    expect(self.sent.emails.contains(where: { $0.to == parent.email.rawValue })).toBeFalse()
  }

  func testLapsedLightParentDoesNotShortCircuit() async throws {
    let parent = try await self.parent()
    _ = try await parent.withOnboardedChild()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      stripeCustomerId: .init("cus_lapsed_light"),
      fullTrialStartedAt: .reference - .days(18),
      lastStripeSubscriptionId: .init("sub_old_light"),
      lastPaidTier: .light,
      trialEmailLifecycle: .none,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()

    let identity = try await parent.model.billingIdentity(in: self.db)!
    expect(identity.trialEmailLifecycle).toEqual(.endingSoonSent)
    expect(self.sent.emails.count).toEqual(1)
  }

  func testAncientLightTrialGoesTerminalWithoutEmail() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      stripeCustomerId: .init("cus_ancient_light"),
      fullTrialStartedAt: .reference - .days(90),
      lastStripeSubscriptionId: .init("sub_ancient_light"),
      lastPaidTier: .light,
      trialEmailLifecycle: .none,
    ))
    _ = try await self.db.create(StripeSubscription(
      parentId: parent.id,
      tier: .light,
      stripeId: .init("sub_ancient_light"),
      stripeStatus: .active,
      currentPeriodEnd: .reference + .days(180),
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()

    let identity = try await parent.model.billingIdentity(in: self.db)!
    expect(identity.trialEmailLifecycle).toEqual(.finalSent)
    expect(self.sent.emails.contains(where: { $0.to == parent.email.rawValue })).toBeFalse()
  }

  func testComplimentaryIdentityIgnored() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference - .days(50),
      trialEmailLifecycle: .none,
      isComplimentary: true,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()

    let identity = try await parent.model.billingIdentity(in: self.db)!
    expect(identity.trialEmailLifecycle).toEqual(.none)
    expect(self.sent.emails.contains(where: { $0.to == parent.email.rawValue })).toBeFalse()
  }

  func testIdentityWithoutTrialIgnored() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: nil,
      trialEmailLifecycle: .none,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()
    expect(self.sent.emails.contains(where: { $0.to == parent.email.rawValue })).toBeFalse()
  }

  func testFinalSentLifecycleFilteredOutByQuery() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference - .days(50),
      trialEmailLifecycle: .finalSent,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()
    expect(self.sent.emails.contains(where: { $0.to == parent.email.rawValue })).toBeFalse()
  }

  func testSkippedLifecycleFilteredOutByQuery() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference - .days(50),
      trialEmailLifecycle: .skipped,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()
    expect(self.sent.emails.contains(where: { $0.to == parent.email.rawValue })).toBeFalse()
  }

  func testTrialExpiredOnboardedSendsEmail() async throws {
    let parent = try await self.parent()
    _ = try await parent.withOnboardedChild()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference - .days(21),
      trialEmailLifecycle: .endingSoonSent,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()

    let identity = try await parent.model.billingIdentity(in: self.db)!
    expect(identity.trialEmailLifecycle).toEqual(.expiredSent)
    expect(self.sent.emails.count).toEqual(1)
    expect(self.sent.emails[0].template).toBe("trial-expired-v2")
  }

  func testTrialExpiredWithoutAnyDevicesSendsOneInformationalEmail() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference - .days(21),
      trialEmailLifecycle: .endingSoonSent,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()

    let identity = try await parent.model.billingIdentity(in: self.db)!
    expect(identity.trialEmailLifecycle).toEqual(.finalSent)
    let emails = self.sent.emails.filter { $0.to == parent.email.rawValue }
    expect(emails.count).toEqual(1)
    expect(emails.first?.template).toEqual("trial-expired-no-mac")
  }

  // MARK: - Stripe failsafe

  func testRefreshActiveSubKeepsActiveAndUpdatesPeriodEnd() async throws {
    try await self.db.delete(all: StripeSubscription.self)
    let parent = try await self.parent()
    _ = try? await self.db.create(BillingIdentity(parentId: parent.id))
    _ = try await self.db.create(StripeSubscription(
      parentId: parent.id,
      tier: .full,
      stripeId: .init("sub_x"),
      stripeStatus: .active,
      currentPeriodEnd: .reference - .days(5),
    ))

    let nextPeriodEnd = Date.reference + .days(25)

    try await withDependencies {
      $0.stripe.getSubscription = { id in
        expect(id).toEqual("sub_x")
        return .init(
          id: id,
          status: .active,
          customer: "cus_x",
          currentPeriodEnd: Int(Date.epoch.distance(to: nextPeriodEnd)),
        )
      }
    } operation: {
      _ = try await SubscriptionManager().refreshStaleSubscriptions()
    }

    let sub = try await parent.model.subscription(in: self.db)!
    expect(sub.stripeStatus).toEqual(.active)
    expect(sub.currentPeriodEnd).toEqual(nextPeriodEnd)
    expect(self.sent.emails.count).toEqual(0)
  }

  func testActiveToPastDueSendsPaidToOverdueEmail() async throws {
    try await self.db.delete(all: StripeSubscription.self)
    let parent = try await self.parent()
    _ = try await parent.withOnboardedChild()
    _ = try? await self.db.create(BillingIdentity(parentId: parent.id))
    _ = try await self.db.create(StripeSubscription(
      parentId: parent.id,
      tier: .full,
      stripeId: .init("sub_pd"),
      stripeStatus: .active,
      currentPeriodEnd: .reference - .days(5),
    ))

    try await withDependencies {
      $0.stripe.getSubscription = { _ in
        .init(id: "sub_pd", status: .pastDue, customer: "cus_x", currentPeriodEnd: 0)
      }
    } operation: {
      _ = try await SubscriptionManager().refreshStaleSubscriptions()
    }

    let sub = try await parent.model.subscription(in: self.db)!
    expect(sub.stripeStatus).toEqual(.pastDue)
    expect(self.sent.emails.count).toEqual(1)
    expect(self.sent.emails[0].template).toBe("paid-to-overdue")
  }

  func testPastDueToCanceledOnboardedSendsOverdueToUnpaidEmail() async throws {
    try await self.db.delete(all: StripeSubscription.self)
    let parent = try await self.parent()
    _ = try await parent.withOnboardedChild()
    _ = try? await self.db.create(BillingIdentity(parentId: parent.id))
    _ = try await self.db.create(StripeSubscription(
      parentId: parent.id,
      tier: .full,
      stripeId: .init("sub_cx"),
      stripeStatus: .pastDue,
      currentPeriodEnd: .reference - .days(8),
    ))

    try await withDependencies {
      $0.stripe.getSubscription = { _ in
        .init(id: "sub_cx", status: .canceled, customer: "cus_x", currentPeriodEnd: 0)
      }
    } operation: {
      _ = try await SubscriptionManager().refreshStaleSubscriptions()
    }

    let sub = try await parent.model.subscription(in: self.db)!
    expect(sub.stripeStatus).toEqual(.canceled)
    expect(self.sent.emails.count).toEqual(1)
    expect(self.sent.emails[0].template).toBe("overdue-to-unpaid")
  }

  func testTerminalSubsAreNotRefreshed() async throws {
    try await self.db.delete(all: StripeSubscription.self)
    let parent = try await self.parent()
    _ = try? await self.db.create(BillingIdentity(parentId: parent.id))
    _ = try await self.db.create(StripeSubscription(
      parentId: parent.id,
      tier: .full,
      stripeId: .init("sub_t"),
      stripeStatus: .canceled,
      currentPeriodEnd: .reference - .days(50),
    ))

    try await withDependencies {
      $0.stripe.getSubscription = { _ in
        XCTFail("Stripe should not be called for terminal subs")
        return .init(id: "sub_t", status: .canceled, customer: "x", currentPeriodEnd: 0)
      }
    } operation: {
      _ = try await SubscriptionManager().refreshStaleSubscriptions()
    }
    expect(self.sent.emails.count).toEqual(0)
  }

  func testStripeLookupErrorIsSwallowed() async throws {
    try await self.db.delete(all: StripeSubscription.self)
    let parent = try await self.parent()
    _ = try? await self.db.create(BillingIdentity(parentId: parent.id))
    _ = try await self.db.create(StripeSubscription(
      parentId: parent.id,
      tier: .full,
      stripeId: .init("sub_e"),
      stripeStatus: .active,
      currentPeriodEnd: .reference - .days(5),
    ))

    try await withDependencies {
      $0.stripe.getSubscription = { _ in
        throw NSError(domain: "Test", code: 1)
      }
    } operation: {
      _ = try await SubscriptionManager().refreshStaleSubscriptions()
    }

    let sub = try await parent.model.subscription(in: self.db)!
    expect(sub.stripeStatus).toEqual(.active)
    expect(self.sent.emails.count).toEqual(0)
  }
}

private extension ParentEntities {
  @discardableResult
  func withOnboardedChild() async throws -> ParentWithOnboardedChildEntities {
    @Dependency(\.db) var db
    let child = try await db.create(Child.random { $0.parentId = self.model.id })
    let computer = try await db.create(Computer.random { $0.parentId = self.model.id })
    let computerUser = try await db.create(ComputerUser.random {
      $0.childId = child.id
      $0.computerId = computer.id
    })
    return .init(
      model: self.model,
      token: self.token,
      child: child,
      computerUser: computerUser,
      computer: computer,
    )
  }
}
