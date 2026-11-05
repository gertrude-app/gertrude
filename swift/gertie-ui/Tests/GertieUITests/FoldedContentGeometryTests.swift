import SwiftUI
import Testing

@testable import GertieUI

struct FoldedContentGeometryTests {
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

  @Test(arguments: [
    CGRect(x: 390, y: 0, width: 0, height: 1000),
    CGRect(x: 0, y: 420, width: 800, height: 0),
  ])
  func inactiveDivisionsIdentifyTheInnerDisplayWithoutActivatingFoldedLayout(
    division: CGRect,
  ) throws {
    let size = CGSize(width: 800, height: 1000)

    #expect(FoldedContentGeometry.resolve(containerSize: size, divisions: [division]) == nil)
    let metadata = try #require(FoldedContentGeometry.resolve(
      containerSize: size,
      divisions: [division],
      includeInactive: true,
    ))
    #expect(metadata.axis == (division.width == 0 ? .horizontal : .vertical))
    #expect(metadata.spacing == 0)
  }

  @Test
  func flatInvalidAndNonSpanningDivisionsDoNotActivateFoldedLayout() {
    let size = CGSize(width: 800, height: 1000)
    let fold = CGRect(x: 0, y: 420, width: 800, height: 24)

    #expect(FoldedContentGeometry.resolve(containerSize: size, divisions: []) == nil)
    for division in [
      CGRect(x: 0, y: 0, width: 800, height: 24), // no usable space above
      CGRect(x: 776, y: 0, width: 24, height: 1000), // no usable space trailing
      CGRect(x: 10, y: 420, width: 790, height: 24), // doesn't span the container
      CGRect.null,
      CGRect.infinite,
    ] {
      #expect(FoldedContentGeometry.resolve(containerSize: size, divisions: [division]) == nil)
    }
    for containerSize in [CGSize.zero, CGSize(width: CGFloat.infinity, height: 1000)] {
      #expect(FoldedContentGeometry.resolve(containerSize: containerSize, divisions: [fold]) == nil)
    }
  }
}
