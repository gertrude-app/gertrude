import SwiftUI
import Testing

@testable import LibViews

struct DetailContentLayoutTests {
  @MainActor
  @Test(arguments: [CGFloat(0), 44])
  func collectionHeroRowsKeepMatchingSpaceAboveAndBelowTheHero(topInset: CGFloat) throws {
    let hero = Color.red
      .frame(width: 100, height: 200)
      .detailHeroRow(topInset: topInset)
    let image = try #require(ImageRenderer(content: hero).cgImage)

    #expect(image.width == 100)
    #expect(image.height == Int(200 + topInset + 18 + 24 + 30))
  }

  @Test(arguments: [CGFloat(600), 680, 744, 800, 1024])
  func wideHeroesPlaceArtworkBesideMetadata(containerWidth: CGFloat) {
    #expect(DetailHeroLayout.usesHorizontalLayout(containerWidth: containerWidth))
  }

  @Test(arguments: [CGFloat(320), 390, 430, 599])
  func narrowHeroesKeepStackedArtworkAndMetadata(containerWidth: CGFloat) {
    #expect(!DetailHeroLayout.usesHorizontalLayout(containerWidth: containerWidth))
  }

  @Test(arguments: [CGFloat(200), 360, 500, 900])
  func bookArtworkPreservesPaddingWithinItsHeroPane(containerWidth: CGFloat) {
    let artworkSize = DetailHeroLayout.bookArtworkSize(
      containerWidth: containerWidth,
      maximumArtworkSize: 320,
    )

    #expect(artworkSize <= 320)
    #expect(artworkSize <= containerWidth - 64)
  }

  @Test(arguments: [CGFloat(140), 220, 320])
  func bookArtworkRespectsTheHeroFittingCandidate(maximumArtworkSize: CGFloat) {
    #expect(DetailHeroLayout.bookArtworkSize(
      containerWidth: 500,
      maximumArtworkSize: maximumArtworkSize,
    ) == maximumArtworkSize)
  }

  @Test(arguments: [CGFloat(0), 32, 64])
  func temporarilyNarrowPaneNeverProducesInvalidArtworkSize(containerWidth: CGFloat) {
    #expect(DetailHeroLayout.bookArtworkSize(
      containerWidth: containerWidth,
      maximumArtworkSize: 320,
    ) == 1)
  }

  @MainActor
  @Test(arguments: [CGFloat(100), 400])
  func bookHeroSpansBothHalvesWithoutTakingTheFullDisplayHeight(metadataHeight: CGFloat) throws {
    let geometry = try #require(FoldedContentGeometry.resolve(
      containerSize: CGSize(width: 1000, height: 800),
      divisions: [CGRect(x: 450, y: 0, width: 24, height: 800)],
    ))
    let hero = BookDetailHero(geometry: geometry) { size in
      Color.red.frame(width: size, height: size)
    } metadata: {
      Color.blue.frame(width: 200, height: metadataHeight)
    }
    let image = try #require(ImageRenderer(content: hero).cgImage)

    #expect(image.width == 1000)
    #expect(image.height == Int(max(320, metadataHeight)))
  }
}
