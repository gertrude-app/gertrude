import SwiftUI

#if os(iOS)
  import UIKit
#endif

struct MusicDeviceRecognizedView: View {
  @Environment(\.colorScheme) private var colorScheme

  let childName: String
  let onContinueTap: @MainActor @Sendable () -> Void

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 60, weight: .regular))
        .foregroundStyle(Color(self.colorScheme, light: .violet500, dark: .violet400))

      VStack(spacing: 8) {
        Text("Account connected")
          .font(.system(size: 24, weight: .bold))
          .multilineTextAlignment(.center)

        Text(musicDeviceLabel(self.childName))
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(Color(self.colorScheme, light: .violet600, dark: .violet300))
      }
      .multilineTextAlignment(.center)

      Spacer()

      BigButton(
        "Continue",
        type: .button { self.onContinueTap() },
        variant: .primary,
      )
    }
    .frame(maxWidth: 500)
    .padding(30)
    .screenGradientBackground()
  }
}

struct MusicSubscriptionRequiredView: View {
  @Environment(\.colorScheme) private var colorScheme

  let childName: String
  let remediationUrl: URL?
  let overrideText: String?
  let statusDelay: Duration

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Image(systemName: "creditcard")
        .font(.system(size: 40, weight: .regular))
        .foregroundStyle(Color(self.colorScheme, light: .violet500, dark: .violet400))
        .frame(maxWidth: .infinity, alignment: .center)

      Spacer()
      Spacer()

      WaitingStatus(label: "Waiting for the subscription…", delay: self.statusDelay)

      Spacer()

      Text(musicOnboardingBlurb(
        override: self.overrideText,
        device: musicDeviceLabel(self.childName),
        fallback: "This is \(musicDeviceLabel(self.childName)). The Gertrude account needs a subscription before approved music can play. Open this link:",
      ))
      .font(.system(size: 17, weight: .medium))
      .foregroundStyle(Color(
        self.colorScheme,
        light: .black.opacity(0.8),
        dark: .white.opacity(0.8),
      ))
      .fixedSize(horizontal: false, vertical: true)

      Text(self.url)
        .font(.system(size: 20, weight: .semibold, design: .monospaced))
        .minimumScaleFactor(0.7)
        .lineLimit(1)
        .foregroundStyle(Color(self.colorScheme, light: .violet600, dark: .violet300))
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
        .textSelection(.enabled)

      BigButton(
        "Send link",
        type: .share(self.url),
        variant: .primary,
        icon: "square.and.arrow.up",
      )
    }
    .frame(maxWidth: 500)
    .padding(30)
    .padding(.top, 50)
    .screenGradientBackground()
  }

  init(
    childName: String,
    remediationUrl: URL?,
    overrideText: String? = nil,
    statusDelay: Duration = .seconds(45),
  ) {
    self.childName = childName
    self.remediationUrl = remediationUrl
    self.overrideText = overrideText
    self.statusDelay = statusDelay
  }

  private var url: String {
    self.remediationUrl?.absoluteString ?? "https://parents.gertrude.app/settings"
  }
}

func musicDeviceType() -> String {
  #if os(iOS)
    UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
  #else
    "iPhone"
  #endif
}

func musicDeviceLabel(_ childName: String) -> String {
  "\(childName)’s \(musicDeviceType())"
}

func musicOnboardingBlurb(
  override: String?,
  device: String,
  fallback: String,
) -> String {
  guard let override, !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
    return fallback
  }
  let filled = override.replacingOccurrences(of: "{{device}}", with: device)
  guard !filled.contains("{{"), !filled.contains("}}") else { return fallback }
  return filled
}

#Preview("Device Recognized") {
  MusicDeviceRecognizedView(childName: "Billy Bob") {}
}

#Preview("Device Recognized Dark") {
  MusicDeviceRecognizedView(childName: "Billy Bob") {}
    .preferredColorScheme(.dark)
}

#Preview("Subscription Required") {
  MusicSubscriptionRequiredView(
    childName: "Billy Bob",
    remediationUrl: URL(string: "https://parents.gertrude.app/settings"),
    overrideText: "{{device}} needs a subscription — Gertrude Music is $5 a month and covers your whole family. Open this link:",
    statusDelay: .seconds(2),
  )
}

#Preview("Subscription Required Dark") {
  MusicSubscriptionRequiredView(
    childName: "Billy Bob",
    remediationUrl: URL(string: "https://parents.gertrude.app/settings"),
    statusDelay: .seconds(2),
  )
  .preferredColorScheme(.dark)
}
