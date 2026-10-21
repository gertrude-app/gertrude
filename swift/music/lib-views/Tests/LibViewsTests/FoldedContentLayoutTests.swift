import SwiftUI
import Testing

@testable import LibViews

struct FoldedContentLayoutTests {
  @Test
  func horizontalFoldCreatesUpperAndLowerRegionsAtActualFold() throws {
    let division = CGRect(x: 0, y: 420, width: 800, height: 24)
    let geometry = try #require(FoldedContentGeometry.resolve(
      containerSize: CGSize(width: 800, height: 1000),
      divisions: [division],
    ))

    #expect(geometry.axis == .vertical)
    #expect(geometry.division == division)
    #expect(geometry.primarySize == CGSize(width: 800, height: 420))
    #expect(geometry.secondarySize == CGSize(width: 800, height: 556))
    #expect(geometry.spacing == 24)
  }

  @Test
  func verticalFoldCreatesLeadingAndTrailingRegionsAtActualFold() throws {
    let division = CGRect(x: 550, y: 0, width: 24, height: 800)
    let geometry = try #require(FoldedContentGeometry.resolve(
      containerSize: CGSize(width: 1200, height: 800),
      divisions: [division],
    ))

    #expect(geometry.axis == .horizontal)
    #expect(geometry.division == division)
    #expect(geometry.primarySize == CGSize(width: 550, height: 800))
    #expect(geometry.secondarySize == CGSize(width: 626, height: 800))
    #expect(geometry.spacing == 24)
  }

  @Test
  func horizontalFoldCanExtendBeyondDetailColumnEdges() throws {
    let division = CGRect(x: -420, y: 380, width: 1200, height: 24)
    let geometry = try #require(FoldedContentGeometry.resolve(
      containerSize: CGSize(width: 600, height: 900),
      divisions: [division],
    ))

    #expect(geometry.axis == .vertical)
    #expect(geometry.primarySize == CGSize(width: 600, height: 380))
    #expect(geometry.secondarySize == CGSize(width: 600, height: 496))
  }

  @Test
  func verticalFoldCanExtendBeyondSafeAreaEdges() throws {
    let geometry = try #require(FoldedContentGeometry.resolve(
      containerSize: CGSize(width: 1200, height: 700),
      divisions: [CGRect(x: 550, y: -80, width: 24, height: 900)],
    ))

    #expect(geometry.axis == .horizontal)
    #expect(geometry.primarySize == CGSize(width: 550, height: 700))
    #expect(geometry.secondarySize == CGSize(width: 626, height: 700))
  }

  @Test
  func foldAxisComesFromDivisionRatherThanContainerAspectRatio() {
    #expect(FoldedContentGeometry.resolve(
      containerSize: CGSize(width: 1200, height: 700),
      divisions: [CGRect(x: 0, y: 330, width: 1200, height: 24)],
    )?.axis == .vertical)
    #expect(FoldedContentGeometry.resolve(
      containerSize: CGSize(width: 700, height: 1000),
      divisions: [CGRect(x: 330, y: 0, width: 24, height: 1000)],
    )?.axis == .horizontal)
  }

  @Test
  func flatDisplayKeepsExistingLayout() {
    #expect(FoldedContentGeometry.resolve(
      containerSize: CGSize(width: 800, height: 1000),
      divisions: [],
    ) == nil)
  }

  @Test(arguments: [
    CGRect(x: 0, y: 420, width: 800, height: 0),
    CGRect(x: 390, y: 0, width: 0, height: 1000),
    CGRect(x: 0, y: 0, width: 800, height: 24),
    CGRect(x: 0, y: -24, width: 800, height: 24),
    CGRect(x: 0, y: 976, width: 800, height: 24),
    CGRect(x: 0, y: 1000, width: 800, height: 24),
    CGRect(x: 0, y: 0, width: 24, height: 1000),
    CGRect(x: 776, y: 0, width: 24, height: 1000),
    CGRect(x: 10, y: 420, width: 790, height: 24),
    CGRect(x: 0, y: 420, width: 790, height: 24),
    CGRect(x: 390, y: 10, width: 24, height: 990),
    CGRect(x: 390, y: 0, width: 24, height: 990),
    CGRect.null,
    CGRect.infinite,
  ])
  func onlySpanningDivisionsWithUsableSpaceOnBothSidesActivateFoldedLayout(division: CGRect) {
    #expect(FoldedContentGeometry.resolve(
      containerSize: CGSize(width: 800, height: 1000),
      divisions: [division],
    ) == nil)
  }

  @Test(arguments: [
    CGSize.zero,
    CGSize(width: 0, height: 1000),
    CGSize(width: 800, height: 0),
    CGSize(width: CGFloat.infinity, height: 1000),
    CGSize(width: 800, height: CGFloat.nan),
  ])
  func invalidContainerDoesNotActivateFoldedLayout(containerSize: CGSize) {
    #expect(FoldedContentGeometry.resolve(
      containerSize: containerSize,
      divisions: [CGRect(x: 0, y: 420, width: 800, height: 24)],
    ) == nil)
  }
}
