import ComposableArchitecture
import LibViews
import SwiftUI

#if os(iOS)
  import UIKit
#endif

extension View {
  func albumDetailZoomPush(
    store: StoreOf<AlbumDetailFeature>?,
    onDismiss: @MainActor @escaping (String) -> Void,
  ) -> some View {
    self.modifier(AlbumDetailZoomPushModifier(
      albumDetailStore: store,
      onDismiss: onDismiss,
    ))
  }
}

private struct AlbumDetailZoomPushModifier: ViewModifier {
  let albumDetailStore: StoreOf<AlbumDetailFeature>?
  let onDismiss: @MainActor (String) -> Void

  #if os(iOS)
    @State private var navigationController: UINavigationController?
    @State private var pushedAlbumDetailID: String?
  #endif

  func body(content: Content) -> some View {
    #if os(iOS)
      content
        .background {
          NavigationControllerReader { navigationController in
            if self.navigationController !== navigationController {
              self.navigationController = navigationController
            }
            self.pushAlbumDetailIfNeeded()
          }
        }
        .onChange(of: self.albumDetailStore?.state) { _, _ in
          self.pushAlbumDetailIfNeeded()
        }
    #else
      content
    #endif
  }

  #if os(iOS)
    private func pushAlbumDetailIfNeeded() {
      guard let albumDetailStore else {
        self.pushedAlbumDetailID = nil
        return
      }

      let pushID = albumDetailStore.transitionSourceID ?? albumDetailStore.album.id.rawValue
      guard self.pushedAlbumDetailID != pushID else { return }
      self.pushedAlbumDetailID = pushID

      let didPush = AlbumDetailZoomPusher.push(
        pushID: pushID,
        transitionSourceID: albumDetailStore.transitionSourceID,
        rootView: AlbumDetailViewContainer(store: albumDetailStore),
        in: self.navigationController,
        onPop: { self.onDismiss(pushID) },
      )
      if !didPush {
        self.pushedAlbumDetailID = nil
      }
    }
  #endif
}
