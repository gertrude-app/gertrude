import GertieUI
import SwiftUI

struct LibraryRefreshAtmosphere: View {
  @Environment(\.colorScheme) private var colorScheme

  let isActive: Bool

  @State private var isPresented = false
  @State private var isRendered = false

  var body: some View {
    Group {
      if self.isRendered {
        self.glow
          .frame(height: 430)
          .scaleEffect(x: 1.12, y: 0.98, anchor: .top)
          .offset(y: self.isPresented ? -24 : -520)
          .opacity(0.86)
          .blur(radius: 28)
          .mask(self.fade)
          .ignoresSafeArea(edges: .top)
          .allowsHitTesting(false)
          .accessibilityHidden(true)
      }
    }
    .task(id: self.isActive) {
      if self.isActive {
        self.isRendered = true
        self.isPresented = false
        await Task.yield()
        withAnimation(.snappy(duration: 0.68)) {
          self.isPresented = true
        }
      } else if self.isRendered {
        withAnimation(.snappy(duration: 0.52)) {
          self.isPresented = false
        }
        try? await Task.sleep(for: .milliseconds(640))
        if !Task.isCancelled {
          self.isRendered = false
        }
      }
    }
  }

  @ViewBuilder
  private var glow: some View {
    if #available(iOS 18.0, macOS 15.0, *) {
      MeshGradient(
        width: 5,
        height: 4,
        points: self.meshPoints,
        colors: self.meshColors,
        smoothsColors: true,
      )
    } else {
      LinearGradient(
        colors: [
          Color(
            self.colorScheme,
            light: .violet500.opacity(0.64),
            dark: .violet900.opacity(0.76),
          ),
          Color(
            self.colorScheme,
            light: .fuchsia500.opacity(0.34),
            dark: .fuchsia900.opacity(0.46),
          ),
          .clear,
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing,
      )
    }
  }

  private var meshPoints: [SIMD2<Float>] {
    [
      .init(0, 0), .init(0.26, 0), .init(0.50, 0.02), .init(0.74, 0), .init(1, 0),
      .init(0, 0.24), .init(0.24, 0.18), .init(0.50, 0.12), .init(0.76, 0.18), .init(1, 0.24),
      .init(0, 0.52), .init(0.24, 0.43), .init(0.50, 0.37), .init(0.76, 0.43), .init(1, 0.52),
      .init(0, 0.88), .init(0.28, 0.82), .init(0.50, 0.78), .init(0.72, 0.82), .init(1, 0.88),
    ]
  }

  private var meshColors: [Color] {
    [
      Color(self.colorScheme, light: .violet500.opacity(0.80), dark: .violet800.opacity(0.68)),
      Color(self.colorScheme, light: .fuchsia400.opacity(0.58), dark: .fuchsia900.opacity(0.52)),
      Color(self.colorScheme, light: .fuchsia300.opacity(0.66), dark: .fuchsia950.opacity(0.44)),
      Color(self.colorScheme, light: .fuchsia400.opacity(0.58), dark: .fuchsia900.opacity(0.52)),
      Color(self.colorScheme, light: .violet500.opacity(0.80), dark: .violet800.opacity(0.68)),
      Color(self.colorScheme, light: .violet600.opacity(0.54), dark: .violet900.opacity(0.52)),
      Color(self.colorScheme, light: .fuchsia500.opacity(0.42), dark: .fuchsia900.opacity(0.40)),
      Color(self.colorScheme, light: .violet500.opacity(0.42), dark: .violet900.opacity(0.38)),
      Color(self.colorScheme, light: .fuchsia500.opacity(0.42), dark: .fuchsia900.opacity(0.40)),
      Color(self.colorScheme, light: .violet600.opacity(0.54), dark: .violet900.opacity(0.52)),
      Color(self.colorScheme, light: .violet500.opacity(0.16), dark: .violet950.opacity(0.16)),
      Color(self.colorScheme, light: .fuchsia400.opacity(0.14), dark: .fuchsia950.opacity(0.14)),
      Color(self.colorScheme, light: .violet500.opacity(0.18), dark: .violet950.opacity(0.16)),
      Color(self.colorScheme, light: .fuchsia400.opacity(0.14), dark: .fuchsia950.opacity(0.14)),
      Color(self.colorScheme, light: .violet500.opacity(0.16), dark: .violet950.opacity(0.16)),
      .clear,
      .clear,
      .clear,
      .clear,
      .clear,
    ]
  }

  private var fade: some View {
    LinearGradient(
      stops: [
        .init(color: .black, location: 0),
        .init(color: .black.opacity(0.88), location: 0.34),
        .init(color: .black.opacity(0.18), location: 0.72),
        .init(color: .clear, location: 0.94),
      ],
      startPoint: .top,
      endPoint: .bottom,
    )
  }
}
