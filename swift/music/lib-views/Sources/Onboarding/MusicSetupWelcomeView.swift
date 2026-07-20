import SwiftUI

#if os(iOS)
  import UIKit
#endif

struct MusicSetupWelcomeView: View {
  @Environment(\.colorScheme) private var colorScheme

  let onPrimaryButtonTap: @MainActor @Sendable () -> Void

  @State private var showBackground = false
  @State private var greeting = ""
  @State private var lettersOffset: [Vector] = []
  @State private var subtitleOffset = Vector(x: 0, y: 40)
  @State private var buttonOffset = Vector(x: 0, y: 40)

  private static let greetingText = "Hi there!"

  var body: some View {
    ZStack {
      MusicSetupWelcomeBackground()
        .opacity(self.showBackground ? 1 : 0)
        .ignoresSafeArea()

      VStack(alignment: self.isPad ? .center : .leading, spacing: 12) {
        if !self.isPad {
          Spacer()
        }

        HStack(spacing: 0) {
          ForEach(Array(self.greeting.enumerated()), id: \.offset) { index, char in
            Text(String(char))
              .font(.system(size: 50, weight: .black))
              .foregroundStyle(Color(self.colorScheme, light: .violet950, dark: .violet100))
              .swooshIn(
                tracking: self.$lettersOffset[index],
                to: .zero,
                after: .seconds(Double(index) / 15.0 + 0.5),
                for: .milliseconds(600),
              )
          }
        }

        Text(
          "Gertrude Music lets parents or accountability partners give access to only selected, approved music.",
        )
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(Color(self.colorScheme, light: .violet950, dark: .violet100))
        .multilineTextAlignment(self.isPad ? .center : .leading)
        .fixedSize(horizontal: false, vertical: true)
        .swooshIn(
          tracking: self.$subtitleOffset,
          to: .zero,
          after: .seconds(1.0),
          for: .milliseconds(800),
          via: .smooth,
        )

        BigButton("Get started", type: .button {
          self.vanishingAnimations()
          delayed(by: .milliseconds(800)) {
            self.onPrimaryButtonTap()
          }
        }, variant: .primary)
          .padding(.top, 20)
          .swooshIn(
            tracking: self.$buttonOffset,
            to: .zero,
            after: .seconds(1.3),
            for: .milliseconds(800),
            via: .smooth,
          )
      }
      .padding(30)
      .frame(maxWidth: 500)
    }
    .onAppear {
      self.greeting = Self.greetingText
      self.lettersOffset = Array(repeating: Vector(x: 0, y: 40), count: self.greeting.count)
      withAnimation(.smooth(duration: 1.2)) {
        self.showBackground = true
      }
    }
  }

  @MainActor private func vanishingAnimations() {
    withAnimation(.smooth(duration: 1)) {
      self.showBackground = false
    }
    for index in self.lettersOffset.indices {
      withAnimation(.smooth(duration: 0.5)) {
        self.lettersOffset[index].y = 50
      }
    }
    withAnimation(.smooth(duration: 0.5)) {
      self.subtitleOffset.y = 50
      self.buttonOffset.y = 50
    }
  }

  private var isPad: Bool {
    #if os(iOS)
      UIDevice.current.userInterfaceIdiom == .pad
    #else
      false
    #endif
  }
}

struct MusicSetupSplashView: View {
  var body: some View {
    ZStack {
      Image("MusicSplashGradient", bundle: Bundle.module)
        .resizable()
      Image("MusicSplashNote", bundle: Bundle.module)
        .resizable()
        .scaledToFit()
        .frame(width: 144, height: 144)
    }
    .ignoresSafeArea()
  }
}

private struct MusicSetupWelcomeBackground: View {
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

#Preview("Welcome") {
  MusicSetupWelcomeView {}
}

#Preview("Welcome Dark") {
  MusicSetupWelcomeView {}
    .preferredColorScheme(.dark)
}
