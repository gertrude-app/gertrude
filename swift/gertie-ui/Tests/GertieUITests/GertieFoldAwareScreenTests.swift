#if os(macOS)
  import SwiftUI
  import Testing

  @testable import GertieUI

  @MainActor
  struct GertieFoldAwareScreenTests {
    @Test
    func waitingStatusCountsDownFromItsSharedStart() {
      let start = ContinuousClock.now
      let status = GertieWaitingStatus(
        label: "Waiting for account connection…",
        delay: .seconds(45),
        startedAt: start,
      )

      #expect(status.remainingDelay(at: start.advanced(by: .seconds(10))) == .seconds(35))
    }

    @Test(arguments: [
      CGSize(width: 1000, height: 800),
      CGSize(width: 390, height: 844),
      CGSize(width: 1000, height: 400),
    ])
    func optedInPadScreensCenterTheirContentAndActions(size: CGSize) throws {
      let regions = try self.render(
        size: size,
        isPad: true,
        centersFlatContentOnPad: true,
      )
      let group = regions.red.union(regions.green).union(regions.blue)

      #expect(abs(group.midY - size.height / 2) <= 0.5)
      #expect(group.midX == size.width / 2)
      #expect(regions.green.height == 100)
      #expect(regions.blue.height == 52)
      #expect(try self.render(size: size, isPad: true).green.isNull) // not opted in: custom layout
    }

    private func render(
      size: CGSize,
      isPad: Bool = false,
      centersFlatContentOnPad: Bool = false,
    ) throws -> RenderedScreenRegions {
      let screen = GertieFoldAwareScreen(centersFlatContentOnPad: centersFlatContentOnPad) {
        Color(red: 1, green: 0, blue: 0).frame(width: 200, height: 100)
      } icon: {
        Color(red: 1, green: 0, blue: 0).frame(height: 48)
      } message: {
        Color(red: 0, green: 1, blue: 0).frame(height: 100)
      } actions: {
        Color(red: 0, green: 0, blue: 1).frame(height: 52)
      }
      return try RenderedScreenRegions(containerSize: size) {
        screen.content(
          containerSize: size,
          geometry: nil,
          isPad: isPad,
        )
      }
    }
  }
#endif
