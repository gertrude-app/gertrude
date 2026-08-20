import Foundation
import SwiftUI

public struct GertieResultScreen: View {
  public enum Tone {
    case standard
    case error
  }

  public struct Action {
    public enum TriggerBehavior {
      case immediate
      case afterExitAnimation
    }

    fileprivate let title: String
    fileprivate let behavior: TriggerBehavior
    fileprivate let callback: @MainActor () -> Void

    private init(
      title: String,
      behavior: TriggerBehavior,
      callback: @MainActor @escaping () -> Void,
    ) {
      self.title = title
      self.behavior = behavior
      self.callback = callback
    }

    public static func button(
      _ title: String,
      behavior: TriggerBehavior = .immediate,
      action: @MainActor @escaping () -> Void,
    ) -> Self {
      Self(title: title, behavior: behavior, callback: action)
    }
  }

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.colorScheme) private var colorScheme
  @ScaledMetric(relativeTo: .title2) private var iconSize = 48.0
  @ScaledMetric(relativeTo: .title2) private var titleSize = 24.0
  @ScaledMetric(relativeTo: .body) private var messageSize = 16.0

  @State private var showBackground = false
  @State private var response = ActionResponse.idle

  private let icon: String
  private let tone: Tone
  private let title: String
  private let message: String?
  private let accessibilityIdentifier: String?
  private let action: Action?
  private let secondaryAction: Action?

  public init(
    icon: String,
    tone: Tone = .standard,
    title: String,
    message: String? = nil,
    accessibilityIdentifier: String? = nil,
    action: Action? = nil,
    secondaryAction: Action? = nil,
  ) {
    self.icon = icon
    self.tone = tone
    self.title = title
    self.message = message
    self.accessibilityIdentifier = accessibilityIdentifier
    self.action = action
    self.secondaryAction = secondaryAction
  }

  public var body: some View {
    ZStack {
      GertieScreenBackground()
        .opacity(self.showBackground ? 1 : 0)
        .ignoresSafeArea()

      GeometryReader { proxy in
        ScrollView {
          VStack(spacing: 24) {
            Spacer(minLength: 0)

            Image(systemName: self.icon)
              .font(.system(size: self.iconSize, weight: .regular))
              .foregroundStyle(self.iconColor)
              .accessibilityHidden(true)
              .swooshIn(
                fromYOffset: 20,
                animation: .bouncy(duration: 0.6, extraBounce: 0.3),
              )
              .modifier(
                GertieResultScreenExitModifier(
                  isExiting: self.isExiting,
                  yOffset: -20,
                ),
              )

            VStack(spacing: 8) {
              Text(verbatim: self.title)
                .font(.system(size: self.titleSize, weight: .bold))
                .foregroundStyle(
                  Color(self.colorScheme, light: .violet950, dark: .violet100),
                )
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

              if let message = self.message {
                Text(verbatim: message)
                  .font(.system(size: self.messageSize, weight: .medium))
                  .foregroundStyle(
                    Color(self.colorScheme, light: .violet950, dark: .violet100).opacity(0.8),
                  )
                  .multilineTextAlignment(.center)
                  .fixedSize(horizontal: false, vertical: true)
              }
            }
            .modifier(GertieResultScreenAccessibilityIdentifier(
              identifier: self.accessibilityIdentifier,
            ))
            .swooshIn(
              fromYOffset: 20,
              after: .milliseconds(100),
              animation: .bouncy(duration: 0.6, extraBounce: 0.3),
            )
            .modifier(
              GertieResultScreenExitModifier(
                isExiting: self.isExiting,
                yOffset: 20,
                delay: 0.06,
              ),
            )

            if self.action != nil || self.secondaryAction != nil {
              VStack(spacing: 12) {
                if let action = self.action {
                  Button(action.title) {
                    self.actionTriggered(action)
                  }
                  .buttonStyle(.gertiePrimary)
                  .accessibilityIdentifier("btn-primary")
                  .disabled(self.isResponding)
                  .swooshIn(
                    fromYOffset: 20,
                    after: .milliseconds(200),
                    animation: .bouncy(duration: 0.6, extraBounce: 0.3),
                  )
                  .modifier(
                    GertieResultScreenExitModifier(
                      isExiting: self.isExiting,
                      yOffset: 20,
                      delay: 0.06,
                    ),
                  )
                }

                if let secondaryAction = self.secondaryAction {
                  Button(secondaryAction.title) {
                    self.actionTriggered(secondaryAction)
                  }
                  .buttonStyle(.gertieSecondary)
                  .accessibilityIdentifier("btn-secondary")
                  .disabled(self.isResponding)
                  .swooshIn(
                    fromYOffset: 20,
                    after: self.action == nil
                      ? .milliseconds(200)
                      : .milliseconds(280),
                    animation: .bouncy(duration: 0.6, extraBounce: 0.3),
                  )
                  .modifier(
                    GertieResultScreenExitModifier(
                      isExiting: self.isExiting,
                      yOffset: 20,
                    ),
                  )
                }
              }
              .padding(.horizontal, 30)
            }

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
    .task(id: self.exitTaskID) {
      await self.invokeExitActionIfNeeded()
    }
  }

  private var isResponding: Bool {
    switch self.response {
    case .idle:
      false
    case .exiting, .exitCompleted:
      true
    }
  }

  private var isExiting: Bool {
    switch self.response {
    case .exiting, .exitCompleted:
      true
    case .idle:
      false
    }
  }

  private var exitTaskID: ExitTaskID {
    guard case .exiting(let id, _) = self.response else {
      return ExitTaskID(id: nil, skipsMotion: self.reduceMotion)
    }
    return ExitTaskID(id: id, skipsMotion: self.reduceMotion)
  }

  private var iconColor: Color {
    switch self.tone {
    case .standard:
      Color(self.colorScheme, light: .violet500, dark: .violet400)
    case .error:
      Color(self.colorScheme, light: .red, dark: .red.opacity(0.8))
    }
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

  @MainActor private func actionTriggered(_ action: Action) {
    guard case .idle = self.response else { return }

    switch action.behavior {
    case .immediate:
      action.callback()
    case .afterExitAnimation:
      self.response = .exiting(id: UUID(), action: action.callback)
      guard !self.reduceMotion else {
        self.showBackground = false
        return
      }
      withAnimation(.smooth(duration: 0.4).delay(0.05)) {
        self.showBackground = false
      }
    }
  }

  @MainActor private func invokeExitActionIfNeeded() async {
    guard case .exiting(let id, _) = self.response else { return }

    if !self.reduceMotion {
      do {
        try await Task.sleep(for: .milliseconds(500))
      } catch {
        return
      }
    }

    guard !Task.isCancelled else { return }
    guard case .exiting(let currentID, let action) = self.response else {
      return
    }
    guard currentID == id else { return }

    self.response = .exitCompleted
    action()
  }

  private enum ActionResponse {
    case idle
    case exiting(
      id: UUID,
      action: @MainActor () -> Void,
    )
    case exitCompleted
  }

  private struct ExitTaskID: Equatable {
    let id: UUID?
    let skipsMotion: Bool
  }
}

private struct GertieResultScreenAccessibilityIdentifier: ViewModifier {
  let identifier: String?

  @ViewBuilder func body(content: Content) -> some View {
    if let identifier {
      content.accessibilityIdentifier(identifier)
    } else {
      content
    }
  }
}

private struct GertieResultScreenExitModifier: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let isExiting: Bool
  let yOffset: CGFloat
  var delay = 0.0

  func body(content: Content) -> some View {
    content
      .offset(y: self.isExiting ? self.yOffset : 0)
      .opacity(self.isExiting ? 0 : 1)
      .blur(radius: self.isExiting ? 10 : 0)
      .animation(
        self.reduceMotion ? nil : .smooth(duration: 0.3).delay(self.delay),
        value: self.isExiting,
      )
  }
}

#Preview("Error") {
  GertieResultScreen(
    icon: "xmark.circle.fill",
    tone: .error,
    title: "Couldn’t generate a code",
    message: "Please check your internet connection and try again.",
    action: .button("Try again") {},
    secondaryAction: .button("Cancel") {},
  )
}

#Preview("Completion") {
  GertieResultScreen(
    icon: "party.popper",
    title: "Quit the app, you’re done!",
    message: "Gertrude will keep blocking even when the app is not running.",
  )
}

#Preview("Accessibility text") {
  GertieResultScreen(
    icon: "checkmark.circle.fill",
    title: "Successfully connected!",
    message: "This device is now connected and ready to use.",
    action: .button("Continue") {},
  )
  .environment(\.dynamicTypeSize, .accessibility3)
}
