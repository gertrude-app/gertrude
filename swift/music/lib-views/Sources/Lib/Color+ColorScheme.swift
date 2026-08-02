import GertieUI
import SwiftUI

public extension Color {
  static let slate200 = Color(hex: "#e2e8f0")!
  static let slate300 = Color(hex: "#cbd5e1")!
  static let slate400 = Color(hex: "#94a3b8")!
  static let slate700 = Color(hex: "#334155")!
  static let slate800 = Color(hex: "#1e293b")!
  static let slate900 = Color(hex: "#0f172a")!

  internal static func artworkPlaceholder(in colorScheme: ColorScheme) -> Color {
    Color(
      colorScheme,
      light: Color(red: 0.90, green: 0.90, blue: 0.92),
      dark: Color(red: 0.14, green: 0.14, blue: 0.16),
    )
  }

  internal func isDarker(
    than other: Color,
    in environment: EnvironmentValues,
  ) -> Bool {
    self.resolve(in: environment).relativeLuminance
      < other.resolve(in: environment).relativeLuminance
  }
}

struct ArtworkPaletteColors {
  let darker: Color
  let lighter: Color
}

extension ArtworkPalette {
  var backgroundColor: Color? {
    self.bgColor.flatMap(Color.init(hex:))
  }

  func orderedColors(in environment: EnvironmentValues) -> ArtworkPaletteColors? {
    guard let backgroundColor = self.backgroundColor,
          let primaryTextColor = self.textColor1.flatMap(Color.init(hex:))
    else { return nil }

    if backgroundColor.isDarker(than: primaryTextColor, in: environment) {
      return ArtworkPaletteColors(
        darker: backgroundColor,
        lighter: primaryTextColor,
      )
    }

    return ArtworkPaletteColors(
      darker: primaryTextColor,
      lighter: backgroundColor,
    )
  }
}

private extension Color.Resolved {
  var relativeLuminance: Float {
    0.2126 * self.red + 0.7152 * self.green + 0.0722 * self.blue
  }
}
