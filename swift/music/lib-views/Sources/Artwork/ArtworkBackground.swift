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

  var body: some View {
    BlurredArtworkBackground(artworkURL: self.artworkURL)
      .mask {
        LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
      }
      .opacity(0.3)
  }
}
