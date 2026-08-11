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

  var body: some View {
    Group {
      switch self.step {
      case .defaultScreen:
        DefaultActionScreenDemo {
          self.step = .question
        }
      case .question:
        QuestionActionScreenDemo {
          self.step = .error
        }
      case .error:
        ErrorActionScreenDemo {
          self.step = .bullets
        }
      case .bullets:
        BulletsActionScreenDemo {
          self.step = .progress
        }
      case .progress:
        ProgressActionScreenDemo {
          self.step = .supplement
        }
      case .supplement:
        SupplementActionScreenDemo {
          self.dismiss()
        }
      }
    }
    .toolbar(.hidden, for: .navigationBar)
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

  let onComplete: (@MainActor () -> Void)?

  init(onComplete: (@MainActor () -> Void)? = nil) {
    self.onComplete = onComplete
  }

  var body: some View {
    GertieActionScreen(
      message: "The setup usually takes 5–7 minutes.",
      action: .button("Continue", behavior: .afterExitAnimation) {
        self.complete()
      },
    )
    .navigationTitle("Default")
    .navigationBarTitleDisplayMode(.inline)
  }

  @MainActor private func complete() {
    if let onComplete = self.onComplete {
      onComplete()
    } else {
      self.dismiss()
    }
  }
}

private struct QuestionActionScreenDemo: View {
  @Environment(\.dismiss) private var dismiss

  let onComplete: (@MainActor () -> Void)?

  init(onComplete: (@MainActor () -> Void)? = nil) {
    self.onComplete = onComplete
  }

  var body: some View {
    GertieActionScreen(
      message: "How old is the person who will use this device?",
      icon: .question,
      actions: [
        .button(
          "Under 18",
          emphasis: .secondary,
          behavior: .afterExitAnimation,
        ) {
          self.complete()
        },
        .button("18 or older", behavior: .afterExitAnimation) {
          self.complete()
        },
      ],
    )
    .navigationTitle("Question")
    .navigationBarTitleDisplayMode(.inline)
  }

  @MainActor private func complete() {
    if let onComplete = self.onComplete {
      onComplete()
    } else {
      self.dismiss()
    }
  }
}

private struct ErrorActionScreenDemo: View {
  @Environment(\.dismiss) private var dismiss

  let onComplete: (@MainActor () -> Void)?

  init(onComplete: (@MainActor () -> Void)? = nil) {
    self.onComplete = onComplete
  }

  var body: some View {
    GertieActionScreen(
      message: "Couldn’t reach Gertrude’s servers.",
      icon: .error,
      actions: [
        .button("Try again", behavior: .afterExitAnimation) {
          self.complete()
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

  @MainActor private func complete() {
    if let onComplete = self.onComplete {
      onComplete()
    } else {
      self.dismiss()
    }
  }
}

private struct BulletsActionScreenDemo: View {
  @Environment(\.dismiss) private var dismiss

  let onComplete: (@MainActor () -> Void)?

  init(onComplete: (@MainActor () -> Void)? = nil) {
    self.onComplete = onComplete
  }

  var body: some View {
    GertieActionScreen(
      message: "Before continuing, make sure:",
      bullets: [
        "The device is connected to the internet.",
        "You know the device passcode.",
      ],
      actions: [
        .button("Waiting for permission", isEnabled: false) {},
        .button("Continue", behavior: .afterExitAnimation) {
          self.complete()
        },
      ],
    )
    .navigationTitle("Bullets")
    .navigationBarTitleDisplayMode(.inline)
  }

  @MainActor private func complete() {
    if let onComplete = self.onComplete {
      onComplete()
    } else {
      self.dismiss()
    }
  }
}

private struct ProgressActionScreenDemo: View {
  @State private var shouldFinish = false

  let onComplete: (@MainActor () -> Void)?

  init(onComplete: (@MainActor () -> Void)? = nil) {
    self.onComplete = onComplete
  }

  var body: some View {
    GertieActionScreen(
      message: "Gertrude needs permission before setup can continue.",
      action: .button("Allow permission", behavior: .showProgress) {
        self.shouldFinish = true
      },
    )
    .navigationTitle("Progress")
    .navigationBarTitleDisplayMode(.inline)
    .task(id: self.shouldFinish) {
      await self.finishIfNeeded()
    }
  }

  @MainActor private func finishIfNeeded() async {
    guard self.shouldFinish, let onComplete = self.onComplete else { return }

    do {
      try await Task.sleep(for: .milliseconds(800))
    } catch {
      return
    }

    guard !Task.isCancelled, self.shouldFinish else { return }
    onComplete()
  }
}

private struct SupplementActionScreenDemo: View {
  @Environment(\.dismiss) private var dismiss

  let onComplete: (@MainActor () -> Void)?

  init(onComplete: (@MainActor () -> Void)? = nil) {
    self.onComplete = onComplete
  }

  var body: some View {
    GertieActionScreen(
      message: "Follow the steps shown here, then return to Gertrude.",
      action: .button("Finish", behavior: .afterExitAnimation) {
        self.complete()
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

  @MainActor private func complete() {
    if let onComplete = self.onComplete {
      onComplete()
    } else {
      self.dismiss()
    }
  }
}
