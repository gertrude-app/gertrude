import ComposableArchitecture
import Foundation
import GertieApp
import GertieTcaFeatures
import IOSRoute

extension IOSReducer {
  enum CrossPromoTrigger {
    case postOnboarding
    case home

    var placement: String {
      switch self {
      case .postOnboarding: "iosBlockerPostOnboarding"
      case .home: "iosBlockerHome"
      }
    }
  }

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

  static let crossPromoThrottle: TimeInterval = 60 * 60 * 72

  func presentCrossPromos(_ state: inout State) -> EffectOf<IOSReducer> {
    guard state.screen.isRunning else { return .none }
    return .merge(
      self.presentCrossPromo(&state, for: .postOnboarding),
      self.presentCrossPromo(&state, for: .home),
    )
  }

  func presentCrossPromo(
    _ state: inout State,
    for trigger: CrossPromoTrigger,
  ) -> EffectOf<IOSReducer> {
    guard state.destination == nil else { return .none }
    let candidates = state.crossPromos.promos.filter { $0.placement == trigger.placement }
    guard !candidates.isEmpty else { return .none }
    let dismissed = Set(self.deps.sharedStorage.loadDismissedCrossPromoIds() ?? [])
    guard let campaign = candidates.first(where: { !dismissed.contains($0.campaignId) })
    else { return .none }
    if trigger == .home,
       let last = self.deps.sharedStorage.loadCrossPromoLastShownAt(),
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
    let extra = ctaSlot.map { slot in
      "slot=\(slot.rawValue) action=\(campaign.action(for: slot)?.analyticsLabel ?? "-")"
    }
    return .merge(
      self.logCrossPromoEvent(event, campaign, extra: extra),
      .run { [deps = self.deps] _ in
        var dismissed = deps.sharedStorage.loadDismissedCrossPromoIds() ?? []
        if !dismissed.contains(campaign.campaignId) {
          dismissed.append(campaign.campaignId)
        }
        deps.sharedStorage.saveDismissedCrossPromoIds(dismissed)
      },
    )
  }

  func logUnpresentableCrossPromos(_ campaigns: [CrossPromoCampaign]) -> EffectOf<IOSReducer> {
    .merge(campaigns.map { campaign in
      .run { [deps = self.deps] _ in
        await deps.api.logEvent(
          "c4f06a92",
          "cross promo dropped: no guaranteed exit"
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
    return .run { [deps = self.deps] _ in
      await deps.api.logEvent(event.id, detail)
    }
  }
}
