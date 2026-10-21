import SwiftUI
import Testing

@testable import LibTCA

struct LibrarySidebarPresentationTests {
  @Test
  func selectionDismissesOnlyTheOverlaidSidebar() {
    var presentation = self.overlayPresentation

    presentation.selectCollection(isCompact: false)

    #expect(presentation.visibility == .detailOnly)
    #expect(presentation.didDismissOverlay)
  }

  @Test(arguments: [
    CGRect(x: 420, y: 0, width: 580, height: 800),
    CGRect(x: 419.5, y: 0, width: 580, height: 800),
    CGRect(x: 0, y: 800, width: 800, height: 400),
    CGRect.zero,
    CGRect.null,
  ])
  func fixedOrNonvisibleColumnsStayUnchanged(detailFrame: CGRect) {
    var presentation = self.overlayPresentation
    presentation.detailFrame = detailFrame

    presentation.selectCollection(isCompact: false)

    #expect(presentation.visibility == .automatic)
    #expect(!presentation.didDismissOverlay)
  }

  @Test
  func compactNavigationDoesNotDismissAColumn() {
    var presentation = self.overlayPresentation

    presentation.selectCollection(isCompact: true)

    #expect(presentation.visibility == .automatic)
    #expect(!presentation.didDismissOverlay)
  }

  @Test
  func missingGeometryDoesNotDismissAColumn() {
    var presentation = LibrarySidebarPresentation()

    presentation.selectCollection(isCompact: false)

    #expect(presentation.visibility == .automatic)
    #expect(!presentation.didDismissOverlay)
  }

  @Test
  func unchangedContainerGeometryDoesNotReopenDismissedOverlay() throws {
    var presentation = self.overlayPresentation
    let geometry = try #require(presentation.geometry)
    presentation.selectCollection(isCompact: false)

    presentation.updateGeometry(geometry)

    #expect(presentation.visibility == .detailOnly)
    #expect(presentation.didDismissOverlay)
  }

  @Test
  func resizingAfterAutomaticDismissalRestoresAdaptiveColumns() {
    var presentation = self.overlayPresentation
    presentation.selectCollection(isCompact: false)

    presentation.updateGeometry(.init(size: CGSize(width: 1200, height: 800), divisions: []))

    #expect(presentation.visibility == .automatic)
    #expect(!presentation.didDismissOverlay)
  }

  @Test
  func foldingWithoutResizingAlsoRestoresAdaptiveColumns() {
    var presentation = self.overlayPresentation
    presentation.selectCollection(isCompact: false)

    presentation.updateGeometry(.init(
      size: CGSize(width: 800, height: 800),
      divisions: [CGRect(x: 0, y: 380, width: 800, height: 24)],
    ))

    #expect(presentation.visibility == .automatic)
    #expect(!presentation.didDismissOverlay)
  }

  @Test(arguments: [NavigationSplitViewVisibility.all, .detailOnly])
  func resizingPreservesSubsequentManualVisibilityChoices(
    visibility: NavigationSplitViewVisibility,
  ) {
    var presentation = self.overlayPresentation
    presentation.selectCollection(isCompact: false)
    presentation.updateVisibility(.all)
    presentation.updateVisibility(visibility)

    presentation.updateGeometry(.init(size: CGSize(width: 1200, height: 800), divisions: []))

    #expect(presentation.visibility == visibility)
    #expect(!presentation.didDismissOverlay)
  }

  @Test
  func selectionDismissesAReopenedOverlayAgain() {
    var presentation = self.overlayPresentation
    presentation.selectCollection(isCompact: false)
    presentation.updateVisibility(.all)

    presentation.selectCollection(isCompact: false)

    #expect(presentation.visibility == .detailOnly)
    #expect(presentation.didDismissOverlay)
  }

  @Test
  func visibilityConfirmationDoesNotForgetAutomaticDismissal() {
    var presentation = self.overlayPresentation
    presentation.selectCollection(isCompact: false)

    presentation.updateVisibility(.detailOnly)
    presentation.updateGeometry(.init(size: CGSize(width: 1200, height: 800), divisions: []))

    #expect(presentation.visibility == .automatic)
    #expect(!presentation.didDismissOverlay)
  }

  private var overlayPresentation: LibrarySidebarPresentation {
    LibrarySidebarPresentation(
      sidebarFrame: CGRect(x: 0, y: 0, width: 420, height: 800),
      detailFrame: CGRect(x: 0, y: 0, width: 800, height: 800),
      geometry: .init(size: CGSize(width: 800, height: 800), divisions: []),
    )
  }
}
