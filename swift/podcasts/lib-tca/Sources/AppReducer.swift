import ComposableArchitecture
import Foundation
import GertieApp
import GertieTcaFeatures
import LibCore
import PairQL
import PodcastRoute
import SQLiteData

@Reducer
struct AppReducer: Sendable {
  @ObservableState
  struct State: Equatable {
    @Presents var mode: Mode.State?
    var identity = PodcastIdentityClient.Resolution(available: false)
    @Shared(.podcastIdentityGeneration) var identityGeneration
    var nowPlaying = NowPlayingFeature.State()
    @Shared(.appInForeground) var appInForeground
    @Presents var alert: AlertState<AlertAction>?
    var killSwitch = KillSwitchFeature.State()
    @Presents var crossPromo: CrossPromoFeature.State?
    var crossPromos = CrossPromos.Output(promos: [])
    @Shared(.appConfig) var appConfig
    @Fetch(CurrentSubscription()) var subscription: Subscription = .fallback

    var canPresentSuggestedKillSwitch: Bool {
      if case .some(.podcasts) = self.mode { true } else { false }
    }
  }

  @Reducer
  enum Mode {
    case podcasts(PodcastsFeature)
    case onboarding(OnboardingFeature)
  }

  enum Action: Equatable {
    case identityResolved(PodcastIdentityClient.Resolution)
    case identityRetryTapped
    case appDidLaunch
    case appInForegroundChanged(Bool)
    case killSwitch(KillSwitchFeature.Action)
    case crossPromo(PresentationAction<CrossPromoFeature.Action>)
    case receivedCrossPromos(CrossPromos.Output)
    case receivedAppConfig(GetPodcastAppConfig.Output)
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

    var placement: String {
      switch self {
      case .postOnboarding:
        "amOnboardingParent"
      case .childHome:
        "amChildHome"
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

  @Dependency(\.podcastIdentity) var identity
  @Dependency(\.api) var api
  @Dependency(\.db) var database
  @Dependency(\.keychain) var keychain
  @Dependency(\.audio) var audio
  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.date) var date
  @Dependency(\.notificationCenter) var notificationCenter
  @Dependency(\.locale) var locale

  var body: some Reducer<State, Action> {
    Scope(\.killSwitch, action: \.killSwitch) {
      KillSwitchFeature(app: .podcasts) {
        guard let deviceId = await self.identity.current().deviceId else {
          throw KillSwitchDeviceIdError.missingDeviceId
        }
        return deviceId
      }
    }
    Scope(\.nowPlaying, action: \.nowPlaying) {
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

        return .merge(
          self.resolveIdentity(firstLaunch: isFirstLaunch),
          .run { send in
            if let appConfig = try? await self.api.appConfig(), !appConfig.isEmpty {
              await send(.receivedAppConfig(appConfig))
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
      case .identityRetryTapped:
        return self.resolveIdentity()
      case .identityResolved(let resolution):
        let previous = state.identity
        state.identity = resolution
        let changed = previous.deviceId != resolution.deviceId
          || previous.connection != resolution.connection
          || previous.migrationPending != resolution.migrationPending
          || previous.available != resolution.available
        if changed {
          state.$identityGeneration.withLock { $0 += 1 }
          state.crossPromo = nil
          if resolution.available,
             previous.deviceId != resolution.deviceId || previous.connection != resolution
             .connection {
            state.mode = nil
          }
        }
        let cancel: EffectOf<Self> = changed ? .merge(
          .cancel(id: ClaimFlow.CancelID.poll),
          .cancel(id: ClaimFlow.CancelID.identityWork),
          .cancel(id: OnboardingFeature.CancelID.connecting),
          .cancel(id: OnboardingFeature.CancelID.identityWork),
        ) : .none
        if resolution.migrationPending {
          state.mode = nil
          return cancel
        }
        guard resolution.available else { return cancel }
        if state.mode == nil || previous.migrationPending {
          if self.keychain.hasPincode() {
            state.mode = .podcasts(.init())
          } else if self.keychain.isClaimed() {
            state.mode = .onboarding(.init(screen: .explainSetPasscode, resumedAfterClaim: true))
          } else {
            state.mode = .onboarding(.init())
          }
        } else if changed, case .podcasts = state.mode {
          state.mode = .podcasts(.init())
        }
        return cancel
      case .killSwitch:
        return .none
      case .receivedCrossPromos(let crossPromos):
        let dropped = crossPromos.promos.filter { !$0.hasGuaranteedExit }
        state.crossPromos = .init(promos: crossPromos.promos.filter(\.hasGuaranteedExit))
        return .merge(
          self.logUnpresentable(dropped),
          self.presentCrossPromo(&state, for: .childHome),
        )
      case .receivedAppConfig(let appConfig):
        state.$appConfig.withLock { $0 = appConfig }
        return .none
      case .appInForegroundChanged(let foregrounded):
        let wasInForeground = state.appInForeground
        state.$appInForeground.withLock { $0 = foregrounded }
        if !foregrounded {
          return .send(.nowPlaying(.appBackgrounded))
        }
        var effects: [EffectOf<Self>] = [self.resolveIdentity()]
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
            log(.info, .setup, "ba182b20", detail: "\(pincode.redacted)")
            if resumedAfterClaim {
              log(.info, .setup, "c3e9a1f4")
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
          log(.warn, .setup, "73430b7b")
        } else {
          log(.warn, .setup, "9f4d7c2d")
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
    let dismissed = self.database.dismissedCrossPromoIds()
    guard let campaign = state.crossPromos.promos.firstEligible(
      at: trigger.placement,
      excluding: dismissed,
    ) else { return .none }
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

  func logUnpresentable(_ campaigns: [CrossPromoCampaign]) -> EffectOf<Self> {
    .merge(campaigns.map { campaign in
      .run { _ in
        await log(
          .warn,
          .setup,
          "b9e1a7c4",
          detail: "campaign=\(campaign.campaignId) placement=\(campaign.placement)",
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
      "slot=\(slot.rawValue) action=\(campaign.action(for: slot)?.analyticsLabel ?? "-")"
    }
    return .merge(
      self.logCrossPromoEvent(event, campaign, extra: extra),
      .run { _ in
        self.database.insertCrossPromoDismissal(campaignId: campaign.campaignId, at: now)
      },
    )
  }

  func logCrossPromoEvent(
    _ event: CrossPromoEvent,
    _ campaign: CrossPromoCampaign,
    extra: String? = nil,
  ) -> EffectOf<Self> {
    .run { _ in
      await log(.info, .setup, event.id, detail: campaign.eventLogDetail(extra: extra)).value
    }
  }

  private func resolveIdentity(firstLaunch: Bool = false) -> EffectOf<Self> {
    .run { send in
      let resolution = await self.resolveAndPublish(send)
      if firstLaunch { self.logFirstLaunch() }
      await withTaskGroup(of: Void.self) { group in
        group.addTask {
          await self.refreshAndPublish(send)
          await self.fetchCrossPromos(send)
        }
        if resolution.needsReport {
          group.addTask {
            await self.reportAndPublish(send)
          }
        }
      }
    }
    .cancellable(id: CancelID.identity, cancelInFlight: true)
  }

  @MainActor
  private func resolveAndPublish(_ send: Send<Action>) -> PodcastIdentityClient.Resolution {
    let resolution = self.identity.resolve()
    send(.identityResolved(resolution))
    return resolution
  }

  @MainActor
  private func refreshAndPublish(_ send: Send<Action>) async {
    await self.refreshEntitlement()
    send(.identityResolved(self.identity.current()))
  }

  @MainActor
  private func reportAndPublish(_ send: Send<Action>) async {
    _ = await self.identity.report()
    send(.identityResolved(self.identity.current()))
    await self.refreshAndPublish(send)
  }

  @MainActor
  private func fetchCrossPromos(_ send: Send<Action>) async {
    let session = self.identity.current()
    if let promos = try? await self.api.crossPromos(), !promos.promos.isEmpty,
       (try? self.identity.validate(session)) != nil {
      send(.receivedCrossPromos(promos))
    }
  }

  enum CancelID { case identity }

  @MainActor
  func refreshEntitlement() async {
    let session = self.identity.current()
    guard session.available else { return }
    if self.keychain.isClaimed() {
      do {
        let output = try await self.api.getAccountStatus()
        try self.identity.validate(session)
        output.subscription.writeLocal(now: self.date.now)
        try self.identity.completeMigration()
      } catch let error as PqlError where error.statusCode == 401 {
        guard (try? self.identity.validate(session)) != nil else { return }
        guard (try? self.identity.removeToken()) != nil else { return }
        await self.refreshTrialStatus()
      } catch is CancellationError {
      } catch is URLError {
      } catch {
        log(.err, .setup, "a1f4c2d9", detail: "\(error)")
      }
    } else {
      await self.refreshTrialStatus()
    }
  }

  @MainActor
  func refreshTrialStatus() async {
    let session = self.identity.current()
    do {
      let output = try await self.api.getTrialStatus()
      try self.identity.acceptTrialStatus(output, for: session)
      try self.identity.completeMigration()
    } catch {}
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
    log(
      .info,
      .setup,
      "27c4f26a",
      detail: "region: `\(region)`, language: `\(lang)`",
    )
  }
}

extension AppReducer.State {
  var hideNowPlaying: Bool {
    if !self.identity.available || self.identity.migrationPending { return true }
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
  dep(\.db).insertEvent(kind: .error, detail: detail, apiId: id)
  #if !DEBUG
    Task { await sendAppEvent(.warn, nil, id, "\(file):\(line)" + (detail.map { " \($0)" } ?? "")) }
  #endif
}

extension SharedKey where Self == InMemoryKey<Bool>.Default {
  static var appInForeground: Self {
    Self[.inMemory("appInForeground"), default: true]
  }
}

extension SharedKey where Self == InMemoryKey<GetPodcastAppConfig.Output>.Default {
  static var appConfig: Self {
    Self[.inMemory("appConfig"), default: .init()]
  }
}

extension AppReducer.Mode.State: Equatable {}
extension AppReducer.Mode.Action: Equatable {}

extension SharedKey where Self == InMemoryKey<Int>.Default {
  static var podcastIdentityGeneration: Self {
    Self[.inMemory("podcastIdentityGeneration"), default: 0]
  }
}
