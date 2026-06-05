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
    case nowPlaying(NowPlayingFeature.Action)
    case mode(PresentationAction<Mode.Action>)
    case alert(PresentationAction<AlertAction>)
  }

  enum AlertAction: Equatable {
    case dismiss
  }

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
        } else {
          state.mode = .onboarding(.init())
        }
        return .merge(
          .run { _ in
            await self.ensureDeviceId()
            if isFirstLaunch {
              self.logFirstLaunch()
            }
            await self.refreshEntitlement()
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
      case .appInForegroundChanged(let foregrounded):
        state.$appInForeground.withLock { $0 = foregrounded }
        if !foregrounded {
          return .send(.nowPlaying(.appBackgrounded))
        }
        return .none
      case .mode(.presented(.onboarding(.finished(let pincode)))):
        state.mode = .podcasts(.init())
        return .run { _ in
          self.keychain.save(pincode: pincode)
          self.database.insertRecord(id: .onboardingFinished)
          log(.info("ba182b20"), "set pincode", detail: "\(pincode.redacted)")
        }
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
      case .nowPlaying:
        return .none
      case .mode:
        return .none
      }
    }
    .ifLet(\.$mode, action: \.mode)
    .ifLet(\.$alert, action: \.alert)
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
    case .legacyGrandfathered:
      break
    case .claimed(let token, _, _, let subscription):
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
