import GertieUI
import SwiftUI

public struct PodcastsWelcomeScreen: View {
  private let onAction: @MainActor () -> Void

  public init(onAction: @MainActor @escaping () -> Void) {
    self.onAction = onAction
  }

  public var body: some View {
    GertieWelcomeScreen(
      greeting: lstr(.welcomeGreeting),
      message: lstr(.welcomeDescription),
      actionTitle: lstr(.welcomeGetStarted),
      onAction: self.onAction,
    )
  }
}

#Preview {
  PodcastsWelcomeScreen {}
}
