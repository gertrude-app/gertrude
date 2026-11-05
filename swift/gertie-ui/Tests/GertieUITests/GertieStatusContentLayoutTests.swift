#if os(macOS)
  import SwiftUI
  import Testing

  @testable import GertieUI

  @MainActor
  struct GertieStatusContentLayoutTests {
    @Test
    func flatResultsCenterTheOutcomeWithInsetButtons() throws {
      let regions = try self.render(
        .result,
        size: CGSize(width: 1000, height: 800),
        actionCount: 1,
      )
      let group = regions.red.union(regions.green).union(regions.blue)

      #expect(abs(group.midY - 400) <= 0.5)
      #expect(group.midX == 500)
      #expect(regions.blue.width == 380)
    }

    @Test(arguments: [0, 1])
    func tabletopResultsCenterTheOutcomeAboveAndBottomAlignActionsBelow(actionCount: Int) throws {
      let regions = try self.render(
        .result,
        size: CGSize(width: 800, height: 1000),
        division: CGRect(x: -100, y: 420, width: 1000, height: 24),
        actionCount: actionCount,
      )
      let outcome = regions.red.union(regions.green)

      #expect(outcome.midX == 400)
      #expect(outcome.midY == 210)
      #expect(outcome.maxY < 420)
      #expect(regions.green.minY - regions.red.maxY == 24)
      if actionCount > 0 {
        #expect(regions.blue.midX == 400)
        #expect(regions.blue.maxY == 970)
        #expect(regions.blue.minY > 444)
      } else {
        #expect(regions.blue.isNull)
      }
    }

    @Test
    func bookLoadingKeepsSpinnerAndMessageTogetherInTheCenterOfTheRightPane() throws {
      let regions = try self.render(
        .loading,
        size: CGSize(width: 1200, height: 800),
        division: CGRect(x: 540, y: 0, width: 24, height: 800),
      )
      let status = regions.red.union(regions.green)

      #expect(status.midX == 882)
      #expect(status.midY == 400)
      #expect(regions.green.minY - regions.red.maxY == 20)
      #expect(regions.blue.isNull)
    }

    private func render(
      _ kind: StatusScreenKind,
      size: CGSize,
      division: CGRect? = nil,
      actionCount: Int = 0,
    ) throws -> RenderedScreenRegions {
      try RenderedScreenRegions(containerSize: size) {
        StatusScreenLayoutFixture(
          kind: kind,
          containerSize: size,
          geometry: FoldedContentGeometry.resolve(
            containerSize: size,
            divisions: division.map { [$0] } ?? [],
          ),
          actionCount: actionCount,
        )
      }
    }
  }

  private enum StatusScreenKind {
    case result
    case loading

    var configuration: GertieScreenLayoutConfiguration {
      self == .result ? .result : .loading
    }

    var iconHeight: CGFloat {
      self == .result ? 48 : 20
    }
  }

  private struct StatusScreenLayoutFixture: View {
    let kind: StatusScreenKind
    let containerSize: CGSize
    let geometry: FoldedContentGeometry?
    let actionCount: Int

    var body: some View {
      GertieScreenContentLayout(
        containerSize: self.containerSize,
        geometry: self.geometry,
        configuration: self.kind.configuration,
        hasActions: self.actionCount > 0,
      ) {
        self.icon
      } message: {
        self.message
      } actions: {
        self.actions
      }
    }

    private var icon: some View {
      Color(red: 1, green: 0, blue: 0).frame(height: self.kind.iconHeight)
    }

    private var message: some View {
      Color(red: 0, green: 1, blue: 0).frame(height: 100)
    }

    private var actions: some View {
      VStack(spacing: 12) {
        ForEach(0 ..< self.actionCount, id: \.self) { _ in
          Color(red: 0, green: 0, blue: 1).frame(height: 52)
        }
      }
    }
  }
#endif
