import GertieUI
import SwiftUI

#if os(iOS)
  import UIKit
#endif

struct MusicDeviceRecognizedView: View {
  let childName: String
  let onContinueTap: @MainActor @Sendable () -> Void

  var body: some View {
    GertieResultScreen(
      icon: "checkmark.circle.fill",
      title: "Account connected",
      message: musicDeviceLabel(self.childName),
      action: .button("Continue") {
        self.onContinueTap()
      },
    )
  }
}

struct MusicUnavailableView: View {
  @Environment(\.colorScheme) private var colorScheme

  let childName: String
  let statusDelay: Duration

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "music.note")
        .font(.system(size: 60, weight: .regular))
        .foregroundStyle(Color(self.colorScheme, light: .violet500, dark: .violet400))
        .accessibilityHidden(true)

      VStack(spacing: 12) {
        Text("Music unavailable")
          .font(.system(size: 24, weight: .bold))

        Text(
          "This is \(musicDeviceLabel(self.childName)). It’s connected, but Gertrude Music isn’t available for this account.",
        )
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(Color(
          self.colorScheme,
          light: .black.opacity(0.8),
          dark: .white.opacity(0.8),
        ))
        .fixedSize(horizontal: false, vertical: true)
      }
      .multilineTextAlignment(.center)

      Spacer()

      GertieWaitingStatus(label: "Still checking availability…", delay: self.statusDelay)
    }
    .frame(maxWidth: 500)
    .padding(30)
    .gertieScreenBackground()
  }

  init(childName: String, statusDelay: Duration = .seconds(45)) {
    self.childName = childName
    self.statusDelay = statusDelay
  }
}

@MainActor
func musicDeviceType() -> String {
  #if os(iOS)
    UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
  #else
    "iPhone"
  #endif
}

@MainActor
func musicDeviceLabel(_ childName: String) -> String {
  "\(childName)’s \(musicDeviceType())"
}

#Preview("Device Recognized") {
  MusicDeviceRecognizedView(childName: "Billy Bob") {}
}

#Preview("Device Recognized Dark") {
  MusicDeviceRecognizedView(childName: "Billy Bob") {}
    .preferredColorScheme(.dark)
}

#Preview("Music Unavailable") {
  MusicUnavailableView(childName: "Billy Bob", statusDelay: .seconds(2))
}
