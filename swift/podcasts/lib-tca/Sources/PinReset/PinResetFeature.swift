import ComposableArchitecture
import PairQL

@Reducer
struct PinResetFeature {
  @ObservableState
  struct State: Equatable {
    enum Step: Equatable {
      case enterCode
      case setNewPin
      case unclaimed
    }

    var step: Step
    var pinChallenge = PinChallengeFeature.State()
    var showCodeError = false
    var timesShaken = 0

    init(isClaimed: Bool) {
      self.step = isClaimed ? .enterCode : .unclaimed
    }
  }

  enum Action: Equatable {
    case codeSubmitted(Int)
    case consumeSucceeded
    case consumeFailed
    case consumeErrored
    case newPinSubmitted(Int)
    case cancelTapped
    case receivedShake
    case escapeHatchResponse(authorized: Bool)
    case pinChallenge(PinChallengeFeature.Action)
  }

  static let shakesToTriggerEscapeHatch = 5

  @Dependency(\.api) var api
  @Dependency(\.keychain) var keychain
  @Dependency(\.dismiss) var dismiss

  var body: some ReducerOf<Self> {
    Scope(state: \.pinChallenge, action: \.pinChallenge) {
      PinChallengeFeature(logBaseId: "b3d9f1a7") // b3d9f1a7-1, b3d9f1a7-2
    }
    Reduce { state, action in
      switch action {
      case .codeSubmitted(let code):
        state.showCodeError = false
        return .run { send in
          do {
            try await self.api.consumePinResetCode(code)
            await send(.consumeSucceeded)
          } catch let error as PqlError where error.appTag == .incorrectConfirmationCode {
            await send(.consumeFailed)
          } catch {
            await send(.consumeErrored)
          }
        }

      case .consumeSucceeded:
        return .send(.pinChallenge(.pincodeVerified))

      case .consumeFailed:
        state.showCodeError = true
        return .send(.pinChallenge(.pincodeFailed))

      case .consumeErrored:
        state.showCodeError = true
        return .none

      case .pinChallenge(.delegate(.verified)):
        state.step = .setNewPin
        return .none

      case .pinChallenge(.delegate(.cancelled)):
        return .run { _ in await self.dismiss() }

      case .pinChallenge:
        return .none

      case .newPinSubmitted(let pin):
        return .run { _ in
          self.keychain.save(pincode: pin)
          log(.info, .pin, "5f2c8e04", detail: "to: \(pin.redacted)")
          await self.dismiss()
        }

      case .cancelTapped:
        return .run { _ in await self.dismiss() }

      case .receivedShake where state.step == .setNewPin:
        return .none

      case .receivedShake where state.timesShaken + 1 >= Self.shakesToTriggerEscapeHatch:
        state.timesShaken = 0
        return .run { send in
          let authorized = await (try? self.api.pinResetEscapeHatch()) ?? false
          await send(.escapeHatchResponse(authorized: authorized))
        }

      case .receivedShake:
        state.timesShaken += 1
        return .none

      case .escapeHatchResponse(authorized: true):
        state.step = .setNewPin
        state.showCodeError = false
        return .run { _ in log(.warn, .pin, "bf86c342") }

      case .escapeHatchResponse(authorized: false):
        return .none
      }
    }
  }
}
