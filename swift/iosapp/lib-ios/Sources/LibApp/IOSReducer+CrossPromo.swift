import BlockerRoute
import ComposableArchitecture
import Foundation
import GertieApp
import GertieTcaFeatures
import LibClients

extension IOSReducer {
  enum CrossPromoEvent: String {
    case impression
    case cta
    case dismiss

    var id: String {
      switch self {
      case .impression: "3d8f1b6a"
      case .cta: "7e2c9f04"
      case .dismiss: "a5b1d8e3"
      }
    }
  }

  static let onboardingCrossPromoPlacement = "iosBlockerOnboarding"
  static let homeCrossPromoPlacement = "iosBlockerHome"
  static let crossPromoThrottle: TimeInterval = 60 * 60 * 72

  func presentOnboardingCrossPromo(_ state: inout State) -> EffectOf<IOSReducer> {
    let placement = Self.onboardingCrossPromoPlacement
    guard state.crossPromos.promos
      .contains(where: { $0.placement == placement && $0.hasDismissCta })
    else {
      state.screen = .onboarding(.happyPath(.doneQuit))
      return .none
    }
    let dismissed = Set(self.deps.sharedStorage.loadDismissedCrossPromoIds() ?? [])
    guard let campaign = state.crossPromos.promos
      .filter(\.hasDismissCta)
      .firstEligible(at: placement, excluding: dismissed)
    else {
      state.screen = .onboarding(.happyPath(.doneQuit))
      return .none
    }
    let now = self.deps.now
    state.onboarding.crossPromo = .init(campaign: campaign)
    return .merge(
      .run { [deps = self.deps] _ in deps.sharedStorage.saveCrossPromoLastShownAt(now) },
      self.logCrossPromoEvent(.impression, campaign),
    )
  }

  func closeOnboardingCrossPromo(
    _ state: inout State,
    event: CrossPromoEvent,
    ctaSlot: CrossPromoFeature.CtaSlot?,
  ) -> EffectOf<IOSReducer> {
    let campaign = state.onboarding.crossPromo?.campaign
    state.onboarding.crossPromo = nil
    state.screen = .onboarding(.happyPath(.doneQuit))
    guard let campaign else { return .none }
    return .merge(
      self.logCrossPromoEvent(event, campaign, extra: self.eventExtra(campaign, ctaSlot)),
      self.burnCrossPromo(campaign),
    )
  }

  func presentHomeCrossPromo(_ state: inout State) -> EffectOf<IOSReducer> {
    guard state.screen.isRunning, state.destination == nil else { return .none }
    let placement = Self.homeCrossPromoPlacement
    guard state.crossPromos.promos.contains(where: { $0.placement == placement })
    else { return .none }
    let dismissed = Set(self.deps.sharedStorage.loadDismissedCrossPromoIds() ?? [])
    guard let campaign = state.crossPromos.promos.firstEligible(at: placement, excluding: dismissed)
    else { return .none }
    if let last = self.deps.sharedStorage.loadCrossPromoLastShownAt(),
       self.deps.now.timeIntervalSince(last) < Self.crossPromoThrottle {
      return .none
    }
    let now = self.deps.now
    state.destination = .crossPromo(.init(campaign: campaign))
    return .merge(
      .run { [deps = self.deps] _ in deps.sharedStorage.saveCrossPromoLastShownAt(now) },
      self.logCrossPromoEvent(.impression, campaign),
    )
  }

  func closeCrossPromo(
    _ state: inout State,
    event: CrossPromoEvent,
    ctaSlot: CrossPromoFeature.CtaSlot?,
  ) -> EffectOf<IOSReducer> {
    guard let promo = state.destination?.crossPromo else { return .none }
    let campaign = promo.campaign
    state.destination = nil
    return .merge(
      self.logCrossPromoEvent(event, campaign, extra: self.eventExtra(campaign, ctaSlot)),
      self.burnCrossPromo(campaign),
    )
  }

  func burnCrossPromo(_ campaign: CrossPromoCampaign) -> EffectOf<IOSReducer> {
    .run { [deps = self.deps] _ in
      var dismissed = deps.sharedStorage.loadDismissedCrossPromoIds() ?? []
      if !dismissed.contains(campaign.campaignId) {
        dismissed.append(campaign.campaignId)
      }
      deps.sharedStorage.saveDismissedCrossPromoIds(dismissed)
    }
  }

  func eventExtra(
    _ campaign: CrossPromoCampaign,
    _ ctaSlot: CrossPromoFeature.CtaSlot?,
  ) -> String? {
    ctaSlot.map { slot in
      "slot=\(slot.rawValue) action=\(campaign.action(for: slot)?.analyticsLabel ?? "-")"
    }
  }

  func logUnpresentableCrossPromos(_ campaigns: [CrossPromoCampaign]) -> EffectOf<IOSReducer> {
    .merge(campaigns.map { campaign in
      .run { _ in
        log(
          .warn,
          "c4f06a92",
          detail: "cross promo dropped: no guaranteed exit"
            + " campaign=\(campaign.campaignId) placement=\(campaign.placement)",
        )
      }
    })
  }

  func logCrossPromoEvent(
    _ event: CrossPromoEvent,
    _ campaign: CrossPromoCampaign,
    extra: String? = nil,
  ) -> EffectOf<IOSReducer> {
    let base = "cross promo \(event.rawValue)"
      + " campaign=\(campaign.campaignId)"
      + " variant=\(campaign.variant ?? "-")"
      + " placement=\(campaign.placement)"
    let detail = extra.map { "\(base) \($0)" } ?? base
    return .run { _ in
      log(.info, event.id, detail: detail)
    }
  }
}
