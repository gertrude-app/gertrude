import SwiftUI

public enum NoticeBannerTone: Equatable, Sendable {
  case error
  case information
  case success
  case warning

  fileprivate var defaultSystemImage: String {
    switch self {
    case .error:
      "exclamationmark"
    case .information:
      "info"
    case .success:
      "checkmark"
    case .warning:
      "exclamationmark"
    }
  }

  fileprivate func color(in colorScheme: ColorScheme) -> Color {
    switch self {
    case .error:
      Color(
        colorScheme,
        light: Color(red: 1.00, green: 0.44, blue: 0.51),
        dark: Color(red: 0.92, green: 0.30, blue: 0.39),
      )
    case .information:
      Color(colorScheme, light: .violet400, dark: .violet500)
    case .success:
      Color(
        colorScheme,
        light: Color(red: 0.33, green: 0.84, blue: 0.64),
        dark: Color(red: 0.16, green: 0.59, blue: 0.44),
      )
    case .warning:
      Color(
        colorScheme,
        light: Color(red: 1.00, green: 0.73, blue: 0.34),
        dark: Color(red: 0.79, green: 0.49, blue: 0.10),
      )
    }
  }
}

public struct NoticeBanner: View {
  @Environment(\.colorScheme) private var cs

  private let actionTitle: String?
  private let message: String
  private let onActionTap: @MainActor @Sendable () -> Void
  private let onDismissTap: (@MainActor @Sendable () -> Void)?
  private let systemImage: String?
  private let title: String
  private let tone: NoticeBannerTone

  @State private var dismissalDragOffset: CGFloat = 0
  @State private var isDismissalDragVertical: Bool?

  public init(
    tone: NoticeBannerTone,
    title: String,
    message: String,
    systemImage: String? = nil,
    actionTitle: String? = nil,
    onActionTap: @MainActor @escaping @Sendable () -> Void = {},
    onDismissTap: (@MainActor @Sendable () -> Void)? = nil,
  ) {
    self.tone = tone
    self.title = title
    self.message = message
    self.systemImage = systemImage
    self.actionTitle = actionTitle
    self.onActionTap = onActionTap
    self.onDismissTap = onDismissTap
  }

  public var body: some View {
    self.bannerContent
      .contentShape(.rect)
      .offset(y: self.dismissalDragOffset)
      .opacity(1 - min(self.dismissalDragOffset / 240, 0.35))
      .gesture(
        self.dismissGesture,
        including: self.onDismissTap == nil ? .none : .gesture,
      )
      .accessibilityIdentifier("notice-banner")
      .task(id: self.announcement) {
        AccessibilityNotification.Announcement(self.announcement).post()
      }
  }

  @ViewBuilder
  private var bannerContent: some View {
    if #available(iOS 26.0, macOS 26.0, *) {
      self.bannerLayout
        .padding(12)
        .glassEffect(
          .regular.tint(self.glassTint).interactive(),
          in: RoundedRectangle(cornerRadius: 20, style: .continuous),
        )
    } else {
      self.bannerLayout
        .padding(12)
        .background(
          .regularMaterial,
          in: RoundedRectangle(cornerRadius: 20, style: .continuous),
        )
    }
  }

  private var bannerLayout: some View {
    HStack(alignment: .top, spacing: 12) {
      self.statusIcon

      VStack(alignment: .leading, spacing: 9) {
        VStack(alignment: .leading, spacing: 3) {
          Text(self.title)
            .font(
              .system(
                .subheadline,
                design: .rounded,
                weight: .bold,
              ),
            )
            .foregroundStyle(.primary)

          Text(self.message)
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)

        self.actionButton
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      self.dismissButton
    }
  }

  private var statusIcon: some View {
    Image(systemName: self.systemImage ?? self.tone.defaultSystemImage)
      .font(.system(size: 15, weight: .black))
      .symbolRenderingMode(.monochrome)
      .foregroundStyle(self.tint)
      .frame(width: 20)
      .accessibilityHidden(true)
  }

  @ViewBuilder
  private var actionButton: some View {
    if let actionTitle {
      Button(actionTitle, action: self.onActionTap)
        .font(.system(.footnote, design: .rounded, weight: .medium))
        .controlSize(.small)
        .foregroundStyle(self.tint)
        .padding(.vertical, 4)
    }
  }

  @ViewBuilder
  private var dismissButton: some View {
    if let onDismissTap {
      Button(action: onDismissTap) {
        Image(systemName: "xmark")
          .font(.system(size: 11, weight: .bold))
          .foregroundStyle(.secondary.opacity(0.55))
          .frame(width: 20, height: 20)
          .contentShape(.rect)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Dismiss \(self.title)")
    }
  }

  private var dismissGesture: some Gesture {
    DragGesture(minimumDistance: 8)
      .onChanged { value in
        guard self.onDismissTap != nil else { return }

        if self.isDismissalDragVertical == nil {
          self.isDismissalDragVertical = abs(value.translation.height)
            > abs(value.translation.width)
        }

        guard self.isDismissalDragVertical == true else { return }
        self.dismissalDragOffset = max(0, value.translation.height)
      }
      .onEnded { value in
        guard let onDismissTap = self.onDismissTap else { return }
        let projectedDistance = max(
          value.translation.height,
          value.predictedEndTranslation.height,
        )
        let shouldDismiss = self.isDismissalDragVertical == true
          && projectedDistance > 56

        self.isDismissalDragVertical = nil

        if shouldDismiss {
          withAnimation(.easeOut(duration: 0.18)) {
            onDismissTap()
          }
        } else {
          withAnimation(.spring(duration: 0.26, bounce: 0.18)) {
            self.dismissalDragOffset = 0
          }
        }
      }
  }

  private var glassTint: Color {
    Color(
      self.cs,
      light: .white.opacity(0.72),
      dark: .black.opacity(0.72),
    )
  }

  private var tint: Color {
    self.tone.color(in: self.cs)
  }

  private var announcement: String {
    "\(self.title). \(self.message)"
  }
}

#if DEBUG
  #Preview("Notices") {
    @Previewable @Environment(\.colorScheme) var cs

    ScrollView {
      VStack(spacing: 18) {
        NoticeBanner(
          tone: .error,
          title: "Couldn’t add music",
          message:
          "Your selection is still here. Try adding it again.",
          onDismissTap: {},
        )

        NoticeBanner(
          tone: .warning,
          title: "Can’t refresh library",
          message:
          "Gertrude Music is showing saved music. It may be out of date.",
          systemImage: "wifi.exclamationmark",
          actionTitle: "Try Again",
          onDismissTap: {},
        )

        NoticeBanner(
          tone: .success,
          title: "Playlist updated",
          message: "The selected songs were added to Road Trip.",
          onDismissTap: {},
        )

        NoticeBanner(
          tone: .information,
          title: "Playlist changed",
          message:
          "The latest version from another device is now shown.",
          onDismissTap: {},
        )
      }
      .padding(18)
    }
    .background(
      Color(
        cs,
        light: Color(hex: "#eeeeee")!,
        dark: Color(hex: "#161616")!,
      ),
    )
  }

  #Preview("Accessibility text") {
    NoticeBanner(
      tone: .warning,
      title: "Can’t refresh library",
      message:
      "Gertrude Music is showing saved music. It may be out of date.",
      systemImage: "wifi.exclamationmark",
      actionTitle: "Try Again",
      onDismissTap: {},
    )
    .padding(18)
    .environment(\.dynamicTypeSize, .accessibility3)
  }
#endif
