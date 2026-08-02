import Foundation
import SwiftUI

public struct GertieScreenAction {
  public enum Emphasis {
    case automatic
    case primary
    case secondary
  }

  public enum TriggerBehavior {
    case immediate
    case afterExitAnimation
    case showProgress
  }

  fileprivate enum Target {
    case button(
      behavior: TriggerBehavior,
      action: @MainActor () -> Void,
    )
    case link(destination: URL)
    case share(item: String)
  }

  fileprivate let title: String
  fileprivate let emphasis: Emphasis
  fileprivate let isEnabled: Bool
  fileprivate let target: Target

  private init(
    title: String,
    emphasis: Emphasis,
    isEnabled: Bool,
    target: Target,
  ) {
    self.title = title
    self.emphasis = emphasis
    self.isEnabled = isEnabled
    self.target = target
  }

  public static func button(
    _ title: String,
    emphasis: Emphasis = .automatic,
    isEnabled: Bool = true,
    behavior: TriggerBehavior = .immediate,
    action: @MainActor @escaping () -> Void,
  ) -> Self {
    Self(
      title: title,
      emphasis: emphasis,
      isEnabled: isEnabled,
      target: .button(behavior: behavior, action: action),
    )
  }

  public static func link(
    _ title: String,
    destination: URL,
    emphasis: Emphasis = .automatic,
  ) -> Self {
    Self(
      title: title,
      emphasis: emphasis,
      isEnabled: true,
      target: .link(destination: destination),
    )
  }

  public static func share(
    _ title: String,
    item: String,
    emphasis: Emphasis = .automatic,
  ) -> Self {
    Self(
      title: title,
      emphasis: emphasis,
      isEnabled: true,
      target: .share(item: item),
    )
  }
}

public enum GertieActionScreenIcon {
  case info
  case question
  case error
  case announcement
  case system(String)

  fileprivate var systemName: String {
    switch self {
    case .info:
      "info.circle"
    case .question:
      "questionmark.circle"
    case .error:
      "exclamationmark.circle"
    case .announcement:
      "sparkles"
    case .system(let name):
      name
    }
  }
}

public enum GertieActionScreenMotion {
  case standard
  case none
}

public enum GertieActionScreenSupplementPlacement {
  case beforeMessage
  case afterMessage
}

public struct GertieActionScreen<Supplement: View>: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.colorScheme) private var cs
  @ScaledMetric(relativeTo: .body) private var messageSize = 18.0
  @ScaledMetric(relativeTo: .body) private var bulletSize = 16.0
  @ScaledMetric(relativeTo: .body) private var bulletDotSize = 6.0
  @ScaledMetric(relativeTo: .body) private var bulletDotTopPadding = 7.0
  @ScaledMetric(relativeTo: .body) private var bulletIndent = 14.0

  @State private var showBackground = false
  @State private var response = ActionResponse.idle

  private let message: String
  private let icon: GertieActionScreenIcon
  private let bullets: [String]
  private let actions: [GertieScreenAction]
  private let accessibilityIdentifier: String?
  private let motion: GertieActionScreenMotion
  private let supplementPlacement: GertieActionScreenSupplementPlacement
  private let supplement: Supplement

  public init(
    message: String,
    icon: GertieActionScreenIcon = .info,
    bullets: [String] = [],
    actions: [GertieScreenAction] = [],
    accessibilityIdentifier: String? = nil,
    motion: GertieActionScreenMotion = .standard,
    supplementPlacement: GertieActionScreenSupplementPlacement,
    @ViewBuilder supplement: () -> Supplement,
  ) {
    self.message = message
    self.icon = icon
    self.bullets = bullets
    self.actions = actions
    self.accessibilityIdentifier = accessibilityIdentifier
    self.motion = motion
    self.supplementPlacement = supplementPlacement
    self.supplement = supplement()
  }

  public init(
    message: String,
    icon: GertieActionScreenIcon = .info,
    bullets: [String] = [],
    action: GertieScreenAction,
    accessibilityIdentifier: String? = nil,
    motion: GertieActionScreenMotion = .standard,
    supplementPlacement: GertieActionScreenSupplementPlacement,
    @ViewBuilder supplement: () -> Supplement,
  ) {
    self.init(
      message: message,
      icon: icon,
      bullets: bullets,
      actions: [action],
      accessibilityIdentifier: accessibilityIdentifier,
      motion: motion,
      supplementPlacement: supplementPlacement,
      supplement: supplement,
    )
  }

  public var body: some View {
    ZStack {
      GertieScreenBackground()
        .opacity(self.showBackground ? 1 : 0)
        .ignoresSafeArea()

      GeometryReader { proxy in
        ScrollView {
          VStack(alignment: .leading, spacing: 16) {
            GertieScreenIconBadge(systemName: self.icon.systemName)
              .modifier(
                GertieActionScreenEntranceModifier(
                  motion: self.motion,
                  yOffset: -20,
                ),
              )
              .modifier(
                GertieActionScreenExitModifier(
                  isExiting: self.isExiting,
                  motion: self.motion,
                  yOffset: -20,
                ),
              )

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 16) {
              if self.supplementPlacement == .beforeMessage {
                self.supplement
              }

              Text(verbatim: self.message)
                .font(
                  .system(
                    size: self.messageSize,
                    weight: .medium,
                  ),
                )
                .foregroundStyle(
                  Color(
                    self.cs,
                    light: .violet950,
                    dark: .violet100,
                  ),
                )
                .fixedSize(horizontal: false, vertical: true)
                .modifier(GertieOptionalAccessibilityIdentifier(
                  identifier: self.accessibilityIdentifier,
                ))

              if self.supplementPlacement == .afterMessage {
                self.supplement
              }

              if !self.bullets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                  ForEach(self.bullets.indices, id: \.self) {
                    index in
                    HStack(alignment: .top, spacing: 12) {
                      Image(systemName: "circle.fill")
                        .font(
                          .system(
                            size: self.bulletDotSize,
                          ),
                        )
                        .foregroundStyle(
                          Color(
                            self.cs,
                            light: .violet500,
                            dark: .violet400,
                          ),
                        )
                        .padding(
                          .top,
                          self.bulletDotTopPadding,
                        )
                        .accessibilityHidden(true)

                      Text(verbatim: self.bullets[index])
                        .font(
                          .system(
                            size: self.bulletSize,
                            weight: .medium,
                          ),
                        )
                        .foregroundStyle(
                          Color(
                            self.cs,
                            light: .violet950,
                            dark: .violet100,
                          ),
                        )
                        .fixedSize(
                          horizontal: false,
                          vertical: true,
                        )
                        .opacity(0.8)
                    }
                    .padding(.leading, self.bulletIndent)
                  }
                }
              }
            }
            .modifier(
              GertieActionScreenEntranceModifier(
                motion: self.motion,
                yOffset: 20,
              ),
            )
            .modifier(
              GertieActionScreenExitModifier(
                isExiting: self.isExiting,
                motion: self.motion,
                yOffset: 20,
                delay: self.bodyExitDelay,
              ),
            )

            if !self.actions.isEmpty {
              VStack(spacing: 12) {
                ForEach(self.actions.indices, id: \.self) {
                  index in
                  GertieScreenActionView(
                    action: self.actions[index],
                    isPrimary: self.isPrimaryAction(
                      at: index,
                    ),
                    isResponding: self.isResponding,
                    isShowingProgress: self
                      .progressActionIndex == index,
                  ) {
                    self.actionTriggered(
                      self.actions[index],
                      at: index,
                    )
                  }
                  .accessibilityIdentifier(self.actionAccessibilityIdentifier(at: index))
                  .modifier(
                    GertieActionScreenEntranceModifier(
                      motion: self.motion,
                      yOffset: 20,
                      delay: .seconds(
                        Double(index + 1) * 0.08,
                      ),
                    ),
                  )
                  .modifier(
                    GertieActionScreenExitModifier(
                      isExiting: self.isExiting,
                      motion: self.motion,
                      yOffset: 20,
                      delay: self.actionExitDelay(
                        at: index,
                      ),
                    ),
                  )
                }
              }
              .padding(.top, 12)
            }
          }
          .disabled(self.isResponding)
          .frame(
            minHeight: max(0, proxy.size.height - 60),
            alignment: .top,
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
    .task(id: self.exitTaskID) {
      await self.invokeExitActionIfNeeded()
    }
  }

  private var skipsMotion: Bool {
    self.reduceMotion || self.motion == .none
  }

  private var isResponding: Bool {
    switch self.response {
    case .idle:
      false
    case .exiting, .exitCompleted, .showingProgress:
      true
    }
  }

  private var isExiting: Bool {
    switch self.response {
    case .exiting, .exitCompleted:
      true
    case .idle, .showingProgress:
      false
    }
  }

  private var progressActionIndex: Int? {
    guard case .showingProgress(let index) = self.response else {
      return nil
    }
    return index
  }

  private var bodyExitDelay: Double {
    min(0.18, max(0.06, Double(self.actions.count) * 0.06))
  }

  private var exitTaskID: ExitTaskID {
    guard case .exiting(let id, _) = self.response else {
      return ExitTaskID(id: nil, skipsMotion: self.skipsMotion)
    }
    return ExitTaskID(id: id, skipsMotion: self.skipsMotion)
  }

  private func actionAccessibilityIdentifier(at index: Int) -> String {
    switch index {
    case 0:
      "btn-primary"
    case 1:
      "btn-secondary"
    case 2:
      "onboarding-tertiary-button"
    default:
      "btn-\(index + 1)"
    }
  }

  private func isPrimaryAction(at index: Int) -> Bool {
    switch self.actions[index].emphasis {
    case .automatic:
      index == self.actions.startIndex
    case .primary:
      true
    case .secondary:
      false
    }
  }

  private func actionExitDelay(at index: Int) -> Double {
    guard self.actions.count > 1 else { return 0 }
    let step = min(0.06, 0.18 / Double(self.actions.count - 1))
    return Double(self.actions.count - index - 1) * step
  }

  @MainActor private func beginEntranceAnimations() {
    guard !self.skipsMotion else {
      self.showBackground = true
      return
    }

    withAnimation(.smooth(duration: 0.4)) {
      self.showBackground = true
    }
  }

  @MainActor private func actionTriggered(
    _ action: GertieScreenAction,
    at index: Int,
  ) {
    guard case .idle = self.response else { return }
    guard case .button(let behavior, let callback) = action.target else {
      return
    }
    guard action.isEnabled else { return }

    switch behavior {
    case .immediate:
      callback()
    case .afterExitAnimation:
      self.response = .exiting(id: UUID(), action: callback)
      guard !self.skipsMotion else {
        self.showBackground = false
        return
      }
      withAnimation(.smooth(duration: 0.4).delay(0.05)) {
        self.showBackground = false
      }
    case .showProgress:
      self.response = .showingProgress(index: index)
      callback()
    }
  }

  @MainActor private func invokeExitActionIfNeeded() async {
    guard case .exiting(let id, _) = self.response else { return }

    if !self.skipsMotion {
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
    case showingProgress(index: Int)
  }

  private struct ExitTaskID: Equatable {
    let id: UUID?
    let skipsMotion: Bool
  }
}

public extension GertieActionScreen where Supplement == EmptyView {
  init(
    message: String,
    icon: GertieActionScreenIcon = .info,
    bullets: [String] = [],
    actions: [GertieScreenAction] = [],
    accessibilityIdentifier: String? = nil,
    motion: GertieActionScreenMotion = .standard,
  ) {
    self.init(
      message: message,
      icon: icon,
      bullets: bullets,
      actions: actions,
      accessibilityIdentifier: accessibilityIdentifier,
      motion: motion,
      supplementPlacement: .beforeMessage,
    ) {
      EmptyView()
    }
  }

  init(
    message: String,
    icon: GertieActionScreenIcon = .info,
    bullets: [String] = [],
    action: GertieScreenAction,
    accessibilityIdentifier: String? = nil,
    motion: GertieActionScreenMotion = .standard,
  ) {
    self.init(
      message: message,
      icon: icon,
      bullets: bullets,
      actions: [action],
      accessibilityIdentifier: accessibilityIdentifier,
      motion: motion,
    )
  }
}

private struct GertieOptionalAccessibilityIdentifier: ViewModifier {
  let identifier: String?

  @ViewBuilder func body(content: Content) -> some View {
    if let identifier {
      content.accessibilityIdentifier(identifier)
    } else {
      content
    }
  }
}

private struct GertieScreenActionView: View {
  let action: GertieScreenAction
  let isPrimary: Bool
  let isResponding: Bool
  let isShowingProgress: Bool
  let onTrigger: @MainActor () -> Void

  @ViewBuilder var body: some View {
    if self.isShowingProgress {
      ProgressView {
        Text(verbatim: self.action.title)
      }
      .labelsHidden()
      .frame(maxWidth: .infinity, minHeight: 52)
    } else if self.isPrimary {
      self.control
        .buttonStyle(.gertiePrimary)
        .disabled(self.isResponding)
    } else {
      self.control
        .buttonStyle(.gertieSecondary)
        .disabled(self.isResponding)
    }
  }

  @ViewBuilder private var control: some View {
    switch self.action.target {
    case .button:
      Button(action: self.onTrigger) {
        Text(verbatim: self.action.title)
      }
      .disabled(!self.action.isEnabled)
    case .link(let destination):
      Link(destination: destination) {
        Text(verbatim: self.action.title)
      }
    case .share(let item):
      ShareLink(item: item) {
        Text(verbatim: self.action.title)
      }
    }
  }
}

private struct GertieActionScreenEntranceModifier: ViewModifier {
  let motion: GertieActionScreenMotion
  let yOffset: CGFloat
  var delay = Duration.zero

  @ViewBuilder func body(content: Content) -> some View {
    switch self.motion {
    case .standard:
      content.swooshIn(
        fromYOffset: self.yOffset,
        after: self.delay,
        animation: .bouncy(duration: 0.5, extraBounce: 0.2),
      )
    case .none:
      content
    }
  }
}

private struct GertieActionScreenExitModifier: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let isExiting: Bool
  let motion: GertieActionScreenMotion
  let yOffset: CGFloat
  var delay = 0.0

  func body(content: Content) -> some View {
    content
      .offset(y: self.isExiting ? self.yOffset : 0)
      .opacity(self.isExiting ? 0 : 1)
      .blur(radius: self.isExiting ? 10 : 0)
      .animation(
        self.reduceMotion || self.motion == .none
          ? nil
          : .smooth(duration: 0.3).delay(self.delay),
        value: self.isExiting,
      )
  }
}

#Preview("No action") {
  GertieActionScreen(
    message: "Gertrude must be installed on the device you want to protect.",
  )
}

#Preview("One action") {
  GertieActionScreen(
    message: "The setup usually takes 5–7 minutes.",
    action: .button("Next") {},
  )
}

#Preview("Question") {
  GertieActionScreen(
    message: "How old is the person who will use this device?",
    icon: .question,
    actions: [
      .button("Under 18", emphasis: .secondary) {},
      .button("18 or older") {},
    ],
  )
}

#Preview("Error and link") {
  GertieActionScreen(
    message: "Couldn’t reach Gertrude’s servers.",
    icon: .error,
    actions: [
      .button("Try again", behavior: .afterExitAnimation) {},
      .link(
        "Contact support",
        destination: URL(string: "https://gertrude.app/support")!,
      ),
    ],
  )
  .preferredColorScheme(.dark)
}

#Preview("Bullets and disabled") {
  GertieActionScreen(
    message: "Before continuing, make sure:",
    bullets: [
      "The device is connected to the internet.",
      "You know the device passcode.",
    ],
    actions: [
      .button("Waiting for permission", isEnabled: false) {},
      .button("Go back") {},
      .share("Share setup instructions", item: "https://gertrude.app"),
    ],
  )
  .environment(\.dynamicTypeSize, .accessibility2)
}

#Preview("Progress") {
  GertieActionScreen(
    message: "Gertrude needs permission before setup can continue.",
    action: .button("Allow permission", behavior: .showProgress) {},
  )
}

#Preview("Supplement") {
  GertieActionScreen(
    message: "Follow the steps shown here, then return to Gertrude.",
    action: .button("Got it") {},
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

#Preview("Form supplement") {
  GertieActionScreen(
    message: "Enter a podcast RSS feed URL to add to your library:",
    motion: .none,
    supplementPlacement: .afterMessage,
  ) {
    TextField("Podcast URL", text: .constant(""))
      .textFieldStyle(.roundedBorder)
  }
}
