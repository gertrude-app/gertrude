import SwiftUI

public extension View {
  func swooshIn(
    fromYOffset yOffset: CGFloat,
    after delay: Duration = .zero,
    animation: Animation = .bouncy(duration: 0.8, extraBounce: 0.3),
  ) -> some View {
    self.modifier(SwooshInModifier(
      yOffset: yOffset,
      delay: delay,
      animation: animation,
    ))
  }
}

private struct SwooshInModifier: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isVisible = false

  let yOffset: CGFloat
  let delay: Duration
  let animation: Animation

  func body(content: Content) -> some View {
    content
      .offset(y: self.isVisible ? 0 : self.yOffset)
      .opacity(self.isVisible ? 1 : 0)
      .blur(radius: self.isVisible ? 0 : 10)
      .allowsHitTesting(self.isVisible)
      .task(id: self.reduceMotion) {
        guard !self.isVisible else { return }

        guard !self.reduceMotion else {
          self.isVisible = true
          return
        }

        do {
          try await Task.sleep(for: self.delay)
        } catch {
          return
        }

        guard !Task.isCancelled else { return }
        withAnimation(self.animation) {
          self.isVisible = true
        }
      }
  }
}
