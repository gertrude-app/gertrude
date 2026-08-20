import GertieUI
import SwiftUI

struct FreeAlternativesHubView: View {
  @Environment(\.colorScheme) var cs
  @ScaledMetric(relativeTo: .subheadline) private var orTextSize = 14.0

  let onBirthdayTapped: () -> Void
  let onSiblingTapped: () -> Void
  let onAppleConfiguratorTapped: () -> Void
  let onGertrudeTapped: () -> Void

  var body: some View {
    GertieActionScreen(
      message: "There are three free alternatives:",
      icon: .system("arrow.triangle.branch"),
      action: .button("Go with Gertrude ($10/year)") {
        self.onGertrudeTapped()
      },
      supplementPlacement: .afterMessage,
    ) {
      VStack(alignment: .leading, spacing: 16) {
        AlternativeCard(
          icon: "birthday.cake",
          title: "Change your birthday",
          onTap: self.onBirthdayTapped,
        )

        AlternativeCard(
          icon: "person.2",
          title: "Use a sibling’s account",
          onTap: self.onSiblingTapped,
        )

        AlternativeCard(
          icon: "desktopcomputer",
          title: "Supervise yourself",
          onTap: self.onAppleConfiguratorTapped,
        )

        Text("or")
          .font(.system(size: self.orTextSize, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.top, 8)
      }
      .frame(maxWidth: .infinity)
    }
  }
}

struct AlternativeCard: View {
  @Environment(\.colorScheme) var cs
  @ScaledMetric(relativeTo: .title3) private var iconSize = 22.0
  @ScaledMetric(relativeTo: .title3) private var iconWidth = 36.0
  @ScaledMetric(relativeTo: .body) private var titleSize = 16.0
  @ScaledMetric(relativeTo: .caption) private var chevronSize = 12.0

  let icon: String
  let title: String
  let onTap: () -> Void

  var body: some View {
    Button {
      self.onTap()
    } label: {
      HStack(spacing: 14) {
        Image(systemName: self.icon)
          .font(.system(size: self.iconSize, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
          .frame(width: self.iconWidth)

        Text(self.title)
          .font(.system(size: self.titleSize, weight: .semibold))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: self.chevronSize, weight: .semibold))
          .foregroundStyle(Color(self.cs, light: .violet400, dark: .violet500))
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .background(
        Color(self.cs, light: .violet500.opacity(0.1), dark: .violet500.opacity(0.15)),
      )
      .clipShape(.rect(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(.plain)
  }
}

struct InstructionsForProtectorView: View {
  @Environment(\.colorScheme) var cs

  let code: Int
  let onNext: () -> Void

  var codeString: String {
    String(format: "%06d", self.code)
  }

  var supervisionUrl: String {
    "https://gertrude.app/s/\(self.codeString)"
  }

  var body: some View {
    GertieActionScreen(
      message: "The parent/spouse/accountability partner will need to open this link on their computer (Mac or Windows) to setup the account and perform the supervision.",
      icon: .system("link.circle"),
      actions: [
        .share("Send link", item: self.supervisionUrl, emphasis: .secondary),
        .button("Next", emphasis: .primary) {
          self.onNext()
        },
      ],
      supplementPlacement: .afterMessage,
    ) {
      Text(self.supervisionUrl)
        .font(.system(size: 20, weight: .semibold, design: .monospaced))
        .minimumScaleFactor(0.7)
        .lineLimit(1)
        .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet300))
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
    }
  }
}

struct WaitingForSupervisionView: View {
  let code: Int

  var codeString: String {
    String(format: "%06d", self.code)
  }

  var supervisionUrl: String {
    "https://gertrude.app/s/\(self.codeString)"
  }

  var body: some View {
    GertieActionScreen(
      message: "Now close this app and have the helper create the account from that link.\n\nAfter the account is created, they’ll be walked through the supervision process.",
      icon: .system("hourglass"),
      action: .share(
        "Send link again",
        item: self.supervisionUrl,
        emphasis: .secondary,
      ),
    )
  }
}

#Preview("FreeAlternativesHub") {
  FreeAlternativesHubView(
    onBirthdayTapped: {},
    onSiblingTapped: {},
    onAppleConfiguratorTapped: {},
    onGertrudeTapped: {},
  )
}

#Preview("InstructionsForProtector") {
  InstructionsForProtectorView(code: 123_456, onNext: {})
}

#Preview("WaitingForSupervision") {
  WaitingForSupervisionView(code: 123_456)
}
