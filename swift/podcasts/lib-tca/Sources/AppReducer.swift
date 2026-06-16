import ComposableArchitecture
import Foundation
import LibCore
import PairQL
import PodcastRoute
import SQLiteData

@Reducer
struct AppReducer: Sendable {
  @ObservableState
  struct State: Equatable {
    @Presents var mode: Mode.State?
    var nowPlaying = NowPlayingFeature.State()
    @Shared(.appInForeground) var appInForeground
    @Presents var alert: AlertState<AlertAction>?
    @Presents var crossPromo: CrossPromoFeature.State?
    var crossPromos = CrossPromos.Output(promos: [])
    @Fetch(CurrentSubscription()) var subscription: Subscription = .fallback
  }

  @Reducer
  enum Mode {
    case podcasts(PodcastsFeature)
    case onboarding(OnboardingFeature)
  }

  enum Action: Equatable {
    case appDidLaunch
    case appInForegroundChanged(Bool)
    case crossPromo(PresentationAction<CrossPromoFeature.Action>)
    case receivedCrossPromos(CrossPromos.Output)
    case nowPlaying(NowPlayingFeature.Action)
    case mode(PresentationAction<Mode.Action>)
    case alert(PresentationAction<AlertAction>)
  }

  enum AlertAction: Equatable {
    case dismiss
  }

  enum CrossPromoTrigger: Equatable {
    case postOnboarding
    case childHome

    var placement: CrossPromoPlacement {
      switch self {
      case .postOnboarding:
        .amOnboardingParent
      case .childHome:
        .amChildHome
      }
    }
  }

  enum CrossPromoEvent: String {
    case impression
    case cta
    case dismiss

    var id: String {
      switch self {
      case .impression: "fa1c7e93"
      case .cta: "b62d4a8f"
      case .dismiss: "c9e35b21"
      }
    }
  }

  static let amCrossPromoThrottle: TimeInterval = 60 * 60 * 72

  @Dependency(\.api) var api
  @Dependency(\.db) var database
  @Dependency(\.device) var device
  @Dependency(\.keychain) var keychain
  @Dependency(\.audio) var audio
  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.date) var date
  @Dependency(\.notificationCenter) var notificationCenter
  @Dependency(\.locale) var locale

  var body: some Reducer<State, Action> {
    Scope(state: \.nowPlaying, action: \.nowPlaying) {
      NowPlayingFeature()
    }
    Reduce { state, action in
      switch action {
      case .appDidLaunch:
        let isFirstLaunch = self.keychain.isFirstLaunch()
        if isFirstLaunch {
          let installDate = self.date.now
          self.keychain.save(installDate: installDate)
          self.database.insertRecord(id: .installDate)
        }

        if self.keychain.hasPincode() {
          state.mode = .podcasts(.init())
        } else if self.keychain.isClaimed() {
          state.mode = .onboarding(.init(screen: .explainSetPasscode, resumedAfterClaim: true))
        } else {
          state.mode = .onboarding(.init())
        }
        return .merge(
          .run { send in
            await self.ensureDeviceId()
            if isFirstLaunch {
              self.logFirstLaunch()
            }
            await self.refreshEntitlement()
            if let crossPromos = try? await self.api.crossPromos(), !crossPromos.promos.isEmpty {
              await send(.receivedCrossPromos(crossPromos))
            }
          },
          .publisher {
            self.audio.systemEvents()
              .map { .nowPlaying(.system($0)) }
              .receive(on: self.mainQueue)
          },
          .publisher {
            self.notificationCenter.appForegroundingEvents()
              .map { .appInForegroundChanged($0) }
              .receive(on: self.mainQueue)
          },
          .run { _ in
            try await self.mainQueue.sleep(for: .seconds(10))
            self.cleanupTasks()
          },
        )
      case .receivedCrossPromos(let crossPromos):
        let dropped = crossPromos.promos.filter { !self.hasGuaranteedExit($0) }
        state.crossPromos = .init(promos: crossPromos.promos.filter(self.hasGuaranteedExit))
        return .merge(
          self.logUnpresentable(dropped),
          self.presentCrossPromo(&state, for: .childHome),
        )
      case .appInForegroundChanged(let foregrounded):
        let wasInForeground = state.appInForeground
        state.$appInForeground.withLock { $0 = foregrounded }
        if !foregrounded {
          return .send(.nowPlaying(.appBackgrounded))
        }
        var effects: [EffectOf<Self>] = [.run { _ in await self.refreshEntitlement() }]
        if !wasInForeground {
          effects.append(self.presentCrossPromo(&state, for: .childHome))
        }
        return .merge(effects)
      case .mode(.presented(.onboarding(.finished(let pincode)))):
        let resumedAfterClaim: Bool = if case .onboarding(let onboarding) = state.mode {
          onboarding.resumedAfterClaim
        } else {
          false
        }
        state.mode = .podcasts(.init())
        return .merge(
          self.presentCrossPromo(&state, for: .postOnboarding),
          .run { _ in
            self.keychain.save(pincode: pincode)
            self.database.insertRecord(id: .onboardingFinished)
            log(.info("ba182b20"), "set pincode", detail: "\(pincode.redacted)")
            if resumedAfterClaim {
              log(.info("c3e9a1f4"), "pin set after mid-claim relaunch")
            }
          },
        )
      case .crossPromo(.presented(.delegate(.ctaTapped(let slot)))):
        return self.closeCrossPromo(&state, event: .cta, ctaSlot: slot)
      case .crossPromo(.dismiss), .crossPromo(.presented(.delegate(.dismissed))):
        return self.closeCrossPromo(&state, event: .dismiss, ctaSlot: nil)
      case .mode(.presented(.podcasts(.destination(.presented(.show(let showAction)))))):
        switch showAction {
        case .delegate(.episodePlayPauseTapped(let episode, let show)),
             .destination(.presented(.episode(.delegate(.episodePlayPauseTapped(
               let episode,
               let show,
             ))))):
          return .send(.nowPlaying(.episodePlayPauseTapped(episode, show)))
        case .delegate(.alert(let message)):
          state.alert = .init { TextState(message) }
          return .none
        default:
          return .none
        }
      case .alert(.presented(.dismiss)):
        state.alert = nil
        return .none
      case .nowPlaying(.delegate(.alert(let message))):
        state.alert = .init { TextState(message) }
        return .none
      case .mode(
        .presented(.podcasts(.destination(.presented(.addShow(.delegate(.alert(let message))))))),
      ):
        state.alert = .init { TextState(message) }
        return .none
      case .mode(.presented(.onboarding(.delegate(.shouldNotBeOnboarding)))):
        if self.keychain.hasPincode() {
          state.mode = .podcasts(.init())
          log(.unexpected("73430b7b"), "false onboarding")
        } else {
          log(.unexpected("9f4d7c2d"), "false onboarding")
        }
        return .none
      case .alert:
        return .none
      case .crossPromo:
        return .none
      case .nowPlaying:
        return .none
      case .mode:
        return .none
      }
    }
    .ifLet(\.$mode, action: \.mode)
    .ifLet(\.$alert, action: \.alert)
    .ifLet(\.$crossPromo, action: \.crossPromo) {
      CrossPromoFeature()
    }
  }

  func presentCrossPromo(
    _ state: inout State,
    for trigger: CrossPromoTrigger,
  ) -> EffectOf<Self> {
    guard state.crossPromo == nil,
          state.alert == nil,
          case .some(.podcasts(let podcasts)) = state.mode,
          podcasts.destination == nil
    else { return .none }
    let candidates = state.crossPromos.promos.filter { $0.placement == trigger.placement }
    let dismissed = self.database.dismissedCrossPromoIds()
    guard let campaign = candidates.first(where: { !dismissed.contains($0.campaignId) })
    else { return .none }
    let now = self.date.now
    switch trigger {
    case .postOnboarding:
      state.crossPromo = .init(campaign: campaign)
      return .merge(
        .run { _ in self.database.upsertRecord(id: .amCrossPromoLastShownAt, at: now) },
        self.logCrossPromoEvent(.impression, campaign),
      )
    case .childHome:
      if let last = self.database.record(id: .amCrossPromoLastShownAt)?.updatedAt,
         now.timeIntervalSince(last) < Self.amCrossPromoThrottle {
        return .none
      }
      state.crossPromo = .init(campaign: campaign)
      return .merge(
        .run { _ in self.database.upsertRecord(id: .amCrossPromoLastShownAt, at: now) },
        self.logCrossPromoEvent(.impression, campaign),
      )
    }
  }

  func hasGuaranteedExit(_ campaign: CrossPromoCampaign) -> Bool {
    if campaign.style == .sheet, campaign.dismissable { return true }
    let ctas = [campaign.primaryCta] + [campaign.secondaryCta, campaign.tertiaryCta]
      .compactMap(\.self)
    return ctas.contains { if case .dismiss = $0.action { true } else { false } }
  }

  func logUnpresentable(_ campaigns: [CrossPromoCampaign]) -> EffectOf<Self> {
    .merge(campaigns.map { campaign in
      .run { _ in
        await log(
          .unexpected("b9e1a7c4"),
          "cross promo dropped: no guaranteed exit",
          detail: "campaign=\(campaign.campaignId) placement=\(campaign.placement.rawValue)",
        ).value
      }
    })
  }

  func closeCrossPromo(
    _ state: inout State,
    event: CrossPromoEvent,
    ctaSlot: CrossPromoFeature.CtaSlot?,
  ) -> EffectOf<Self> {
    guard let campaign = state.crossPromo?.campaign else {
      state.crossPromo = nil
      return .none
    }
    state.crossPromo = nil
    let now = self.date.now
    let extra = ctaSlot.map { slot in
      "slot=\(slot.rawValue) action=\(self.ctaAction(slot, in: campaign)?.analyticsLabel ?? "-")"
    }
    return .merge(
      self.logCrossPromoEvent(event, campaign, extra: extra),
      .run { _ in
        self.database.insertCrossPromoDismissal(campaignId: campaign.campaignId, at: now)
      },
    )
  }

  func ctaAction(
    _ slot: CrossPromoFeature.CtaSlot,
    in campaign: CrossPromoCampaign,
  ) -> CrossPromoAction? {
    switch slot {
    case .primary: campaign.primaryCta.action
    case .secondary: campaign.secondaryCta?.action
    case .tertiary: campaign.tertiaryCta?.action
    }
  }

  func logCrossPromoEvent(
    _ event: CrossPromoEvent,
    _ campaign: CrossPromoCampaign,
    extra: String? = nil,
  ) -> EffectOf<Self> {
    let base = "campaign=\(campaign.campaignId)"
      + " variant=\(campaign.variant ?? "-")"
      + " placement=\(campaign.placement.rawValue)"
    let detail = extra.map { "\(base) \($0)" } ?? base
    return .run { _ in
      await log(.info(event.id), "cross promo \(event.rawValue)", detail: detail).value
    }
  }

  func refreshEntitlement() async {
    if self.keychain.isClaimed() {
      await self.refreshAccountStatus()
    } else {
      await self.refreshTrialStatus()
    }
  }

  func refreshTrialStatus() async {
    guard let output = try? await self.api.getTrialStatus() else { return }
    switch output {
    case .trial(let expiresAt):
      _ = try? CurrentSubscription.set(status: .trialing, expiringAt: expiresAt)
    case .trialExpired(let since):
      _ = try? CurrentSubscription.set(status: .unpaid, expiringAt: since)
    case .legacyGrandfathered(let accessEndsAt, let showMigrationNag, _):
      _ = try? CurrentSubscription.set(
        status: .legacy,
        expiringAt: accessEndsAt,
        legacyMigrationNag: showMigrationNag,
      )
    case .connected(let token, _, _, let subscription):
      self.keychain.save(amToken: token)
      self.applyAccountStatus(subscription)
    }
  }

  func refreshAccountStatus() async {
    do {
      let output = try await self.api.getAccountStatus()
      self.applyAccountStatus(output.subscription)
    } catch let error as PqlError where error.statusCode == 401 {
      self.keychain.deleteAmToken()
      await self.refreshTrialStatus()
    } catch is URLError {
    } catch {
      log(.error("a1f4c2d9"), "account status refresh failed", detail: "\(error)")
    }
  }

  func applyAccountStatus(_ state: AmSubscriptionState) {
    state.writeLocal(now: self.date.now)
  }

  func cleanupTasks() {
    autoPruneDownloads()
    self.database.tryWrite { db in
      try Event
        .where { $0.createdAt.lt(self.date.now - .days(30)) }
        .where { $0.kind.in(["debug", "info", "error"]) }
        .delete()
        .execute(db)
    }
  }

  func logFirstLaunch() {
    let region = self.locale.region?.identifier ?? "(nil)"
    let lang = self.locale.language.languageCode?.identifier ?? "(nil)"
    log(.info("27c4f26a"), "firstLaunch", detail: "region: `\(region)`, language: `\(lang)`")
  }

  func ensureDeviceId() async {
    guard self.keychain.loadDeviceId() == nil else { return }
    // we record the ios vendor id as our device id, same as
    // in the ios app, to correlate installs between apps
    // prior to 1.4.0 we used a random uuid as identifier
    guard let deviceId = await self.device.vendorId() else { return }
    self.keychain.save(deviceId: deviceId)
    self.database.insertRecord(id: .deviceId, value: "\(deviceId)")
    guard let oldInstallId = self.keychain.loadDeprecatedInstallId() else { return }
    try? await self.api.migrateDeviceId(oldInstallId, deviceId)
  }
}

extension AppReducer.State {
  var hideNowPlaying: Bool {
    if case .some(.podcasts(let podcasts)) = self.mode,
       case .some(.addShow) = podcasts.destination {
      return true
    } else if case .some(.onboarding) = self.mode {
      return true
    }
    return false
  }
}

func unexpected(
  id: String,
  _ detail: String? = nil,
  assert: Bool = false,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  file: StaticString = #file,
  line: UInt = #line,
  column: UInt = #column,
) {
  let message = "Unexpected \(id)" + (detail.map { ": \($0)" } ?? "")
  #if DEBUG
    reportIssue(message, fileID: fileID, filePath: filePath, line: line, column: column)
    if assert {
      assertionFailure(message, file: file, line: line)
    }
  #endif
  dep(\.db).insertEvent(kind: .error, label: id, detail: detail)
  #if !DEBUG
    Task { try? await dep(\.api).logEvent(
      id: id,
      kind: .unexpected(nil),
      label: "\(file):\(line)",
      detail: detail,
    ) }
  #endif
}

extension SharedKey where Self == InMemoryKey<Bool>.Default {
  static var appInForeground: Self {
    Self[.inMemory("appInForeground"), default: true]
  }
}

extension AppReducer.Mode.State: Equatable {}
extension AppReducer.Mode.Action: Equatable {}
