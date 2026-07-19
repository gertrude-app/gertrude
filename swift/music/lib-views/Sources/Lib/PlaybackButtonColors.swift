import SwiftUI

struct PlaybackButtonColors {
  let background: Color
  let foreground: Color

  init(background: Color, foreground: Color) {
    self.background = background
    self.foreground = foreground
  }

  init(
    palette: ArtworkPalette?,
    environment: EnvironmentValues,
  ) {
    guard let paletteColors = palette?.orderedColors(in: environment) else {
      if environment.colorScheme == .dark {
        self.background = .white
        self.foreground = .black
      } else {
        self.background = .black
        self.foreground = .white
      }
      return
    }

    if environment.colorScheme == .dark {
      self.background = paletteColors.lighter
      self.foreground = paletteColors.darker
    } else {
      self.background = paletteColors.darker
      self.foreground = paletteColors.lighter
    }
  }
}
