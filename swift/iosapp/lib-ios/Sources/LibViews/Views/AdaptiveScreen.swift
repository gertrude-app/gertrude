import SwiftUI

private let compactHeightThreshold: CGFloat = 700

struct AdaptiveScreen<Content: View>: View {
  @Environment(\.colorScheme) var cs
  @Environment(\.dynamicTypeSize) var dynamicTypeSize
  @State private var didAppear = false

  var backgroundVisible = true
  @ViewBuilder let content: (_ isCompact: Bool) -> Content

  var body: some View {
    GeometryReader { proxy in
      let isCompact = proxy.size.height <= compactHeightThreshold
        || self.dynamicTypeSize.isAccessibilitySize

      ZStack {
        Rectangle()
          .fill(
            Gradient(colors: [
              Color(self.cs, light: .violet200, dark: .violet950.opacity(0.7)),
              .clear,
            ]),
          )
          .ignoresSafeArea()
          .opacity(self.didAppear && self.backgroundVisible ? 1 : 0)
          .onAppear {
            withAnimation(.smooth(duration: 0.7)) {
              self.didAppear = true
            }
          }

        ScrollView {
          self.content(isCompact)
            .frame(maxWidth: .infinity, minHeight: proxy.size.height)
        }
        .scrollBounceBehavior(.basedOnSize)
      }
    }
  }
}
