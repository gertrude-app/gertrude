#if os(macOS)
  import SwiftUI
  import Testing

  @testable import GertieUI

  @MainActor
  struct GertieActionContentLayoutTests {
    @Test
    func flatLayoutKeepsTheIconAtTheTopAndCopyAboveBottomActions() throws {
      let regions = try self.renderLayout(
        containerSize: CGSize(width: 1000, height: 800),
        actionCount: 2,
      )

      #expect(regions.red == CGRect(x: 280, y: 80, width: 440, height: 40))
      #expect(regions.green == CGRect(x: 280, y: 522, width: 440, height: 100))
      #expect(regions.blue == CGRect(x: 280, y: 650, width: 440, height: 120))
    }

    @Test
    func bookLayoutPlacesIconOneThirdDownAboveBottomAlignedCopy() throws {
      let division = CGRect(x: 540, y: -40, width: 24, height: 880)
      let regions = try self.renderLayout(
        containerSize: CGSize(width: 1200, height: 800),
        division: division,
        actionCount: 2,
      )
      let group = regions.red.union(regions.green).union(regions.blue)

      #expect(group.minX > division.maxX)
      #expect(group.midX == 882)
      #expect(abs(regions.red.midY - (30 + (regions.green.minY - 30) / 3)) <= 0.5)
      #expect(regions.green.minY == 522)
      #expect(regions.blue.maxY == 770)
      #expect(regions.red.midX == regions.green.midX)
      #expect(regions.green.midX == regions.blue.midX)
      #expect(regions.green.minY - regions.red.maxY > 16)
      #expect(regions.blue.minY - regions.green.maxY == 28)
    }

    @Test
    func tabletopCentersIconAndCopyAboveTheFoldWithBottomAlignedActions() throws {
      let division = CGRect(x: -100, y: 420, width: 1000, height: 24)
      let regions = try self.renderLayout(
        containerSize: CGSize(width: 800, height: 1000),
        division: division,
        actionCount: 2,
      )
      let introduction = regions.red.union(regions.green)

      #expect(introduction.midX == 400)
      #expect(introduction.midY == 210)
      #expect(introduction.maxY < division.minY)
      #expect(regions.green.minY - regions.red.maxY == 40)
      #expect(regions.blue.midX == 400)
      #expect(regions.blue.minY > division.maxY)
      #expect(regions.blue.maxY == 970)
    }

    @Test
    func longTabletopCopyFadesBeforeTheFoldWithoutMovingActionsOffscreen() throws {
      let regions = try self.renderLayout(
        containerSize: CGSize(width: 800, height: 1000),
        division: CGRect(x: 0, y: 420, width: 800, height: 24),
        messageHeight: 1000,
        actionCount: 2,
      )

      #expect(regions.red.minY == 30)
      #expect((CGFloat(396) ..< 420).contains(regions.green.maxY))
      #expect(regions.blue.minY == 854)
      #expect(regions.blue.maxY == 970)
    }

    @Test(arguments: [
      CGSize(width: 1000, height: 800),
      CGSize(width: 390, height: 844),
      CGSize(width: 1000, height: 400),
    ])
    func padCentersTheWholeGroupEvenInNarrowOrShortWindows(containerSize: CGSize) throws {
      let regions = try self.renderLayout(
        containerSize: containerSize,
        actionCount: 1,
        isPad: true,
      )
      let group = regions.red.union(regions.green).union(regions.blue)
      let metrics = GertieActionScreenMetrics.resolve(
        containerSize: containerSize,
        geometry: nil,
        usesAccessibilitySize: false,
      )

      #expect(abs(group.midY - containerSize.height / 2) <= 0.5)
      #expect(group.midX == containerSize.width / 2)
      #expect(regions.green.minY - regions.red.maxY == metrics.spacing + 16)
      #expect(regions.blue.minY - regions.green.maxY == metrics.spacing + metrics.buttonPadTop)
      #expect(regions.blue.maxY < containerSize.height - metrics.insets.bottom)
    }

    private func renderLayout(
      containerSize: CGSize,
      division: CGRect? = nil,
      messageHeight: CGFloat = 100,
      actionCount: Int,
      isPad: Bool = false,
    ) throws -> RenderedScreenRegions {
      let geometry = FoldedContentGeometry.resolve(
        containerSize: containerSize,
        divisions: division.map { [$0] } ?? [],
      )
      let metrics = GertieActionScreenMetrics.resolve(
        containerSize: containerSize,
        geometry: geometry,
        usesAccessibilitySize: false,
      )

      return try RenderedScreenRegions(containerSize: containerSize) {
        GertieScreenContentLayout(
          containerSize: containerSize,
          geometry: geometry,
          configuration: metrics.layoutConfiguration.resolvingPlacement(
            isPad: isPad,
            geometry: geometry,
          ),
          hasActions: actionCount > 0,
        ) {
          Color(red: 1, green: 0, blue: 0).frame(height: metrics.iconSize)
        } message: {
          Color(red: 0, green: 1, blue: 0).frame(height: messageHeight)
        } actions: {
          VStack(spacing: metrics.spacing) {
            ForEach(0 ..< actionCount, id: \.self) { _ in
              Color(red: 0, green: 0, blue: 1).frame(height: 52)
            }
          }
        }
      }
    }
  }
#endif
