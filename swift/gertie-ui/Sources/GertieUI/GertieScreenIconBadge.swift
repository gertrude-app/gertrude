import SwiftUI

public struct GertieScreenIconBadge: View {
  @Environment(\.colorScheme) private var colorScheme
  @ScaledMetric(relativeTo: .title) private var iconSize = 32.0

  private let systemName: String

  public init(systemName: String) {
    self.systemName = systemName
  }

  public var body: some View {
    Image(systemName: self.systemName)
      .font(.system(size: self.iconSize, weight: .medium))
      .foregroundStyle(
        Color(
          self.colorScheme,
          light: .violet500,
          dark: .violet400,
        ),
      )
      .accessibilityHidden(true)
      .frame(width: 60, height: 60)
      .background(
        Gradient(colors: [
          Color(
            self.colorScheme,
            light: .violet100,
            dark: .black.opacity(0.3),
          ),
          Color(
            self.colorScheme,
            light: .white.opacity(0.5),
            dark: .white.opacity(0.1),
          ),
        ]),
      )
      .cornerRadius(16)
      .padding(.vertical, 1.5)
      .padding(.horizontal, 1)
      .background(
        Gradient(colors: [
          Color(
            self.colorScheme,
            light: .white,
            dark: .white.opacity(0.2),
          ),
          Color(
            self.colorScheme,
            light: .violet300.opacity(0.6),
            dark: .black.opacity(0.2),
          ),
        ]),
      )
      .cornerRadius(17)
      .frame(maxWidth: .infinity, alignment: .center)
  }
}

#Preview("Light") {
  GertieScreenIconBadge(systemName: "link.circle")
    .padding()
}

#Preview("Dark") {
  GertieScreenIconBadge(systemName: "checkmark.circle.fill")
    .padding()
    .preferredColorScheme(.dark)
}
