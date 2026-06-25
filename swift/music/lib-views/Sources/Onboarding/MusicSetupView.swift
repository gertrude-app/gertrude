import SwiftUI

public enum MusicSetupViewState: Equatable, Sendable {
  case checking
  case welcome
  case appleMusicPermission
  case appleMusicDenied
  case appleMusicRestricted
  case appleMusicPrivacyAcknowledgementRequired
  case appleMusicStatusUnavailable
  case appleMusicSubscriptionRequired(canShowOffer: Bool)
  case gertrudeConnection(MusicSetupConnectionViewState)
}

public enum MusicSetupConnectionViewState: Equatable, Sendable {
  case checking
  case unclaimed(code: Int)
  case failed
}

public enum MusicSetupViewEvent: Equatable, Sendable {
  case appleMusicPermissionTapped
  case getStartedTapped
  case refreshConnectionTapped
  case retryTapped
  case settingsTapped
  case subscriptionOfferTapped
}

public struct MusicSetupView: View {
  private let state: MusicSetupViewState
  private let onEvent: @MainActor @Sendable (MusicSetupViewEvent) -> Void

  public init(
    state: MusicSetupViewState,
    onEvent: @MainActor @escaping @Sendable (MusicSetupViewEvent) -> Void = { _ in },
  ) {
    self.state = state
    self.onEvent = onEvent
  }

  public var body: some View {
    switch self.state {
    case .checking:
      LoadingScreenView(text: "Checking setup…")

    case .welcome:
      MusicSetupWelcomeView {
        self.onEvent(.getStartedTapped)
      }

    case .appleMusicPermission:
      ButtonScreenView(
        text: "Gertrude Music needs permission to use Apple Music so approved albums can play.",
        primary: .init("Allow Apple Music Access", animate: false, asyncAction: true) {
          self.onEvent(.appleMusicPermissionTapped)
        },
        screenType: .music,
      )

    case .appleMusicDenied:
      ButtonScreenView(
        text: "Apple Music access is turned off for Gertrude Music. Open Settings and allow Apple Music access, then try again.",
        primary: .init("Open Settings", animate: false) {
          self.onEvent(.settingsTapped)
        },
        secondary: .init("Try again", animate: false) {
          self.onEvent(.retryTapped)
        },
        screenType: .error,
      )

    case .appleMusicRestricted:
      ButtonScreenView(
        text: "Apple Music access appears to be restricted on this device. It may need to be allowed in Screen Time or device settings.",
        primary: .init("Open Settings", animate: false) {
          self.onEvent(.settingsTapped)
        },
        secondary: .init("Try again", animate: false) {
          self.onEvent(.retryTapped)
        },
        screenType: .error,
      )

    case .appleMusicPrivacyAcknowledgementRequired:
      ButtonScreenView(
        text: "This Apple ID needs to finish Apple Music setup before playback can start. Finish any iOS prompts, then come back and try again.",
        primary: .init("Try again", animate: false) {
          self.onEvent(.retryTapped)
        },
        screenType: .error,
      )

    case .appleMusicStatusUnavailable:
      ButtonScreenView(
        text: "Gertrude Music couldn’t check Apple Music on this device. Check your connection and try again.",
        primary: .init("Try again", animate: false) {
          self.onEvent(.retryTapped)
        },
        screenType: .error,
      )

    case .appleMusicSubscriptionRequired(let canShowOffer):
      ButtonScreenView(
        text: canShowOffer
          ? "This device needs an active Apple Music subscription to play approved music."
          :
          "This device needs an active Apple Music subscription to play approved music. This Apple ID may not be eligible to start a subscription here.",
        primary: canShowOffer ? .init("Start subscription", animate: false) {
          self.onEvent(.subscriptionOfferTapped)
        } : .init("Check again", animate: false) {
          self.onEvent(.retryTapped)
        },
        secondary: canShowOffer ? .init("Check again", animate: false) {
          self.onEvent(.retryTapped)
        } : nil,
        screenType: .music,
      )

    case .gertrudeConnection(.checking):
      LoadingScreenView(text: "Checking Gertrude account connection…")

    case .gertrudeConnection(.unclaimed(code: let code)):
      MusicClaimCodeView(code: code) {
        self.onEvent(.refreshConnectionTapped)
      }

    case .gertrudeConnection(.failed):
      ButtonScreenView(
        text: "Gertrude Music couldn’t connect to Gertrude. Check your internet connection and try again.",
        primary: .init("Try again", animate: false) {
          self.onEvent(.refreshConnectionTapped)
        },
        screenType: .error,
      )
    }
  }
}

#Preview("Checking") {
  MusicSetupView(state: .checking)
}

#Preview("Welcome") {
  MusicSetupView(state: .welcome)
}

#Preview("Apple Music Permission") {
  MusicSetupView(state: .appleMusicPermission)
}

#Preview("Apple Music Denied") {
  MusicSetupView(state: .appleMusicDenied)
}

#Preview("Apple Music Restricted") {
  MusicSetupView(state: .appleMusicRestricted)
}

#Preview("Apple Music Privacy") {
  MusicSetupView(state: .appleMusicPrivacyAcknowledgementRequired)
}

#Preview("Apple Music Unavailable") {
  MusicSetupView(state: .appleMusicStatusUnavailable)
}

#Preview("Subscription Offer") {
  MusicSetupView(state: .appleMusicSubscriptionRequired(canShowOffer: true))
}

#Preview("Subscription Ineligible") {
  MusicSetupView(state: .appleMusicSubscriptionRequired(canShowOffer: false))
}

#Preview("Gertrude Connection Checking") {
  MusicSetupView(state: .gertrudeConnection(.checking))
}

#Preview("Gertrude Claim") {
  MusicSetupView(state: .gertrudeConnection(.unclaimed(code: 123_456)))
}

#Preview("Gertrude Connection Failed") {
  MusicSetupView(state: .gertrudeConnection(.failed))
}
