# Music Sidebar Findings

Gertrude Music's Library uses the native `NavigationSplitView` at every width, inside the
same Library/Queue `TabView` on iPhone, iPad and iPhone Duo, with the player in
`tabViewBottomAccessory`. `LibraryFeature.path.first` is the sidebar selection (the detail
column's root) and `detailPath` is everything pushed after it. These are the problems the
native components have in that setup, and how the code works around them.

## Issues and workarounds

- **Top strip in floating iPad windows.** A split view inside a `TabView` starts 10 points
  below the window's top edge, leaving a strip the sidebar background doesn't reach.
  **Workaround:** `.ignoresSafeArea(.container, edges: .top)` on the split view container
  in `LibraryViewContainer`. `.containerBackground(..., for: .navigation)` and
  `.backgroundExtensionEffect()` don't fix it and cause other artifacts.

- **iPad launch: toolbars start one tab-bar height too low.** The selected tab's first
  layout gets the floating tab bar's height as extra top safe area. UIKit only corrects it
  if the tab view exists in the scene's first frame; Gertrude shows the setup splash
  first, so it stayed stuck until the window was resized. **Workaround:**
  `coversTabLayoutUntilSettled()` (`lib-views/Sources/Lib/TabLayoutSettling.swift`) covers
  the tabs with the setup splash, nudges the selected tab's `additionalSafeAreaInsets.top`
  on the second frame so UIKit recomputes it, and lifts the cover once the layout holds
  still (1 s at most). Correct top insets are 10 in a floating window and 32 full screen;
  74 or 96 means it's stuck.

- **iOS 17: double push at compact width.** Selecting a Library item pushed the detail
  twice when the detail column used TCA's `NavigationStack(path: $store.scope(...))`.
  **Workaround:** the detail stack binds to `[StackElementID]` from `detailPath`, uses
  `.navigationDestination(for: StackElementID.self)`, and only writes back pops.

- **Switching between two items of the same kind reuses the screen.** Going from one
  artist to another kept the old scroll position and local state. **Workaround:**
  `.id(id)` on the detail column's root.

- **Zoom transition when collapsed.** `matchedTransitionSource` on the sidebar artwork
  plus `.navigationTransition(.zoom(...))` on the detail root works like a zoom push. The
  zoom namespace is only supplied at compact width, so side-by-side selection doesn't
  zoom.

- **Duo, partly folded: content sits on the fold.** With the sidebar hidden, the detail
  column spans both halves, so centered content lands on the fold. **Workaround:**
  `FoldedContentGeometry.resolve(in:)` places the no-selection message and empty playlists
  in the right half (book) or top half (tabletop).

- **Duo, partly folded: sidebar width snaps at launch** if the sidebar is forced open.
  **Workaround:** none needed; the sidebar starts hidden by default, which is stable.

- **iPhone: no way to show the search field at launch and still let it scroll away.**
  `.navigationBarDrawer(displayMode: .always)` collapses the large title and never hides.
  **Workaround:** none; it stays hidden until pull-down, with a search button in the
  toolbar.

- **iPadOS 17: native components look less polished.** **Workaround:** none, by choice;
  too few users to justify cosmetic overrides.
