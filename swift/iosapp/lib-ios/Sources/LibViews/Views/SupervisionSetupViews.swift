import SwiftUI

struct FreeAlternativesHubView: View {
  @Environment(\.colorScheme) var cs

  let onBirthdayTapped: () -> Void
  let onSiblingTapped: () -> Void
  let onAppleConfiguratorTapped: () -> Void
  let onGertrudeTapped: () -> Void

  @State private var showBg = false
  @State private var iconOffset = Vector(x: 0, y: -20)
  @State private var textOffset = Vector(x: 0, y: 20)
  @State private var card1Offset = Vector(x: 0, y: 20)
  @State private var card2Offset = Vector(x: 0, y: 20)
  @State private var card3Offset = Vector(x: 0, y: 20)
  @State private var orTextOffset = Vector(x: 0, y: 20)
  @State private var buttonOffset = Vector(x: 0, y: 20)

  var body: some View {
    ZStack {
      Rectangle()
        .fill(
          Gradient(colors: [
            Color(self.cs, light: .violet200, dark: .violet950.opacity(0.7)),
            .clear,
          ]),
        )
        .ignoresSafeArea()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation(.smooth(duration: 0.7)) {
            self.showBg = true
          }
        }

      VStack(alignment: .leading, spacing: 16) {
        Image(systemName: "arrow.triangle.branch")
          .font(.system(size: 40, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
          .swooshIn(tracking: self.$iconOffset, to: .zero, after: .zero, for: .milliseconds(800))
          .frame(maxWidth: .infinity, alignment: .center)

        Spacer()

        Text("There are three free alternatives:")
          .font(.system(size: 18, weight: .medium))
          .swooshIn(tracking: self.$textOffset, to: .zero, after: .zero, for: .milliseconds(800))

        AlternativeCard(
          icon: "birthday.cake",
          title: "Change your birthday",
          onTap: self.onBirthdayTapped,
        )
        .swooshIn(
          tracking: self.$card1Offset,
          to: .zero,
          after: .milliseconds(100),
          for: .milliseconds(800),
        )

        AlternativeCard(
          icon: "person.2",
          title: "Use a sibling’s account",
          onTap: self.onSiblingTapped,
        )
        .swooshIn(
          tracking: self.$card2Offset,
          to: .zero,
          after: .milliseconds(200),
          for: .milliseconds(800),
        )

        AlternativeCard(
          icon: "desktopcomputer",
          title: "Supervise yourself",
          onTap: self.onAppleConfiguratorTapped,
        )
        .swooshIn(
          tracking: self.$card3Offset,
          to: .zero,
          after: .milliseconds(300),
          for: .milliseconds(800),
        )

        Text("or")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet400))
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.top, 8)
          .swooshIn(
            tracking: self.$orTextOffset,
            to: .zero,
            after: .milliseconds(350),
            for: .milliseconds(800),
          )

        BigButton(
          "Go with Gertrude ($10/year)",
          type: .button { self.onGertrudeTapped() },
          variant: .primary,
        )
        .swooshIn(
          tracking: self.$buttonOffset,
          to: .zero,
          after: .milliseconds(400),
          for: .milliseconds(800),
        )
      }
      .frame(maxWidth: 500)
      .padding(30)
      .padding(.top, 50)
    }
  }
}

struct AlternativeCard: View {
  @Environment(\.colorScheme) var cs

  let icon: String
  let title: String
  let onTap: () -> Void

  var body: some View {
    Button {
      self.onTap()
    } label: {
      HStack(spacing: 14) {
        Image(systemName: self.icon)
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
          .frame(width: 36)

        Text(self.title)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(Color(self.cs, light: .violet400, dark: .violet500))
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .background(
        Color(self.cs, light: .violet500.opacity(0.1), dark: .violet500.opacity(0.15)),
      )
      .cornerRadius(16)
    }
    .buttonStyle(.plain)
  }
}

struct InstructionsForProtectorView: View {
  @Environment(\.colorScheme) var cs

  let code: Int
  let onNext: () -> Void

  @State private var showBg = false

  var codeString: String {
    String(format: "%06d", self.code)
  }

  var supervisionUrl: String {
    "https://gertrude.app/s/\(self.codeString)"
  }

  var body: some View {
    ZStack {
      Rectangle()
        .fill(
          Gradient(colors: [
            Color(self.cs, light: .violet200, dark: .violet950.opacity(0.7)),
            .clear,
          ]),
        )
        .ignoresSafeArea()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation(.smooth(duration: 0.7)) {
            self.showBg = true
          }
        }

      VStack(alignment: .leading, spacing: 16) {
        Image(systemName: "link.circle")
          .font(.system(size: 40, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
          .frame(maxWidth: .infinity, alignment: .center)

        Spacer()

        Text(
          "The parent/spouse/accountability partner will need to open this link on their computer (Mac or Windows) to setup the account and perform the supervision.",
        )
        .font(.system(size: 18, weight: .medium))

        Text(self.supervisionUrl)
          .font(.system(size: 20, weight: .semibold, design: .monospaced))
          .minimumScaleFactor(0.7)
          .lineLimit(1)
          .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet300))
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 8)

        Spacer()
          .frame(height: 40)

        BigButton(
          "Send link",
          type: .share(self.supervisionUrl),
          variant: .secondary,
          icon: "square.and.arrow.up",
        )

        BigButton("Next", type: .button { self.onNext() }, variant: .primary)
          .padding(.top, 8)
      }
      .frame(maxWidth: 500)
      .padding(30)
      .padding(.top, 50)
    }
  }
}

struct WaitingForSupervisionView: View {
  @Environment(\.colorScheme) var cs

  let code: Int

  @State private var showBg = false

  var codeString: String {
    String(format: "%06d", self.code)
  }

  var supervisionUrl: String {
    "https://gertrude.app/s/\(self.codeString)"
  }

  var body: some View {
    ZStack {
      Rectangle()
        .fill(
          Gradient(colors: [
            Color(self.cs, light: .violet200, dark: .violet950.opacity(0.7)),
            .clear,
          ]),
        )
        .ignoresSafeArea()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation(.smooth(duration: 0.7)) {
            self.showBg = true
          }
        }

      VStack(alignment: .leading, spacing: 16) {
        Image(systemName: "hourglass")
          .font(.system(size: 40, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
          .frame(maxWidth: .infinity, alignment: .center)

        Spacer()

        Text("Now close this app and have the helper create the account from that link.")
          .font(.system(size: 18, weight: .medium))

        Text("After the account is created, they’ll be walked through the supervision process.")
          .font(.system(size: 18, weight: .medium))

        Spacer()
          .frame(height: 40)

        BigButton(
          "Send link again",
          type: .share(self.supervisionUrl),
          variant: .secondary,
          icon: "square.and.arrow.up",
        )
      }
      .frame(maxWidth: 500)
      .padding(30)
      .padding(.top, 50)
    }
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
