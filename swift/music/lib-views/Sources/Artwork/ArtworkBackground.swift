import Foundation
import SwiftUI

struct BlurredArtworkBackground: View {
  let artworkURL: URL?

  var body: some View {
    GeometryReader { proxy in
      CachedArtworkImageView(url: self.artworkURL) { image in
        image
          .resizable()
          .scaledToFill()
          .frame(width: proxy.size.width, height: proxy.size.height)
          .scaleEffect(1.2)
          .blur(radius: 80)
      } placeholder: {
        Color.clear
      }
      .frame(width: proxy.size.width, height: proxy.size.height)
      .clipped()
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}

struct HeroArtworkBackground: View {
  let artworkURL: URL?
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    ZStack {
      BlurredArtworkBackground(artworkURL: self.artworkURL)
        .opacity(0.3)
      self.grain
    }
    .mask {
      LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  @ViewBuilder
  private var grain: some View {
    if self.colorScheme == .dark {
      FilmGrain()
        .opacity(0.2)
    } else {
      BlurredArtworkBackground(artworkURL: self.artworkURL)
        .saturation(2.2)
        .brightness(-0.2)
        .mask { FilmGrain() }
        .opacity(0.35)
    }
  }
}

struct FilmGrain: View {
  var body: some View {
    if let image = Self.image {
      image
        .resizable(resizingMode: .tile)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
  }

  private static let scale: CGFloat = 3
  private static let tileSize = 480
  private static let speckCount = 5000
  private static let speckRadius: ClosedRange<CGFloat> = 0.20 ... 0.70

  private static let image: Image? = {
    guard let context = CGContext(
      data: nil,
      width: tileSize,
      height: tileSize,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue,
    ) else { return nil }
    let size = CGFloat(tileSize)
    for _ in 0 ..< speckCount {
      let center = CGPoint(x: .random(in: 0 ..< size), y: .random(in: 0 ..< size))
      let sizeRoll = CGFloat(pow(Double.random(in: 0 ... 1), 2.5))
      let radius = (speckRadius
        .lowerBound + sizeRoll * (speckRadius.upperBound - speckRadius.lowerBound)) * scale
      let alpha = Double.random(in: 0.35 ... 1) * (1 - Double(sizeRoll) * 0.5)
      context.setFillColor(CGColor(gray: 1, alpha: alpha))
      for dx in wrapOffsets(center.x, radius: radius, size: size) {
        for dy in wrapOffsets(center.y, radius: radius, size: size) {
          context.fillEllipse(in: CGRect(
            x: center.x + dx - radius,
            y: center.y + dy - radius,
            width: radius * 2,
            height: radius * 2,
          ))
        }
      }
    }
    guard let cgImage = context.makeImage() else { return nil }
    return Image(decorative: cgImage, scale: scale)
  }()

  private static func wrapOffsets(_ value: CGFloat, radius: CGFloat, size: CGFloat) -> [CGFloat] {
    var offsets: [CGFloat] = [0]
    if value - radius < 0 { offsets.append(size) }
    if value + radius > size { offsets.append(-size) }
    return offsets
  }
}
