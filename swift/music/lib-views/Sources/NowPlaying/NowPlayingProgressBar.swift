import Foundation
import SwiftUI

struct NowPlayingProgressBar: View {
  let progress: Double
  let duration: TimeInterval
  let onScrub: @MainActor @Sendable (TimeInterval) -> Void

  @State private var scrubbedProgress: Double?
  @State private var isScrubbing = false
  @State private var scrubStartProgress: Double?

  var body: some View {
    VStack(spacing: 9) {
      GeometryReader { proxy in
        ZStack(alignment: .center) {
          ZStack(alignment: .leading) {
            Capsule()
              .fill(.white.opacity(self.isScrubbing ? 0.3 : 0.18))

            Capsule()
              .fill(.white)
              .frame(
                width: proxy.size.width * self.displayedProgress,
              )
          }
          .frame(height: self.isScrubbing ? 13 : 9)
          .clipShape(Capsule())
          .shadow(
            color: .white.opacity(self.isScrubbing ? 0.24 : 0),
            radius: self.isScrubbing ? 9 : 0,
          )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(self.dragGesture(width: proxy.size.width))
        .animation(.easeOut(duration: 0.18), value: self.isScrubbing)
      }
      .frame(height: 28)

      HStack {
        Text(self.formattedTime(self.elapsedTime))

        Spacer(minLength: 12)

        Text("-\(self.formattedTime(self.remainingTime))")
      }
      .font(.system(size: 12, weight: .semibold, design: .rounded))
      .monospacedDigit()
      .foregroundStyle(.white.opacity(0.7))
    }
    .onChange(of: self.progress) { _, _ in
      if !self.isScrubbing {
        self.scrubbedProgress = nil
      }
    }
  }

  private func dragGesture(width: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        guard self.canScrub, width > 0 else { return }
        if !self.isScrubbing {
          self.isScrubbing = true
          self.scrubStartProgress = self.clampedProgress
        }
        self.scrubbedProgress = self.relativeScrubProgress(
          for: value.translation.width,
          width: width,
        )
      }
      .onEnded { value in
        guard self.canScrub, width > 0 else {
          self.isScrubbing = false
          self.scrubbedProgress = nil
          self.scrubStartProgress = nil
          return
        }
        let progress = self.relativeScrubProgress(
          for: value.translation.width,
          width: width,
        )
        self.scrubbedProgress = progress
        self.onScrub(self.time(for: progress))
        self.isScrubbing = false
        self.scrubStartProgress = nil
      }
  }

  private func relativeScrubProgress(
    for translationX: CGFloat,
    width: CGFloat,
  ) -> Double {
    let startingProgress = self.scrubStartProgress ?? self.clampedProgress
    return min(1, max(0, startingProgress + Double(translationX / width)))
  }

  private var canScrub: Bool {
    self.duration.isFinite && self.duration > 0
  }

  private var displayedProgress: Double {
    self.scrubbedProgress ?? self.clampedProgress
  }

  private var clampedProgress: Double {
    min(1, max(0, self.progress))
  }

  private var elapsedTime: TimeInterval {
    max(0, self.duration) * self.displayedProgress
  }

  private var remainingTime: TimeInterval {
    max(0, max(0, self.duration) - self.elapsedTime)
  }

  private func time(for progress: Double) -> TimeInterval {
    max(0, self.duration) * min(1, max(0, progress))
  }

  private func formattedTime(_ time: TimeInterval) -> String {
    let rounded = max(0, Int(time.rounded()))
    return "\(rounded / 60):\(String(format: "%02d", rounded % 60))"
  }
}
