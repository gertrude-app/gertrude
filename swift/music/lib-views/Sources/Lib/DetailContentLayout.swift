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
      #if os(iOS) && compiler(>=6.4)
        if #available(iOS 27.1, *),
           let geometry = FoldedContentGeometry.resolve(
             containerSize: proxy.size,
             divisions: proxy.reservedRegions(kind: .division).map(\.frame),
           ) {
          if geometry.axis == .vertical {
            self.tabletopContent(geometry: geometry)
          } else {
            self.normal(proxy, geometry)
          }
        } else {
          self.normal(proxy, nil)
        }
      #else
        self.normal(proxy, nil)
      #endif
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
    self.artwork = artwork(DetailHeroLayout.bookArtworkSize(
      containerWidth: geometry.primarySize.width,
      maximumArtworkSize: 320,
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

enum DetailHeroLayout {
  static func usesHorizontalLayout(containerWidth: CGFloat) -> Bool {
    containerWidth >= 600
  }

  static func bookArtworkSize(containerWidth: CGFloat, maximumArtworkSize: CGFloat) -> CGFloat {
    max(1, min(maximumArtworkSize, containerWidth - 64))
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
