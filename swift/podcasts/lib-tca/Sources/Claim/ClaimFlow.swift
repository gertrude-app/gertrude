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
      case onboarding
    }

    enum Step: Equatable {
      case showingCode
      case success
      case payment
    }

    var successIsTerminal: Bool {
      self.entitlement?.claimSuccessEntitlement != nil
    }
  }

  enum Action: Equatable {
    case accountStatusResponse(GetAccountStatus.Output, generation: Int? = nil)
    case cancelTapped
    case claimCodeFailed(generation: Int? = nil)
    case claimCodeResponse(code: Int, generation: Int? = nil)
    case doneTapped
    case nextTapped
    case notNowTapped
    case onAppear
    case polled(GetTrialStatus.Output, generation: Int? = nil)
    case retryTapped
  }

  enum CancelID {
    case poll
    case identityWork
  }

  @Shared(.podcastIdentityGeneration) var generation
  @Dependency(\.podcastIdentity) var identity
  @Dependency(\.api) var api
  @Dependency(\.continuousClock) var clock
  @Dependency(\.dismiss) var dismiss

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        log(.info, .claim, "6ba6a016", detail: "\(state.context)/\(state.step)")
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

      case .claimCodeResponse(let code, let generation):
        guard generation == nil || generation == self.generation else { return .none }
        log(.info, .claim, "de4909f1")
        state.claimCode = code
        state.claimCodeFailed = false
        return .none

      case .claimCodeFailed(let generation):
        guard generation == nil || generation == self.generation else { return .none }
        log(.err, .claim, "b2cb8725")
        state.claimCodeFailed = true
        return .none

      case .polled(let output, let generation):
        guard generation == nil || generation == self.generation else { return .none }
        guard case .connected(_, _, let childName, let subscription) = output else {
          return .none
        }
        log(.info, .subs, "9b9ea2d6", detail: "\(subscription)")
        state.childName = childName
        state.entitlement = subscription
        state.step = .success
        return .cancel(id: CancelID.poll)

      case .nextTapped:
        if state.context == .onboarding {
          return self.dismissFlow()
        }
        log(.info, .claim, "82b8e4c0")
        state.step = .payment
        return self.startPayment()

      case .accountStatusResponse(let output, let generation):
        guard generation == nil || generation == self.generation else { return .none }
        state.entitlement = output.subscription
        guard output.subscription.isEntitled else { return .none }
        log(.info, .subs, "c6cae011", detail: "\(output.subscription)")
        return self.dismissFlow()

      case .cancelTapped:
        log(.info, .claim, "c4ef5b66", detail: "\(state.step)")
        return self.dismissFlow()

      case .notNowTapped:
        log(.info, .claim, "32bb0769")
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
    let generation = self.generation
    state.claimCode = nil
    state.claimCodeFailed = false
    return .merge(
      .run { send in
        do {
          let session = await self.identity.current()
          let output = try await self.api.createClaimCode()
          try await self.identity.validate(session)
          await send(.claimCodeResponse(code: output.code, generation: generation))
        } catch {
          await send(.claimCodeFailed(generation: generation))
        }
      }
      .cancellable(id: CancelID.identityWork, cancelInFlight: true),
      .run { send in
        while !Task.isCancelled {
          try await self.clock.sleep(for: .seconds(5))
          let session = await self.identity.current()
          if let output = try? await self.api.getTrialStatus() {
            try await self.identity.acceptTrialStatus(output, for: session)
            await send(.polled(output, generation: generation))
          }
        }
      }
      .cancellable(id: CancelID.poll, cancelInFlight: true),
    )
  }

  func startPayment() -> EffectOf<ClaimFlow> {
    let generation = self.generation
    return .run { send in
      while !Task.isCancelled {
        try await self.clock.sleep(for: .seconds(5))
        let session = await self.identity.current()
        if let output = try? await self.api.getAccountStatus() {
          try await self.identity.acceptAccountStatus(output, for: session)
          await send(.accountStatusResponse(output, generation: generation))
        }
      }
    }
    .cancellable(id: CancelID.poll, cancelInFlight: true)
  }
}
