import SwiftUI

public struct PlayPauseButton: View {
  @Environment(\.colorScheme) var cs

  let text: String
  let isPlaying: Bool
  let onTap: @MainActor @Sendable () -> Void

  public init(
    text: String,
    isPlaying: Bool,
    onTap: @MainActor @Sendable @escaping () -> Void,
  ) {
    self.text = text
    self.isPlaying = isPlaying
    self.onTap = onTap
  }

  public var body: some View {
    Button(action: self.onTap) {
      HStack(spacing: 12) {
        Image(systemName: self.isPlaying ? "pause.fill" : "play.fill")
          .font(.system(size: 20, weight: .semibold))

        Text(self.text)
          .font(.system(size: 18, weight: .semibold))
      }
      .foregroundStyle(.white)
      .frame(width: 240)
      .padding(.vertical, 16)
      .background(Color(self.cs, light: .violet600, dark: .violet500))
      .cornerRadius(12)
    }
  }
}
