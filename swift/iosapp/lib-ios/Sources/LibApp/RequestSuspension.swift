import ComposableArchitecture
import Foundation
import LibClients
import TaggedTime

@Reducer
public struct RequestSuspension {
  @ObservableState
  public enum State: Equatable {
    case customizing
    case requesting
    case requestFailed(error: String)
    case waitingForDecision
    case requestExpired
    case denied(comment: String?)
    case granted(duration: Seconds<Int>, comment: String?)
    case recording
  }

  public enum Action: Equatable {
    case submitRequest(duration: Seconds<Int>, comment: String?)
    case requestSucceeded(UUID)
    case setState(State)
    case startRecordingTapped
    case endSuspensionTapped
  }

  struct Deps: Sendable {
    @Dependency(\.api) var api
  }

  @ObservationIgnored
  let deps = Deps()

  public init() {}

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .setState(let newState):
        state = newState
        return .none

      case .submitRequest(let duration, let comment):
        state = .requesting
        return .run { [deps = self.deps] send in
          do {
            let id = try await deps.api.createSuspendFilterRequest(
              duration: duration,
              comment: comment,
            )
            await send(.requestSucceeded(id))
          } catch {
            await send(.setState(.requestFailed(error: error.localizedDescription)))
          }
        }

      case .requestSucceeded:
        state = .waitingForDecision
        return .none

      case .startRecordingTapped:
        state = .recording
        return .none

      case .endSuspensionTapped:
        return .none
      }
    }
  }
}
