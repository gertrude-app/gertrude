import ComposableArchitecture
import Foundation
import GertieApp

@Reducer
public struct CrossPromoFeature: Sendable {
  @ObservableState
  public struct State: Equatable, Identifiable {
    public var campaign: CrossPromoCampaign
    public var share: Share?
    public var id: String { self.campaign.campaignId }

    public init(campaign: CrossPromoCampaign, share: Share? = nil) {
      self.campaign = campaign
      self.share = share
    }
  }

  public struct Share: Equatable, Identifiable, Sendable {
    public var text: String
    public var slot: CtaSlot
    public var id: String { self.text }

    public init(text: String, slot: CtaSlot) {
      self.text = text
      self.slot = slot
    }
  }

  public enum CtaSlot: String, Equatable, Sendable {
    case primary
    case secondary
    case tertiary
  }

  public enum Action: Equatable {
    public enum DelegateAction: Equatable {
      case ctaTapped(CtaSlot)
      case dismissed
    }

    case delegate(DelegateAction)
    case primaryBtnTapped
    case secondaryBtnTapped
    case tertiaryBtnTapped
    case shareCompleted(Bool)
  }

  @Dependency(\.openURL) var openURL

  public init() {}

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .primaryBtnTapped:
        return self.perform(.primary, state.campaign.primaryCta.action, into: &state)

      case .secondaryBtnTapped:
        guard let cta = state.campaign.secondaryCta else { return .none }
        return self.perform(.secondary, cta.action, into: &state)

      case .tertiaryBtnTapped:
        guard let cta = state.campaign.tertiaryCta else { return .none }
        return self.perform(.tertiary, cta.action, into: &state)

      case .shareCompleted(let completed):
        guard let share = state.share else { return .none }
        state.share = nil
        return completed ? .send(.delegate(.ctaTapped(share.slot))) : .none

      case .delegate:
        return .none
      }
    }
  }

  func perform(
    _ slot: CtaSlot,
    _ action: CrossPromoAction,
    into state: inout State,
  ) -> EffectOf<Self> {
    switch action {
    case .dismiss:
      return .send(.delegate(.dismissed))
    case .share(let text):
      state.share = Share(text: text, slot: slot)
      return .none
    case .openUrl, .openAppStoreProduct:
      return .run { send in
        guard let url = self.ctaUrl(action), await self.openURL(url) else { return }
        await send(.delegate(.ctaTapped(slot)))
      }
    }
  }

  func ctaUrl(_ action: CrossPromoAction) -> URL? {
    switch action {
    case .openUrl(let url):
      URL(string: url)
    case .openAppStoreProduct(let appStoreId):
      URL(string: "https://apps.apple.com/app/id\(appStoreId)")
    case .share, .dismiss:
      nil
    }
  }
}

public extension CrossPromoAction {
  var analyticsLabel: String {
    switch self {
    case .openUrl: "open-url"
    case .openAppStoreProduct: "open-app-store-product"
    case .share: "share"
    case .dismiss: "dismiss"
    }
  }
}
