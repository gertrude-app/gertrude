import GertieUI
import SwiftUI

struct ActionScreenCatalogView: View {
  var body: some View {
    List {
      NavigationLink("Sequence") {
        ActionScreenSequenceDemo()
      }

      NavigationLink("Default one-action screen") {
        DefaultActionScreenDemo()
      }

      NavigationLink("Two-action question") {
        QuestionActionScreenDemo()
      }

      NavigationLink("Error with callback and link") {
        ErrorActionScreenDemo()
      }

      NavigationLink("Bullets and disabled action") {
        BulletsActionScreenDemo()
      }

      NavigationLink("Progress behavior") {
        ProgressActionScreenDemo()
      }

      NavigationLink("Supplement media") {
        SupplementActionScreenDemo()
      }
    }
    .navigationTitle("Action Screen")
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct ActionScreenSequenceDemo: View {
  @Environment(\.dismiss) private var dismiss
  @State private var step = Step.defaultScreen
  @State private var shouldFinishProgress = false

  var body: some View {
    Group {
      switch self.step {
      case .defaultScreen:
        GertieActionScreen(
          message: "The setup usually takes 5–7 minutes.",
          action: .button("Continue", behavior: .afterExitAnimation) {
            self.step = .question
          },
        )
      case .question:
        GertieActionScreen(
          message: "How old is the person who will use this device?",
          icon: .question,
          actions: [
            .button(
              "Under 18",
              emphasis: .secondary,
              behavior: .afterExitAnimation,
            ) {
              self.step = .error
            },
            .button("18 or older", behavior: .afterExitAnimation) {
              self.step = .error
            },
          ],
        )
      case .error:
        GertieActionScreen(
          message: "Couldn’t reach Gertrude’s servers.",
          icon: .error,
          actions: [
            .button("Try again", behavior: .afterExitAnimation) {
              self.step = .bullets
            },
            .link(
              "Contact support",
              destination: URL(string: "https://gertrude.app/support")!,
            ),
          ],
        )
      case .bullets:
        GertieActionScreen(
          message: "Before continuing, make sure:",
          bullets: [
            "The device is connected to the internet.",
            "You know the device passcode.",
          ],
          actions: [
            .button("Waiting for permission", isEnabled: false) {},
            .button("Continue", behavior: .afterExitAnimation) {
              self.step = .progress
            },
          ],
        )
      case .progress:
        GertieActionScreen(
          message: "Gertrude needs permission before setup can continue.",
          action: .button("Allow permission", behavior: .showProgress) {
            self.shouldFinishProgress = true
          },
        )
        .task(id: self.shouldFinishProgress) {
          await self.finishProgressIfNeeded()
        }
      case .supplement:
        GertieActionScreen(
          message: "Follow the steps shown here, then return to Gertrude.",
          action: .button("Finish", behavior: .afterExitAnimation) {
            self.dismiss()
          },
          supplementPlacement: .beforeMessage,
        ) {
          Image(systemName: "iphone.gen3.radiowaves.left.and.right")
            .font(.system(size: 72, weight: .light))
            .foregroundStyle(Color.violet500)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 12)
            .accessibilityLabel("iPhone setup illustration")
        }
      }
    }
    .toolbar(.hidden, for: .navigationBar)
  }

  @MainActor private func finishProgressIfNeeded() async {
    guard self.shouldFinishProgress else { return }

    do {
      try await Task.sleep(for: .milliseconds(800))
    } catch {
      return
    }

    guard !Task.isCancelled, self.step == .progress else { return }
    self.step = .supplement
  }

  private enum Step {
    case defaultScreen
    case question
    case error
    case bullets
    case progress
    case supplement
  }
}

private struct DefaultActionScreenDemo: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    GertieActionScreen(
      message: "The setup usually takes 5–7 minutes.",
      action: .button("Continue") {
        self.dismiss()
      },
    )
    .navigationTitle("Default")
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct QuestionActionScreenDemo: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    GertieActionScreen(
      message: "How old is the person who will use this device?",
      icon: .question,
      actions: [
        .button("Under 18", emphasis: .secondary) {
          self.dismiss()
        },
        .button("18 or older") {
          self.dismiss()
        },
      ],
    )
    .navigationTitle("Question")
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct ErrorActionScreenDemo: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    GertieActionScreen(
      message: "Couldn’t reach Gertrude’s servers.",
      icon: .error,
      actions: [
        .button("Try again", behavior: .afterExitAnimation) {
          self.dismiss()
        },
        .link(
          "Contact support",
          destination: URL(string: "https://gertrude.app/support")!,
        ),
      ],
    )
    .navigationTitle("Error")
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct BulletsActionScreenDemo: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    GertieActionScreen(
      message: "Before continuing, make sure:",
      bullets: [
        "The device is connected to the internet.",
        "You know the device passcode.",
      ],
      actions: [
        .button("Waiting for permission", isEnabled: false) {},
        .button("Go back") {
          self.dismiss()
        },
      ],
    )
    .navigationTitle("Bullets")
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct ProgressActionScreenDemo: View {
  var body: some View {
    GertieActionScreen(
      message: "Gertrude needs permission before setup can continue.",
      action: .button("Allow permission", behavior: .showProgress) {},
    )
    .navigationTitle("Progress")
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct SupplementActionScreenDemo: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    GertieActionScreen(
      message: "Follow the steps shown here, then return to Gertrude.",
      action: .button("Got it") {
        self.dismiss()
      },
      supplementPlacement: .beforeMessage,
    ) {
      Image(systemName: "iphone.gen3.radiowaves.left.and.right")
        .font(.system(size: 72, weight: .light))
        .foregroundStyle(Color.violet500)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 12)
        .accessibilityLabel("iPhone setup illustration")
    }
    .navigationTitle("Supplement")
    .navigationBarTitleDisplayMode(.inline)
  }
}
