import GertieUI
import SwiftUI

struct DetailContentLayout<Normal: View, Hero: View, Content: View>: View {
  private let artworkURL: URL?
  private let normal: (GeometryProxy, FoldedContentGeometry?) -> Normal
  private let hero: (CGFloat, CGFloat) -> Hero
  private let content: Content

  init(
    artworkURL: URL? = nil,
    @ViewBuilder normal: @escaping (GeometryProxy, FoldedContentGeometry?) -> Normal,
    @ViewBuilder hero: @escaping (CGFloat, CGFloat) -> Hero,
    @ViewBuilder content: () -> Content,
  ) {
    self.artworkURL = artworkURL
    self.normal = normal
    self.hero = hero
    self.content = content()
  }

  var body: some View {
    GeometryReader { proxy in
      let geometry = FoldedContentGeometry.resolve(in: proxy)
      if let geometry, geometry.axis == .vertical {
        self.tabletopContent(geometry: geometry)
      } else {
        self.normal(proxy, geometry)
      }
    }
  }

  private func tabletopContent(geometry: FoldedContentGeometry) -> some View {
    FoldedContentLayout(geometry: geometry) { _ in
      TabletopDetailHero(artworkURL: self.artworkURL, hero: self.hero)
    } secondary: { _ in
      self.foldedScrollContent
    }
    .background(.background)
  }

  private var foldedScrollContent: some View {
    self.content
      .contentMargins(.top, 24, for: .scrollContent)
      .mask(alignment: .top) {
        VStack(spacing: 0) {
          LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
            .frame(height: 24)
          Color.black
        }
        .ignoresSafeArea(.container, edges: [.bottom, .trailing])
      }
  }
}

struct BookDetailHero<Artwork: View, Metadata: View>: View {
  private let geometry: FoldedContentGeometry
  private let artwork: Artwork
  private let metadata: Metadata

  init(
    geometry: FoldedContentGeometry,
    @ViewBuilder artwork: (CGFloat) -> Artwork,
    @ViewBuilder metadata: () -> Metadata,
  ) {
    self.geometry = geometry
    self.artwork = artwork(DetailHeroLayout.compactArtworkSize(
      containerWidth: geometry.primarySize.width,
    ))
    self.metadata = metadata()
  }

  var body: some View {
    HStack(spacing: self.geometry.spacing) {
      self.artwork
        .frame(width: self.geometry.primarySize.width)

      self.metadata
        .frame(width: self.geometry.secondarySize.width)
    }
    .fixedSize(horizontal: false, vertical: true)
  }
}

struct DetailHero<Artwork: View, Metadata: View, PlayButton: View>: View {
  private let containerWidth: CGFloat
  private let maximumArtworkSize: CGFloat
  private let artwork: (CGFloat) -> Artwork
  private let metadata: Metadata
  private let playButton: PlayButton

  init(
    containerWidth: CGFloat,
    maximumArtworkSize: CGFloat = 320,
    @ViewBuilder artwork: @escaping (CGFloat) -> Artwork,
    @ViewBuilder metadata: () -> Metadata,
    @ViewBuilder playButton: () -> PlayButton,
  ) {
    self.containerWidth = containerWidth
    self.maximumArtworkSize = maximumArtworkSize
    self.artwork = artwork
    self.metadata = metadata()
    self.playButton = playButton()
  }

  var body: some View {
    if DetailHeroLayout.usesHorizontalLayout(containerWidth: self.containerWidth) {
      HStack(spacing: 36) {
        self.artwork(min(
          self.maximumArtworkSize,
          min(300, max(220, (self.containerWidth - 96) * 0.38)),
        ))

        DetailHeroMetadata {
          self.metadata
        } playButton: {
          self.playButton
        }
      }
      .frame(maxWidth: 900)
      .padding(.horizontal, 32)
    } else {
      VStack(spacing: 16) {
        self.artwork(min(
          self.maximumArtworkSize,
          DetailHeroLayout.compactArtworkSize(containerWidth: self.containerWidth),
        ))

        self.metadata
          .frame(maxWidth: 560)
          .padding(.horizontal, 28)

        self.playButton
          .frame(maxWidth: 520)
          .padding(.horizontal, 20)
          .padding(.top, 4)
      }
    }
  }
}

struct DetailHeroMetadata<Metadata: View, PlayButton: View>: View {
  private let metadata: Metadata
  private let playButton: PlayButton

  init(
    @ViewBuilder metadata: () -> Metadata,
    @ViewBuilder playButton: () -> PlayButton,
  ) {
    self.metadata = metadata()
    self.playButton = playButton()
  }

  var body: some View {
    VStack(spacing: 18) {
      self.metadata

      self.playButton
        .frame(maxWidth: 440)
    }
    .frame(maxWidth: 440)
  }
}

enum DetailHeroLayout {
  static func usesHorizontalLayout(containerWidth: CGFloat) -> Bool {
    containerWidth >= 600
  }

  static func compactArtworkSize(containerWidth: CGFloat) -> CGFloat {
    max(1, min(320, containerWidth - 64))
  }
}

private struct TabletopDetailHero<Hero: View>: View {
  let artworkURL: URL?
  let hero: (CGFloat, CGFloat) -> Hero

  var body: some View {
    GeometryReader { proxy in
      ViewThatFits(in: .vertical) {
        self.candidate(width: proxy.size.width, maximumArtworkSize: 320)
        self.candidate(width: proxy.size.width, maximumArtworkSize: 220)
        self.candidate(width: proxy.size.width, maximumArtworkSize: 140)
        ScrollView {
          self.candidate(width: proxy.size.width, maximumArtworkSize: 140)
        }
        .scrollBounceBehavior(.basedOnSize)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .background {
      HeroArtworkBackground(artworkURL: self.artworkURL)
        .ignoresSafeArea(edges: [.top, .horizontal])
    }
    .background(.background)
  }

  private func candidate(width: CGFloat, maximumArtworkSize: CGFloat) -> some View {
    self.hero(width, maximumArtworkSize)
      .frame(maxWidth: .infinity)
      .padding(.top, 18)
      .padding(.bottom, 24)
      .fixedSize(horizontal: false, vertical: true)
  }
}

struct DetailTrackList<Content: View>: View {
  private let headerArtworkURL: URL?
  private let content: Content

  init(
    headerArtworkURL: URL? = nil,
    @ViewBuilder content: () -> Content,
  ) {
    self.headerArtworkURL = headerArtworkURL
    self.content = content()
  }

  var body: some View {
    List {
      self.content

      Color.clear
        .frame(height: 112)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .accessibilityHidden(true)
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .detailHeroBackground(artworkURL: self.headerArtworkURL)
    .background(.background)
  }
}

extension View {
  func detailHeroRow(topInset: CGFloat) -> some View {
    self
      .frame(maxWidth: .infinity)
      .padding(.top, topInset + 18)
      .padding(.bottom, 24)
      .anchorPreference(key: DetailHeroBoundsPreferenceKey.self, value: .bounds) { $0 }
      .padding(.bottom, 30)
      .listRowInsets(EdgeInsets())
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
  }

  func detailHeroBackground(artworkURL: URL?) -> some View {
    self.backgroundPreferenceValue(DetailHeroBoundsPreferenceKey.self) { anchor in
      if let anchor, let artworkURL {
        GeometryReader { proxy in
          let bounds = proxy[anchor]
          HeroArtworkBackground(artworkURL: artworkURL)
            .frame(height: bounds.height)
            .offset(y: bounds.minY)
        }
        .ignoresSafeArea(edges: .horizontal)
        .allowsHitTesting(false)
      }
    }
  }
}

struct DetailHeroBoundsPreferenceKey: PreferenceKey {
  static var defaultValue: Anchor<CGRect>? { nil }

  static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
    value = nextValue() ?? value
  }
}
