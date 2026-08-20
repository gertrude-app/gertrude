import BlockerRoute
import ComposableArchitecture
import Dependencies
import LibClients

@Reducer
public struct ConnectAccount {
  @ObservableState
  public struct State: Equatable {
    public var screen: SubScreen = .generatingCode

    public init(screen: SubScreen = .generatingCode) {
      self.screen = screen
    }
  }

  public enum Action: Equatable {
    case cancelTapped
    case codeGenerationFailed
    case codeResponse(code: Int)
    case connectionSucceeded(childData: ChildIOSDeviceData_v2)
    case onAppear
    case polled(CheckBlockerConnectionStatus.Output)
    case retryTapped
  }

  enum CancelID { case poll }

  struct Deps: Sendable {
    @Dependency(\.api) var api
    @Dependency(\.continuousClock) var clock
  }

  @ObservationIgnored
  let deps = Deps()

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .cancelTapped:
        return .none

      case .onAppear:
        guard state.screen == .generatingCode else { return .none }
        return self.startGeneratingCode(&state)

      case .retryTapped:
        return self.startGeneratingCode(&state)

      case .codeResponse(let code):
        state.screen = .showingCode(code: code)
        return .none

      case .codeGenerationFailed:
        state.screen = .codeGenerationFailed
        return .none

      case .polled(let status):
        switch status {
        case .connected(let data):
          return .merge(
            .cancel(id: CancelID.poll),
            .send(.connectionSucceeded(childData: data)),
          )
        case .expired, .notFound:
          state.screen = .codeGenerationFailed
          return .cancel(id: CancelID.poll)
        case .pending:
          return .none
        }

      case .connectionSucceeded:
        return .none
      }
    }
  }

  func startGeneratingCode(_ state: inout State) -> EffectOf<ConnectAccount> {
    state.screen = .generatingCode
    return .run { [deps = self.deps] send in
      let code: Int
      do {
        code = try await deps.api.createBlockerClaimCode().code
      } catch {
        await send(.codeGenerationFailed)
        return
      }
      await send(.codeResponse(code: code))
      while !Task.isCancelled {
        try await deps.clock.sleep(for: .seconds(5))
        if let status = try? await deps.api.checkBlockerConnectionStatus(code) {
          await send(.polled(status))
        }
      }
    }
    .cancellable(id: CancelID.poll, cancelInFlight: true)
  }

  public init() {}
}

public extension ConnectAccount.State {
  enum SubScreen: Equatable {
    case generatingCode
    case showingCode(code: Int)
    case codeGenerationFailed
  }
}
