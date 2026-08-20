import SwiftUI

struct GertieWelcomeBackground: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    ZStack(alignment: .top) {
      Color(self.colorScheme, light: .white, dark: .black)

      if #available(iOS 18.0, macOS 15.0, *) {
        MeshGradient(
          width: 5,
          height: 4,
          points: [
            .init(0, 0), .init(0.24, 0), .init(0.5, 0), .init(0.76, 0), .init(1, 0),
            .init(0, 0.22), .init(0.22, 0.16), .init(0.5, 0.11), .init(0.78, 0.16), .init(1, 0.22),
            .init(0, 0.50), .init(0.26, 0.42), .init(0.5, 0.36), .init(0.74, 0.42), .init(1, 0.50),
            .init(0, 0.86), .init(0.25, 0.80), .init(0.5, 0.76), .init(0.75, 0.80), .init(1, 0.86),
          ],
          colors: self.meshColors,
          smoothsColors: true,
        )
        .frame(height: 480)
        .mask(self.topFade)
        .ignoresSafeArea(edges: .top)
      } else {
        LinearGradient(
          colors: [
            Color(
              self.colorScheme,
              light: .violet200.opacity(0.78),
              dark: .violet950.opacity(0.68),
            ),
            Color(
              self.colorScheme,
              light: .fuchsia200.opacity(0.34),
              dark: .fuchsia950.opacity(0.28),
            ),
            .clear,
          ],
          startPoint: .top,
          endPoint: .bottom,
        )
        .frame(height: 480)
        .mask(self.topFade)
        .ignoresSafeArea(edges: .top)
      }
    }
  }

  private var meshColors: [Color] {
    [
      Color(self.colorScheme, light: .violet300.opacity(0.86), dark: .violet800.opacity(0.62)),
      Color(self.colorScheme, light: .fuchsia200.opacity(0.56), dark: .fuchsia900.opacity(0.40)),
      Color(self.colorScheme, light: .fuchsia100.opacity(0.74), dark: .fuchsia950.opacity(0.34)),
      Color(self.colorScheme, light: .fuchsia200.opacity(0.56), dark: .fuchsia900.opacity(0.40)),
      Color(self.colorScheme, light: .violet300.opacity(0.86), dark: .violet800.opacity(0.62)),
      Color(self.colorScheme, light: .violet400.opacity(0.76), dark: .violet800.opacity(0.56)),
      Color(self.colorScheme, light: .fuchsia300.opacity(0.50), dark: .fuchsia800.opacity(0.36)),
      Color(self.colorScheme, light: .violet200.opacity(0.34), dark: .violet950.opacity(0.18)),
      Color(self.colorScheme, light: .fuchsia300.opacity(0.50), dark: .fuchsia800.opacity(0.36)),
      Color(self.colorScheme, light: .violet400.opacity(0.76), dark: .violet800.opacity(0.56)),
      Color(self.colorScheme, light: .violet200.opacity(0.54), dark: .violet900.opacity(0.40)),
      Color(self.colorScheme, light: .fuchsia100.opacity(0.24), dark: .fuchsia950.opacity(0.22)),
      Color(self.colorScheme, light: .violet100.opacity(0.08), dark: .violet950.opacity(0.08)),
      Color(self.colorScheme, light: .fuchsia100.opacity(0.24), dark: .fuchsia950.opacity(0.22)),
      Color(self.colorScheme, light: .violet200.opacity(0.54), dark: .violet900.opacity(0.40)),
      .clear,
      .clear,
      .clear,
      .clear,
      .clear,
    ]
  }

  private var topFade: some View {
    LinearGradient(
      stops: [
        .init(color: .black, location: 0),
        .init(color: .black.opacity(0.92), location: 0.56),
        .init(color: .clear, location: 1),
      ],
      startPoint: .top,
      endPoint: .bottom,
    )
  }
}
