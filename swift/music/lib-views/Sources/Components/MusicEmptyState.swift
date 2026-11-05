import GertieUI
import SwiftUI

public struct MusicEmptyState: View {
  private let title: String
  private let message: String?
  private let buttonTitle: String?
  private let onButtonTap: @MainActor () -> Void

  public init(
    _ title: String,
    message: String? = nil,
    buttonTitle: String? = nil,
    onButtonTap: @escaping @MainActor () -> Void = {},
  ) {
    self.title = title
    self.message = message
    self.buttonTitle = buttonTitle
    self.onButtonTap = onButtonTap
  }

  public var body: some View {
    VStack(spacing: 20) {
      VStack(spacing: 8) {
        Text(self.title)
          .font(.system(.title2, design: .rounded, weight: .bold))
          .accessibilityAddTraits(.isHeader)

        if let message {
          Text(message)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
        }
      }
      .multilineTextAlignment(.center)
      .fixedSize(horizontal: false, vertical: true)

      if let buttonTitle {
        Button(buttonTitle, action: self.onButtonTap)
          .buttonStyle(.gertiePrimary)
          .frame(maxWidth: 280)
          .padding(.top, 4)
      }
    }
    .frame(maxWidth: 360)
    .padding(.horizontal, 32)
    .frame(maxWidth: .infinity)
  }
}

#if DEBUG
  #Preview("With button") {
    MusicEmptyState(
      "Your queue is empty",
      message: "Choose an approved album, artist, or song to start listening.",
      buttonTitle: "Browse Library",
    )
  }

  #Preview("Without button") {
    MusicEmptyState(
      "Choose some music",
      message: "Select an album, artist, or playlist from your library.",
    )
  }
#endif
