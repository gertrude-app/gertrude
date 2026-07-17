import Foundation
import SwiftUI

enum PlaybackWaveformAlignment {
  case center
  case bottom

  var frameAlignment: Alignment {
    switch self {
    case .center: .center
    case .bottom: .bottom
    }
  }

  var verticalAlignment: VerticalAlignment {
    switch self {
    case .center: .center
    case .bottom: .bottom
    }
  }
}

struct PlaybackWaveformView: View {
  let isPlaying: Bool
  let color: Color
  let barCount: Int
  let barWidth: CGFloat
  let barSpacing: CGFloat
  let minimumBarHeight: CGFloat
  let maximumBarHeight: CGFloat
  let containerWidth: CGFloat
  let containerHeight: CGFloat
  let alignment: PlaybackWaveformAlignment
  let phaseStep: Double
  let minimumInterval: TimeInterval?

  var body: some View {
    if self.isPlaying {
      TimelineView(.animation(minimumInterval: self.minimumInterval)) { timeline in
        self.bars(date: timeline.date)
      }
    } else {
      self.bars(date: nil)
    }
  }

  private func bars(date: Date?) -> some View {
    HStack(alignment: self.alignment.verticalAlignment, spacing: self.barSpacing) {
      ForEach(0 ..< self.barCount, id: \.self) { index in
        RoundedRectangle(cornerRadius: self.barWidth / 2, style: .continuous)
          .fill(self.color)
          .frame(
            width: self.barWidth,
            height: self.barHeight(index: index, date: date),
          )
      }
    }
    .frame(
      width: self.containerWidth,
      height: self.containerHeight,
      alignment: self.alignment.frameAlignment,
    )
  }

  private func barHeight(index: Int, date: Date?) -> CGFloat {
    guard let date else { return self.minimumBarHeight }
    let phase = date.timeIntervalSinceReferenceDate * 5.5 + Double(index) * self.phaseStep
    let progress = (sin(phase) + 1) / 2
    return self.minimumBarHeight
      + CGFloat(progress) * (self.maximumBarHeight - self.minimumBarHeight)
  }
}
