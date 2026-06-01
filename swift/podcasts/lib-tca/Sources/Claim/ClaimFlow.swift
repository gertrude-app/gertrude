import ComposableArchitecture
import Foundation
import PodcastRoute

@Reducer
struct ClaimFlow {
  @ObservableState
  struct State: Equatable {
    var childName: String?
    var claimCode: Int?
    var claimCodeFailed = false
    var context: Context
    var entitlement: AmSubscriptionState?
    var step: Step

    init(
      context: Context,
      initialStep: Step = .showingCode,
      entitlement: AmSubscriptionState? = nil,
    ) {
      self.context = context
      self.step = initialStep
      self.entitlement = entitlement
    }

    enum Context: Equatable {
      case modal
      case wizard
    }

    enum Step: Equatable {
      case showingCode
      case success
      case payment
    }

    var successIsTerminal: Bool {
      self.entitlement?.isEntitled ?? false
    }
  }

  enum Action: Equatable {
    case accountStatusResponse(GetAccountStatus.Output)
    case cancelTapped
    case claimCodeFailed
    case claimCodeResponse(code: Int)
    case doneTapped
    case nextTapped
    case notNowTapped
    case onAppear
    case polled(GetTrialStatus.Output)
    case retryTapped
  }

  enum CancelID {
    case poll
  }

  @Dependency(\.api) var api
  @Dependency(\.continuousClock) var clock
  @Dependency(\.date.now) var now
  @Dependency(\.dismiss) var dismiss
  @Dependency(\.keychain) var keychain

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        log(.info("6ba6a016"), "claim flow opened", detail: "\(state.context)/\(state.step)")
        switch state.step {
        case .showingCode:
          return self.startShowingCode(&state)
        case .payment:
          return self.startPayment()
        case .success:
          return .none
        }

      case .retryTapped:
        return self.startShowingCode(&state)

      case .claimCodeResponse(let code):
        log(.info("de4909f1"), "claim code shown")
        state.claimCode = code
        state.claimCodeFailed = false
        return .none

      case .claimCodeFailed:
        log(.error("b2cb8725"), "claim code create failed")
        state.claimCodeFailed = true
        return .none

      case .polled(let output):
        guard case .claimed(let token, _, let childName, let subscription) = output else {
          return .none
        }
        self.keychain.save(amToken: token)
        subscription.writeLocal(now: self.now)
        log(.subscription("9b9ea2d6"), "device claimed", detail: "\(subscription)")
        state.childName = childName
        state.entitlement = subscription
        state.step = .success
        return .cancel(id: CancelID.poll)

      case .nextTapped:
        log(.info("82b8e4c0"), "claim advanced to payment")
        state.step = .payment
        return self.startPayment()

      case .accountStatusResponse(let output):
        state.entitlement = output.subscription
        output.subscription.writeLocal(now: self.now)
        guard output.subscription.isEntitled else { return .none }
        log(
          .subscription("c6cae011"),
          "payment remediation succeeded",
          detail: "\(output.subscription)",
        )
        return self.dismissFlow()

      case .cancelTapped:
        log(.info("c4ef5b66"), "claim flow cancelled", detail: "\(state.step)")
        return self.dismissFlow()

      case .notNowTapped:
        log(.info("32bb0769"), "claim payment declined")
        return self.dismissFlow()

      case .doneTapped:
        return self.dismissFlow()
      }
    }
  }

  func dismissFlow() -> EffectOf<ClaimFlow> {
    .merge(
      .cancel(id: CancelID.poll),
      .run { _ in await self.dismiss() },
    )
  }

  func startShowingCode(_ state: inout State) -> EffectOf<ClaimFlow> {
    state.claimCode = nil
    state.claimCodeFailed = false
    return .merge(
      .run { send in
        do {
          let output = try await self.api.createClaimCode()
          await send(.claimCodeResponse(code: output.code))
        } catch {
          await send(.claimCodeFailed)
        }
      },
      .run { send in
        while !Task.isCancelled {
          try await self.clock.sleep(for: .seconds(5))
          if let output = try? await self.api.getTrialStatus() {
            await send(.polled(output))
          }
        }
      }
      .cancellable(id: CancelID.poll, cancelInFlight: true),
    )
  }

  func startPayment() -> EffectOf<ClaimFlow> {
    .run { send in
      while !Task.isCancelled {
        try await self.clock.sleep(for: .seconds(5))
        if let output = try? await self.api.getAccountStatus() {
          await send(.accountStatusResponse(output))
        }
      }
    }
    .cancellable(id: CancelID.poll, cancelInFlight: true)
  }
}
