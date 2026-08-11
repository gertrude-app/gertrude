import GertieUI
import SwiftUI

public enum MusicSetupViewState: Equatable, Sendable {
  case checking
  case welcome
  case parentQuestion
  case selfManagerNudge
  case explainAccount
  case appleMusicPermission
  case requestingAppleMusicPermission
  case appleMusicDenied
  case appleMusicRestricted
  case appleMusicPrivacyAcknowledgementRequired
  case appleMusicStatusUnavailable
  case appleMusicSubscriptionRequired(canShowOffer: Bool)
  case gertrudeConnection(MusicSetupConnectionViewState)
  case deviceRecognized(childName: String)
  case musicAccessUnavailable(childName: String)
}

public enum MusicSetupConnectionViewState: Equatable, Sendable {
  case checking
  case unclaimed(code: Int, audience: MusicClaimAudience)
  case failed
}

/// who is holding the device during setup, which selects the claim-code copy
public enum MusicClaimAudience: Equatable, Sendable {
  case parentPartner
  case selfManagement
}

public enum MusicSetupViewEvent: Equatable, Sendable {
  case appleMusicPermissionTapped
  case deviceRecognizedContinueTapped
  case explainAccountContinueTapped
  case getStartedTapped
  case nudgeContinueTapped
  case parentNoTapped
  case parentYesTapped
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
      MusicSetupSplashView()

    case .welcome:
      GertieWelcomeScreen(
        greeting: "Hi there!",
        message: "Gertrude Music lets parents or accountability partners give access to only selected, approved music.",
        actionTitle: "Get started",
      ) {
        self.onEvent(.getStartedTapped)
      }

    case .parentQuestion:
      GertieActionScreen(
        message: "Are you the parent or accountability partner? Gertrude Music is controlled by a separate Gertrude account, ideally managed by someone other than the person using this device.",
        icon: .question,
        actions: [
          .button("Yes, I’m the parent or partner") {
            self.onEvent(.parentYesTapped)
          },
          .button("No, this device is mine") {
            self.onEvent(.parentNoTapped)
          },
        ],
      )

    case .selfManagerNudge:
      GertieActionScreen(
        message: "Gertrude Music works best when someone else manages the account. A parent or accountability partner chooses what music is allowed, so the choice isn’t in your own hands. You can continue and set it up yourself, but consider asking someone to manage the account for you.",
        action: .button("Continue") {
          self.onEvent(.nudgeContinueTapped)
        },
      )

    case .explainAccount:
      GertieActionScreen(
        message: "Gertrude Music needs a Gertrude account to approve music for this \(musicDeviceType()). Next you’ll connect one.",
        icon: .system("link.circle"),
        action: .button("Got it, next") {
          self.onEvent(.explainAccountContinueTapped)
        },
      )

    case .deviceRecognized(let childName):
      MusicDeviceRecognizedView(childName: childName) {
        self.onEvent(.deviceRecognizedContinueTapped)
      }

    case .musicAccessUnavailable(let childName):
      MusicUnavailableView(childName: childName)

    case .appleMusicPermission:
      GertieActionScreen(
        message: "Gertrude Music needs permission to use Apple Music so music albums can play.",
        icon: .system("music.note.list"),
        action: .button("Continue") {
          self.onEvent(.appleMusicPermissionTapped)
        },
      )

    case .requestingAppleMusicPermission:
      GertieLoadingScreen(message: "Requesting Apple Music permission…")

    case .appleMusicDenied:
      GertieActionScreen(
        message: "Apple Music access is turned off for Gertrude Music. Open Settings and allow Apple Music access, then try again.",
        icon: .error,
        actions: [
          .button("Open Settings") {
            self.onEvent(.settingsTapped)
          },
          .button("Try again") {
            self.onEvent(.retryTapped)
          },
        ],
      )

    case .appleMusicRestricted:
      GertieActionScreen(
        message: "Apple Music access appears to be restricted on this device. It may need to be allowed in Screen Time or device settings.",
        icon: .error,
        actions: [
          .button("Open Settings") {
            self.onEvent(.settingsTapped)
          },
          .button("Try again") {
            self.onEvent(.retryTapped)
          },
        ],
      )

    case .appleMusicPrivacyAcknowledgementRequired:
      GertieActionScreen(
        message: "This Apple ID needs to finish Apple Music setup before playback can start. Finish any iOS prompts, then come back and try again.",
        icon: .error,
        action: .button("Try again") {
          self.onEvent(.retryTapped)
        },
      )

    case .appleMusicStatusUnavailable:
      GertieResultScreen(
        icon: "xmark.circle.fill",
        tone: .error,
        title: "Couldn’t check Apple Music",
        message: "Check your connection and try again.",
        action: .button("Try again") {
          self.onEvent(.retryTapped)
        },
      )

    case .appleMusicSubscriptionRequired(let canShowOffer):
      if canShowOffer {
        GertieActionScreen(
          message: "This device needs an active Apple Music subscription to play approved music.",
          icon: .system("music.note.list"),
          actions: [
            .button("Start subscription") {
              self.onEvent(.subscriptionOfferTapped)
            },
            .button("Check again") {
              self.onEvent(.retryTapped)
            },
          ],
        )
      } else {
        GertieActionScreen(
          message: "This device needs an active Apple Music subscription to play approved music. This Apple ID may not be eligible to start a subscription here.",
          icon: .system("music.note.list"),
          action: .button("Check again") {
            self.onEvent(.retryTapped)
          },
        )
      }

    case .gertrudeConnection(.checking):
      GertieLoadingScreen(message: "Checking Gertrude account connection…")

    case .gertrudeConnection(.unclaimed(let code, let audience)):
      MusicClaimCodeView(code: code, audience: audience)

    case .gertrudeConnection(.failed):
      GertieResultScreen(
        icon: "xmark.circle.fill",
        tone: .error,
        title: "Couldn’t connect to Gertrude",
        message: "Check your internet connection and try again.",
        action: .button("Try again") {
          self.onEvent(.refreshConnectionTapped)
        },
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

#Preview("Parent Question") {
  MusicSetupView(state: .parentQuestion)
}

#Preview("Self Manager Nudge") {
  MusicSetupView(state: .selfManagerNudge)
}

#Preview("Explain Account") {
  MusicSetupView(state: .explainAccount)
}

#Preview("Device Recognized") {
  MusicSetupView(state: .deviceRecognized(childName: "Billy Bob"))
}

#Preview("Music Unavailable") {
  MusicSetupView(state: .musicAccessUnavailable(childName: "Billy Bob"))
}

#Preview("Apple Music Permission") {
  MusicSetupView(state: .appleMusicPermission)
}

#Preview("Requesting Apple Music Permission") {
  MusicSetupView(state: .requestingAppleMusicPermission)
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

#Preview("Gertrude Claim (Parent)") {
  MusicSetupView(state: .gertrudeConnection(.unclaimed(code: 123_456, audience: .parentPartner)))
}

#Preview("Gertrude Claim (Self)") {
  MusicSetupView(state: .gertrudeConnection(.unclaimed(code: 123_456, audience: .selfManagement)))
}

#Preview("Gertrude Connection Failed") {
  MusicSetupView(state: .gertrudeConnection(.failed))
}
