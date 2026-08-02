import SwiftUI

public struct GertieLoadingScreen: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.colorScheme) private var colorScheme
  @ScaledMetric(relativeTo: .body) private var messageSize = 18.0

  @State private var showBackground = false

  private let message: String

  public init(message: String) {
    self.message = message
  }

  public var body: some View {
    ZStack {
      GertieScreenBackground()
        .opacity(self.showBackground ? 1 : 0)
        .ignoresSafeArea()

      GeometryReader { proxy in
        ScrollView {
          VStack(spacing: 20) {
            Spacer(minLength: 0)

            ProgressView {
              Text(verbatim: self.message)
            }
            .labelsHidden()
            .scaleEffect(1.5)
            .tint(Color(self.colorScheme, light: .violet500, dark: .violet400))

            Text(verbatim: self.message)
              .font(.system(size: self.messageSize, weight: .medium))
              .foregroundStyle(
                Color(self.colorScheme, light: .violet900, dark: .violet100),
              )
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)
              .accessibilityHidden(true)

            Spacer(minLength: 0)
          }
          .frame(
            minHeight: max(0, proxy.size.height - 60),
            alignment: .center,
          )
          .padding(30)
          .frame(maxWidth: 500)
          .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
      }
    }
    .onAppear(perform: self.beginEntranceAnimation)
  }

  @MainActor private func beginEntranceAnimation() {
    guard !self.reduceMotion else {
      self.showBackground = true
      return
    }

    withAnimation(.smooth(duration: 0.4)) {
      self.showBackground = true
    }
  }
}

public struct GertieWaitingStatus: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.colorScheme) private var colorScheme
  @ScaledMetric(relativeTo: .subheadline) private var labelSize = 14.0

  @State private var showLabel = false

  private let label: String
  private let delay: Duration

  public init(label: String, delay: Duration) {
    self.label = label
    self.delay = delay
  }

  public var body: some View {
    HStack(spacing: 8) {
      ProgressView {
        Text(verbatim: self.label)
      }
      .labelsHidden()
      .scaleEffect(0.7)
      .tint(Color(self.colorScheme, light: .violet500, dark: .violet400))

      if self.showLabel {
        Text(verbatim: self.label)
          .font(.system(size: self.labelSize, weight: .medium))
          .foregroundStyle(
            Color(self.colorScheme, light: .violet700, dark: .violet300),
          )
          .fixedSize(horizontal: false, vertical: true)
          .transition(.opacity)
          .accessibilityHidden(true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .center)
    .task {
      await self.revealLabel()
    }
  }

  @MainActor private func revealLabel() async {
    do {
      try await Task.sleep(for: self.delay)
    } catch {
      return
    }

    guard !Task.isCancelled else { return }
    guard !self.reduceMotion else {
      self.showLabel = true
      return
    }

    withAnimation(.smooth(duration: 0.3)) {
      self.showLabel = true
    }
  }
}

#Preview("Loading") {
  GertieLoadingScreen(message: "Checking setup…")
}

#Preview("Loading with long message") {
  GertieLoadingScreen(
    message: "Please wait while Gertrude fetches and validates the information needed to continue.",
  )
}

#Preview("Loading dark") {
  GertieLoadingScreen(message: "Connecting to Gertrude…")
    .preferredColorScheme(.dark)
}

#Preview("Loading accessibility text") {
  GertieLoadingScreen(
    message: "Please wait while Gertrude fetches and validates the information needed to continue.",
  )
  .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Waiting status") {
  GertieWaitingStatus(
    label: "Waiting for account connection…",
    delay: .zero,
  )
  .padding()
}

#Preview("Waiting status delayed") {
  GertieWaitingStatus(
    label: "Waiting for the subscription…",
    delay: .seconds(2),
  )
  .padding()
}
