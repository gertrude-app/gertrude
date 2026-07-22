import Foundation
import SwiftUI

public struct NowPlayingBackgroundView: View {
  private let artworkURL: URL?

  public init(artworkURL: URL?) {
    self.artworkURL = artworkURL
  }

  public var body: some View {
    GeometryReader { proxy in
      ZStack {
        Color.black

        CachedArtworkImageView(
          url: self.artworkURL,
        ) { image in
          image
            .resizable()
            .scaledToFill()
            .frame(width: proxy.size.width, height: proxy.size.height)
            .scaleEffect(1.2)
            .blur(radius: 80)
            .opacity(0.7)
        } placeholder: {
          Color.clear
        }
      }
      .frame(width: proxy.size.width, height: proxy.size.height)
      .clipped()
    }
    .ignoresSafeArea()
  }
}
