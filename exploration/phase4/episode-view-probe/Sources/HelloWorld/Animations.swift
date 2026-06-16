import SwiftUI

public extension Animation {
  static let nowPlayingSpring = Animation.spring(response: 0.3, dampingFraction: 0.8)
  static let backgroundFadeSmooth = Animation.smooth(duration: 0.7)
  static let backgroundFadeSmoothLong = Animation.smooth(duration: 1.0)
  static let downloadRotation = Animation.linear(duration: 1)
    .repeatForever(autoreverses: false)
}

struct RotatingDownloadIcon: ViewModifier {
  @State var rotationAngle: Double = 0

  func body(content: Content) -> some View {
    content
      .rotationEffect(.degrees(self.rotationAngle))
      .onAppear {
        withAnimation(.downloadRotation) {
          self.rotationAngle = 360
        }
      }
  }
}

extension View {
  func rotatingDownloadIcon() -> some View {
    modifier(RotatingDownloadIcon())
  }
}
