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

  @Reducer(state: .equatable, action: .equatable)
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

  @Dependency(\.db) var database
  @Dependency(\.keychain) var keychain
  @Dependency(\.audio) var audio
  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.date) var date
  @Dependency(\.notificationCenter) var notificationCenter
  @Dependency(\.storekit) var storekit

  var body: some Reducer<State, Action> {
    Scope(state: \.nowPlaying, action: \.nowPlaying) {
      NowPlayingFeature()
    }
    Reduce { state, action in
      switch action {
      case .appDidLaunch:
        if self.keychain.isFirstLaunch() {
          let installDate = self.date.now
          self.keychain.save(installDate: installDate)
          self.database.insertRecord(id: .installDate)

          let installId = UUID()
          self.keychain.save(installId: installId)
          self.database.insertRecord(id: .installId, value: "\(installId)")
          log(.info("27c4f26a"), "firstLaunch")
        } else {
          let updated = self.defeatRepeatFreeTrialAttempt(state.subscription)
          self.expireFreeTrial(updated ?? state.subscription)
        }

        if let passcode = self.keychain.loadPincode() {
          state.mode = .podcasts(PodcastsFeature.State(passcode: passcode))
        } else {
          state.mode = .onboarding(OnboardingFeature.State())
        }
        let nowPlayingId = state.nowPlaying.data?.episode.id
        return .merge(
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
            self.cleanupTasks(nowPlayingId)
          },
        )
      case .processStoreKitTransaction(let txn, let isUpdate):
        return .run { [priorStatus = state.subscription.status] _ in
          if let revokedAt = txn.revocationDate {
            try CurrentSubscription.set(
              status: .unpaid,
              expiringAt: revokedAt < self.date.now ? revokedAt : self.date.now
            )
            if priorStatus != .unpaid || isUpdate {
              log(.subscription("19620bda"), "subscription revoked", detail: "\(txn)")
            }
          } else if (txn.expirationDate ?? .distantFuture) < self.date.now {
            try CurrentSubscription.set(
              status: .unpaid,
              expiringAt: txn.expirationDate ?? self.date.now
            )
            if priorStatus != .unpaid || isUpdate {
              log(.subscription("5c74457c"), "subscription expired", detail: "\(txn)")
            }
          } else {
            try CurrentSubscription.set(
              status: .active,
              expiringAt: txn.expirationDate ?? self.date.now + .days(365)
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
        state.mode = .podcasts(.init(passcode: pincode))
        return .run { _ in
          self.keychain.save(pincode: pincode)
          self.database.insertRecord(id: .onboardingFinished)
          log(.info("ba182b20"), "onboarding finished, saved pincode")
        }
      case .mode(.presented(.podcasts(.destination(.presented(.show(let showAction)))))):
        switch showAction {
        case .delegate(.episodePlayPauseTapped(let episode, let show)),
             .destination(.presented(.episode(.delegate(.episodePlayPauseTapped(
               let episode,
               let show
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
        .presented(.podcasts(.destination(.presented(.addShow(.delegate(.alert(let message)))))))
      ):
        state.alert = .init { TextState(message) }
        return .none
      case .mode(.presented(.onboarding(.delegate(.shouldNotBeOnboarding)))):
        if let passcode = self.keychain.loadPincode() {
          state.mode = .podcasts(PodcastsFeature.State(passcode: passcode))
          log(.unexpected("73430b7b"), "false onboarding")
          return .none
        } else {
          return .run { _ in
            await log(.unexpected("9f4d7c2d"), "false onboarding").value
            preconditionFailure("unreachable-9f4d7c2d")
          }
        }
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
    return try? CurrentSubscription.set(
      status: .trialing,
      expiringAt: installDate + .days(30)
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
      expiringAt: subscription.expiresAt
    )
  }

  func cleanupTasks(_ nowPlaying: Episode.ID?) {
    self.autoPruneDownloads(nowPlaying)
    self.database.tryWrite { db in
      try Event
        .where { $0.createdAt.lt(self.date.now - .days(30)) }
        .where { $0.kind.in(["debug", "info", "error"]) }
        .delete()
        .execute(db)
    }
  }

  func autoPruneDownloads(_ nowPlaying: Episode.ID?) {
    let episodes = self.database.tryRead { db in
      try Episode
        .whereDownloadCanBeDeleted(nowPlaying: nowPlaying, now: self.date.now)
        .fetchAll(db)
    }
    if episodes.isEmpty { return }
    self.database.tryWrite { db in
      try Episode
        .update { $0.downloadedAt = nil }
        .where { $0.id.in(episodes.map(\.id)) }
        .execute(db)
    }
    episodes.forEach { $0.removeLocalAudioFile() }
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
  column: UInt = #column
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
      detail: detail
    ) }
  #endif
}

extension SharedKey where Self == InMemoryKey<Bool>.Default {
  static var appInForeground: Self {
    Self[.inMemory("appInForeground"), default: true]
  }
}
