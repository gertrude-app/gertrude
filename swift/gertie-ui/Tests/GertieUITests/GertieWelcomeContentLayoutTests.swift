#if os(macOS)
  import SwiftUI
  import Testing

  @testable import GertieUI

  @MainActor
  struct GertieWelcomeContentLayoutTests {
    @Test
    func bookWelcomeMovesTheWholeBlockToTheActualRightRegion() throws {
      let division = CGRect(x: 540, y: -40, width: 24, height: 880)
      let regions = try WelcomeLayoutRegions(
        containerSize: CGSize(width: 1200, height: 800),
        division: division,
      )

      #expect(regions.introduction == CGRect(x: 662, y: 308, width: 440, height: 100))
      #expect(regions.action == CGRect(x: 662, y: 440, width: 440, height: 52))
      #expect(regions.introduction.minX > division.maxX)
      #expect(regions.action.minX > division.maxX)
    }

    @Test
    func tabletopWelcomeCentersTheIntroductionAndBottomAlignsTheAction() throws {
      let division = CGRect(x: -100, y: 420, width: 1000, height: 24)
      let regions = try WelcomeLayoutRegions(
        containerSize: CGSize(width: 800, height: 1000),
        division: division,
      )

      #expect(regions.introduction == CGRect(x: 180, y: 160, width: 440, height: 100))
      #expect(regions.action == CGRect(x: 180, y: 918, width: 440, height: 52))
      #expect(regions.introduction.maxY < division.minY)
      #expect(regions.action.minY > division.maxY)
      #expect(regions.action.maxY == 970)
    }

    @Test
    func padWelcomeCentersTheFlatBlockVertically() throws {
      let regions = try WelcomeLayoutRegions(
        containerSize: CGSize(width: 800, height: 1000),
        isPad: true,
      )

      #expect(regions.introduction == CGRect(x: 180, y: 408, width: 440, height: 100))
      #expect(regions.action == CGRect(x: 180, y: 540, width: 440, height: 52))
    }

    @Test
    func phoneWelcomeBottomAlignsTheFlatBlock() throws {
      let regions = try WelcomeLayoutRegions(containerSize: CGSize(width: 800, height: 1000))

      #expect(regions.introduction == CGRect(x: 180, y: 786, width: 440, height: 100))
      #expect(regions.action == CGRect(x: 180, y: 918, width: 440, height: 52))
    }
  }

  @MainActor
  private struct WelcomeLayoutRegions {
    let introduction: CGRect
    let action: CGRect

    init(containerSize: CGSize, division: CGRect? = nil, isPad: Bool = false) throws {
      let layout = GertieWelcomeContentLayout(
        containerSize: containerSize,
        geometry: division.flatMap {
          FoldedContentGeometry.resolve(containerSize: containerSize, divisions: [$0])
        },
        isPad: isPad,
      ) { _ in
        Color(red: 1, green: 0, blue: 0).frame(height: 100)
      } action: {
        Color(red: 0, green: 0, blue: 1).frame(height: 52)
      }
      let regions = try RenderedScreenRegions(containerSize: containerSize) { layout }
      self.introduction = try #require(regions.red.isNull ? nil : regions.red)
      self.action = try #require(regions.blue.isNull ? nil : regions.blue)
    }
  }
#endif
