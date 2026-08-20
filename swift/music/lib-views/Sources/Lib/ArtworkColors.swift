import GertieUI
import SwiftUI

extension Color {
  static func artworkPlaceholder(in colorScheme: ColorScheme) -> Color {
    Color(
      colorScheme,
      light: Color(red: 0.90, green: 0.90, blue: 0.92),
      dark: Color(red: 0.14, green: 0.14, blue: 0.16),
    )
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
