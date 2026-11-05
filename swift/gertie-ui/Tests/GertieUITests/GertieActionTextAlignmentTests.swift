#if os(macOS)
  import SwiftUI
  import Testing

  @testable import GertieUI

  @MainActor
  struct GertieActionTextAlignmentTests {
    @Test(arguments: [false, true])
    func padAndTabletopCenterPlainMessages(isPad: Bool) throws {
      let regions = try self.render(
        GertieActionScreen(message: "Continue setup."),
        isPad: isPad,
        isTabletop: !isPad,
      )

      #expect(abs(regions.red.midX - 220) <= 1)
    }

    @Test(arguments: [(false, false), (true, false), (false, true)])
    func phoneMessagesAndBulletListsKeepLeadingAlignment(isPad: Bool, isTabletop: Bool) throws {
      let regions = try self.render(
        GertieActionScreen(
          message: "Continue setup.",
          bullets: isPad || isTabletop ? ["Requirement"] : [],
          // pad/tabletop only stay leading with a list
        ),
        isPad: isPad,
        isTabletop: isTabletop,
      )

      #expect(regions.red.minX < 3)
      #expect(regions.red.midX < 220)
    }

    @Test(arguments: [false, true])
    func onlyTheTabletopUpperPaneProvidesCenteredTextContext(isTabletop: Bool) throws {
      let size = isTabletop ? CGSize(width: 800, height: 1000) : CGSize(width: 1200, height: 800)
      let division = isTabletop
        ? CGRect(x: 0, y: 420, width: 800, height: 24)
        : CGRect(x: 540, y: 0, width: 24, height: 800)
      let geometry = try #require(FoldedContentGeometry.resolve(
        containerSize: size,
        divisions: [division],
      ))
      let regions = try RenderedScreenRegions(containerSize: size) {
        GertieScreenContentLayout(
          containerSize: size,
          geometry: geometry,
          configuration: .result,
          hasActions: true,
        ) {
          EmptyView()
        } message: {
          Color(red: 0, green: 1, blue: 0)
            .frame(height: 100)
            .mask(alignment: .topLeading) {
              Text("Continue setup.").gertieScreenTextAlignment()
            }
        } actions: {
          Color(red: 0, green: 0, blue: 1)
            .frame(height: 100)
            .mask(alignment: .topLeading) {
              Text("Continue setup.").gertieScreenTextAlignment()
            }
        }
      }
      let paneCenter = isTabletop
        ? size.width / 2
        : division.maxX + geometry.secondarySize.width / 2

      if isTabletop {
        #expect(abs(regions.green.midX - paneCenter) <= 1)
        #expect(regions.green.maxY < division.minY)
        #expect(regions.blue.minY > division.maxY)
      } else {
        #expect(regions.green.minX > division.maxX)
        #expect(regions.green.midX < paneCenter)
      }
      #expect(regions.blue.midX < paneCenter)
    }

    private func render(
      _ screen: GertieActionScreen<EmptyView>,
      isPad: Bool,
      isTabletop: Bool = false,
    ) throws -> RenderedScreenRegions {
      try RenderedScreenRegions(containerSize: CGSize(width: 440, height: 100)) {
        Color(red: 1, green: 0, blue: 0)
          .mask(alignment: .topLeading) {
            screen.messageText(isPad: isPad)
          }
          .environment(\.gertieScreenIsTabletop, isTabletop)
      }
    }
  }
#endif
