import SwiftUI

#if os(iOS)
  import UIKit
#endif

public extension View {
  @ViewBuilder
  func coversTabLayoutUntilSettled() -> some View {
    #if os(iOS)
      if UIDevice.current.userInterfaceIdiom == .pad {
        self.modifier(TabLayoutSettlingCover())
      } else {
        self
      }
    #else
      self
    #endif
  }
}

struct TabLayoutSettleTracker {
  static let quietPeriod: TimeInterval = 0.15
  static let limit: TimeInterval = 1

  private var startedAt: TimeInterval?
  private var signature: String?
  private var changedAt: TimeInterval = 0

  mutating func isSettled(signature: String, hasContent: Bool, at time: TimeInterval) -> Bool {
    let startedAt = self.startedAt ?? time
    self.startedAt = startedAt
    if signature != self.signature {
      self.signature = signature
      self.changedAt = time
    }
    if time - startedAt >= Self.limit {
      return true
    }
    return hasContent && time - self.changedAt >= Self.quietPeriod
  }
}

#if os(iOS)
  private struct TabLayoutSettlingCover: ViewModifier {
    @State private var isSettled = false

    func body(content: Content) -> some View {
      content.overlay {
        if !self.isSettled {
          MusicSetupSplashView()
            .accessibilityHidden(true)
            .background {
              TabLayoutSettleWatcher {
                withAnimation(.easeOut(duration: 0.15)) {
                  self.isSettled = true
                }
              }
              .frame(width: 0, height: 0)
            }
            .transition(.opacity)
        }
      }
    }
  }

  private struct TabLayoutSettleWatcher: UIViewRepresentable {
    let onSettle: @MainActor () -> Void

    func makeUIView(context _: Context) -> WatcherView {
      let view = WatcherView()
      view.isUserInteractionEnabled = false
      view.onSettle = self.onSettle
      return view
    }

    func updateUIView(_ view: WatcherView, context _: Context) {
      view.onSettle = self.onSettle
    }

    final class WatcherView: UIView {
      private static let nudgeFrame = 2

      var onSettle: (@MainActor () -> Void)?
      private var link: CADisplayLink?
      private var tracker = TabLayoutSettleTracker()
      private var frameCount = 0

      override func didMoveToWindow() {
        super.didMoveToWindow()
        self.link?.invalidate()
        self.link = nil
        guard self.window != nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(self.tick))
        link.add(to: .main, forMode: .common)
        self.link = link
      }

      @objc private func tick() {
        guard let window = self.window else { return }
        self.frameCount += 1
        let tabs = Self.tabBarController(in: window.rootViewController)
        if self.frameCount == Self.nudgeFrame, let content = tabs?.selectedViewController {
          content.additionalSafeAreaInsets.top += 1
          content.view.layoutIfNeeded()
          content.additionalSafeAreaInsets.top -= 1
        }
        guard self.frameCount > Self.nudgeFrame else { return }
        let bars = Self.navigationBarFrames(in: window)
        let contentTop = tabs?.selectedViewController?.viewIfLoaded?.safeAreaInsets.top ?? -1
        let signature = "\(contentTop) \(bars)"
        guard self.tracker.isSettled(
          signature: signature,
          hasContent: !bars.isEmpty,
          at: CACurrentMediaTime(),
        ) else { return }
        self.link?.invalidate()
        self.link = nil
        self.onSettle?()
      }

      private static func navigationBarFrames(in window: UIWindow) -> [CGRect] {
        var frames: [CGRect] = []
        func collect(_ view: UIView) {
          guard !view.isHidden else { return }
          if let bar = view as? UINavigationBar {
            frames.append(bar.convert(bar.bounds, to: window))
          }
          view.subviews.forEach(collect)
        }
        collect(window)
        return frames
      }

      private static func tabBarController(in controller: UIViewController?)
        -> UITabBarController? {
        guard let controller else { return nil }
        if let tabs = controller as? UITabBarController {
          return tabs
        }
        for child in controller.children {
          if let tabs = self.tabBarController(in: child) {
            return tabs
          }
        }
        return nil
      }
    }
  }
#endif
