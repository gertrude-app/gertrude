import SwiftUI

public struct GertieWelcomeScreen: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @ScaledMetric(relativeTo: .largeTitle) private var greetingSize = 50.0

  @State private var showBackground = false
  @State private var isLeaving = false
  @State private var didInvokeAction = false

  private let greeting: String
  private let message: String
  private let actionTitle: String
  private let onAction: @MainActor () -> Void

  public init(
    greeting: String,
    message: String,
    actionTitle: String,
    onAction: @MainActor @escaping () -> Void,
  ) {
    self.greeting = greeting
    self.message = message
    self.actionTitle = actionTitle
    self.onAction = onAction
  }

  public var body: some View {
    ZStack {
      GertieWelcomeBackground()
        .opacity(self.showBackground ? 1 : 0)
        .ignoresSafeArea()

      GeometryReader { proxy in
        let usesCenteredLayout = proxy.size.width >= 600

        ScrollView {
          VStack(alignment: usesCenteredLayout ? .center : .leading, spacing: 12) {
            self.greetingView

            Text(verbatim: self.message)
              .font(.system(size: 16, weight: .medium))
              .foregroundStyle(Color(self.colorScheme, light: .violet950, dark: .violet100))
              .multilineTextAlignment(usesCenteredLayout ? .center : .leading)
              .fixedSize(horizontal: false, vertical: true)
              .accessibilityIdentifier("onboarding-screen-hi-there")
              .swooshIn(
                fromYOffset: 20,
                after: .seconds(1.0),
              )
              .modifier(GertieWelcomeExitModifier(
                isExiting: self.isLeaving,
                delay: 0.1,
              ))

            Button(action: self.handleAction) {
              Text(verbatim: self.actionTitle)
            }
            .buttonStyle(.gertiePrimary)
            .accessibilityIdentifier("btn-primary")
            .allowsHitTesting(!self.isLeaving)
            .swooshIn(
              fromYOffset: 20,
              after: .seconds(1.3),
            )
            .modifier(GertieWelcomeExitModifier(isExiting: self.isLeaving))
            .padding(.top, 20)
          }
          .frame(
            minHeight: max(0, proxy.size.height - 60),
            alignment: usesCenteredLayout ? .center : .bottomLeading,
          )
          .padding(30)
          .frame(maxWidth: 500)
          .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
      }
    }
    .onAppear(perform: self.beginEntranceAnimations)
    .task(id: self.isLeaving) {
      await self.finishExitIfNeeded()
    }
  }

  @ViewBuilder private var greetingView: some View {
    if self.dynamicTypeSize.isAccessibilitySize {
      Text(verbatim: self.greeting)
        .font(.largeTitle.weight(.black))
        .foregroundStyle(Color(self.colorScheme, light: .violet950, dark: .violet100))
        .fixedSize(horizontal: false, vertical: true)
        .swooshIn(
          fromYOffset: 40,
          after: .seconds(0.5),
          animation: .bouncy(duration: 0.6, extraBounce: 0.3),
        )
        .modifier(GertieWelcomeExitModifier(
          isExiting: self.isLeaving,
          delay: 0.2,
        ))
        .accessibilityAddTraits(.isHeader)
    } else {
      HStack(spacing: 0) {
        ForEach(Array(self.greeting.enumerated()), id: \.offset) { index, character in
          Text(verbatim: String(character))
            .font(.system(size: self.greetingSize, weight: .black))
            .foregroundStyle(Color(self.colorScheme, light: .violet950, dark: .violet100))
            .swooshIn(
              fromYOffset: 40,
              after: .seconds(Double(index) / 15.0 + 0.5),
              animation: .bouncy(duration: 0.6, extraBounce: 0.3),
            )
            .modifier(GertieWelcomeExitModifier(
              isExiting: self.isLeaving,
              delay: 0.2,
            ))
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Text(verbatim: self.greeting))
      .accessibilityAddTraits(.isHeader)
    }
  }

  @MainActor private func beginEntranceAnimations() {
    guard !self.reduceMotion else {
      self.showBackground = true
      return
    }

    withAnimation(.smooth(duration: 1.2)) {
      self.showBackground = true
    }
  }

  @MainActor private func handleAction() {
    guard !self.isLeaving else { return }
    self.isLeaving = true

    guard !self.reduceMotion else {
      self.didInvokeAction = true
      self.onAction()
      return
    }

    withAnimation(.smooth(duration: 1)) {
      self.showBackground = false
    }
  }

  @MainActor private func finishExitIfNeeded() async {
    guard self.isLeaving, !self.reduceMotion, !self.didInvokeAction else { return }

    do {
      try await Task.sleep(for: .milliseconds(800))
    } catch {
      return
    }

    guard !Task.isCancelled else { return }
    self.didInvokeAction = true
    self.onAction()
  }
}

private struct GertieWelcomeExitModifier: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let isExiting: Bool
  var delay = 0.0

  func body(content: Content) -> some View {
    content
      .offset(y: self.isExiting ? 50 : 0)
      .opacity(self.isExiting ? 0 : 1)
      .blur(radius: self.isExiting ? 10 : 0)
      .animation(
        self.reduceMotion ? nil : .smooth(duration: 0.5).delay(self.delay),
        value: self.isExiting,
      )
  }
}

#Preview("Welcome") {
  GertieWelcomeScreen(
    greeting: "Hi there!",
    message: "Gertrude helps families use technology with purpose and accountability.",
    actionTitle: "Get started",
  ) {}
}
