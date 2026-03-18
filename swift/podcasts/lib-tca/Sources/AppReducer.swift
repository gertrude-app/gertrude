import ComposableArchitecture
import Foundation
import LibCore
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
    case processStoreKitTransaction(TransactionData, update: Bool)
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
  @Dependency(\.storekit) var storekit
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
          .run { [subscription = state.subscription] _ in
            await self.ensureDeviceId()
            if isFirstLaunch {
              self.logFirstLaunch()
            } else {
              let updated = self.defeatRepeatFreeTrialAttempt(subscription)
              self.expireFreeTrial(updated ?? subscription)
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
          .run { send in
            for txn in try await self.storekit.verifiedCurrentEntitlements() {
              await send(.processStoreKitTransaction(txn, update: false))
            }
          },
          .run { send in
            for try await update in try await self.storekit.transactionUpdates() {
              await send(.processStoreKitTransaction(update, update: true))
            }
          },
          .run { _ in
            try await self.mainQueue.sleep(for: .seconds(10))
            self.cleanupTasks()
          },
        )
      case .processStoreKitTransaction(let txn, let isUpdate):
        return .run { [priorStatus = state.subscription.status] _ in
          if let revokedAt = txn.revocationDate {
            try CurrentSubscription.set(
              status: .unpaid,
              expiringAt: revokedAt < self.date.now ? revokedAt : self.date.now,
            )
            if priorStatus != .unpaid || isUpdate {
              log(.subscription("19620bda"), "subscription revoked", detail: "\(txn)")
            }
          } else if (txn.expirationDate ?? .distantFuture) < self.date.now {
            try CurrentSubscription.set(
              status: .unpaid,
              expiringAt: txn.expirationDate ?? self.date.now,
            )
            if priorStatus != .unpaid || isUpdate {
              log(.subscription("5c74457c"), "subscription expired", detail: "\(txn)")
            }
          } else {
            try CurrentSubscription.set(
              status: .active,
              expiringAt: txn.expirationDate ?? self.date.now + .days(365),
            )
            if priorStatus != .active || isUpdate {
              log(.subscription("a72104d7"), "subscription activated", detail: "\(txn)")
            }
          }
          if isUpdate {
            await self.storekit.finishTransaction(txn.id)
          }
        }
      case .appInForegroundChanged(let foregrounded):
        state.$appInForeground.withLock { $0 = foregrounded }
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

  func defeatRepeatFreeTrialAttempt(_ subscription: Subscription) -> Subscription? {
    guard subscription.status == .trialing,
          subscription.expiresAt > self.date.now + .days(29) else {
      return nil
    }
    guard let installDate = self.keychain.loadInstallDate(),
          installDate < self.date.now - .days(3) else {
      return nil
    }

    log(.subscription("1ace9aa6"), "defeated repeat free trial attempt")
    let deviceId = self.keychain.loadDeviceId() ?? UUID()
    try? self.database.write { db in
      let records = [
        Record(id: .installDate, createdAt: installDate),
        Record(id: .onboardingFinished, createdAt: installDate),
        Record(id: .deviceId, value: "\(deviceId)", createdAt: installDate),
      ]
      try Record.insert { records }.execute(db)
    }
    return try? CurrentSubscription.set(
      status: .trialing,
      expiringAt: installDate + .days(30),
    )
  }

  func expireFreeTrial(_ subscription: Subscription) {
    guard subscription.status == .trialing,
          subscription.expiresAt <= self.date.now else {
      return
    }
    log(.subscription("456c9362"), "free trial expired")
    _ = try? CurrentSubscription.set(
      status: .unpaid,
      expiringAt: subscription.expiresAt,
    )
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
