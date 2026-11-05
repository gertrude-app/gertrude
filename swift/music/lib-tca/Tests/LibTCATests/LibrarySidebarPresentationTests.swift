import SwiftUI
import Testing

@testable import LibTCA

struct LibrarySidebarPresentationTests {
  @Test
  func backgroundFollowsTheSideBySideSidebarWidth() {
    #expect(self.sideBySidePresentation.backgroundWidth == 420)
  }

  @Test
  func overlaidHiddenOrUnmeasuredSidebarsHaveNoBackground() {
    #expect(self.overlayPresentation.backgroundWidth == nil)

    var hidden = self.sideBySidePresentation
    hidden.updateVisibility(.detailOnly)
    #expect(hidden.backgroundWidth == nil) // before geometry catches up

    var unmeasured = self.sideBySidePresentation
    unmeasured.sidebarFrame = nil
    #expect(unmeasured.backgroundWidth == nil)
  }

  @Test
  func selectionDismissesOnlyAnOverlaidSidebar() {
    var overlay = self.overlayPresentation
    overlay.selectCollection(isCompact: false)
    #expect(overlay.visibility == .detailOnly)

    var sideBySide = self.sideBySidePresentation
    sideBySide.selectCollection(isCompact: false)
    #expect(sideBySide.visibility == .automatic)

    var compact = self.overlayPresentation
    compact.selectCollection(isCompact: true)
    #expect(compact.visibility == .automatic)
  }

  @Test
  func unchangedGeometryKeepsTheOverlayDismissed() throws {
    var presentation = self.overlayPresentation
    let geometry = try #require(presentation.geometry)
    presentation.selectCollection(isCompact: false)

    presentation.updateGeometry(geometry)

    #expect(presentation.visibility == .detailOnly)
  }

  @Test
  func resizingOrFoldingRestoresAdaptiveColumnsAfterADismissal() {
    var resized = self.overlayPresentation
    resized.selectCollection(isCompact: false)
    resized.updateGeometry(.init(size: CGSize(width: 1200, height: 800), divisions: []))
    #expect(resized.visibility == .automatic)

    var folded = self.overlayPresentation
    folded.selectCollection(isCompact: false)
    folded.updateGeometry(.init(
      size: CGSize(width: 800, height: 800),
      divisions: [CGRect(x: 0, y: 380, width: 800, height: 24)],
    ))
    #expect(folded.visibility == .automatic)
  }

  @Test
  func resizingPreservesAManualVisibilityChoice() {
    var presentation = self.overlayPresentation
    presentation.selectCollection(isCompact: false)
    presentation.updateVisibility(.all)

    presentation.updateGeometry(.init(size: CGSize(width: 1200, height: 800), divisions: []))

    #expect(presentation.visibility == .all)
  }

  @Test
  func nothingSelectedShowsTheLibraryUnlessTheUserHidesIt() {
    var presentation = self.overlayPresentation
    presentation.selectionChanged(hasSelection: false)
    #expect(presentation.visibility == .all)

    presentation.updateVisibility(.detailOnly)
    presentation.selectionChanged(hasSelection: true)
    #expect(presentation.visibility == .detailOnly)
  }

  @Test
  func choosingBesideTheLibraryReturnsToAdaptiveColumns() {
    var presentation = self.sideBySidePresentation
    presentation.selectionChanged(hasSelection: false)

    presentation.selectCollection(isCompact: false)
    presentation.selectionChanged(hasSelection: true)

    #expect(presentation.visibility == .automatic)
  }

  private var sideBySidePresentation: LibrarySidebarPresentation {
    LibrarySidebarPresentation(
      sidebarFrame: CGRect(x: 0, y: 0, width: 420, height: 800),
      detailFrame: CGRect(x: 420, y: 0, width: 780, height: 800),
      geometry: .init(size: CGSize(width: 1200, height: 800), divisions: []),
    )
  }

  private var overlayPresentation: LibrarySidebarPresentation {
    LibrarySidebarPresentation(
      sidebarFrame: CGRect(x: 0, y: 0, width: 420, height: 800),
      detailFrame: CGRect(x: 0, y: 0, width: 800, height: 800),
      geometry: .init(size: CGSize(width: 800, height: 800), divisions: []),
    )
  }
}
