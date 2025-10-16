import SwiftUI

public struct PulsingDot: View {
  @State private var isAnimating = false

  public init() {}

  public var body: some View {
    Circle()
      .fill(Color(red: 0.8, green: 0.0, blue: 0.0))
      .frame(width: 9, height: 9)
      .opacity(self.isAnimating ? 0.3 : 1.0)
      .animation(
        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
        value: self.isAnimating
      )
      .allowsHitTesting(false)
      .onAppear {
        self.isAnimating = true
      }
  }
}
