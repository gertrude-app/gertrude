import ComposableArchitecture
import LibViews
import SwiftUI

#if os(iOS)
  import UIKit
#endif

extension View {
  func albumDetailZoomPush(
    store: StoreOf<AlbumDetailFeature>?,
    queuedReplacementPushID: String?,
    onDismiss: @MainActor @escaping (String) -> Void,
  ) -> some View {
    self.modifier(AlbumDetailZoomPushModifier(
      albumDetailStore: store,
      queuedReplacementPushID: queuedReplacementPushID,
      onDismiss: onDismiss,
    ))
  }
}

private struct AlbumDetailZoomPushModifier: ViewModifier {
  let albumDetailStore: StoreOf<AlbumDetailFeature>?
  let queuedReplacementPushID: String?
  let onDismiss: @MainActor (String) -> Void

  #if os(iOS)
    @State private var navigationController: UINavigationController?
    @State private var pushedAlbumDetailID: String?
    @State private var poppingForReplacementID: String?
  #endif

  func body(content: Content) -> some View {
    #if os(iOS)
      content
        .background {
          NavigationControllerReader { navigationController in
            if self.navigationController !== navigationController {
              self.navigationController = navigationController
            }
            self.reconcileAlbumDetailNavigation()
          }
        }
        .onChange(of: self.albumDetailPushID, initial: true) { _, _ in
          self.reconcileAlbumDetailNavigation()
        }
        .onChange(of: self.queuedReplacementPushID, initial: true) { _, _ in
          self.reconcileAlbumDetailNavigation()
        }
    #else
      content
    #endif
  }

  #if os(iOS)
    private var albumDetailPushID: String? {
      guard let albumDetailStore else { return nil }
      return albumDetailStore.transitionSourceID ?? albumDetailStore.album.id.rawValue
    }

    private func reconcileAlbumDetailNavigation() {
      if let queuedReplacementPushID {
        self.popTopAlbumDetailForReplacementIfNeeded(queuedReplacementPushID)
      } else {
        self.poppingForReplacementID = nil
        self.pushAlbumDetailIfNeeded()
      }
    }

    private func popTopAlbumDetailForReplacementIfNeeded(_ replacementPushID: String) {
      guard self.poppingForReplacementID != replacementPushID else { return }
      guard let topDetailPushID = AlbumDetailZoomPusher.topDetailPushID(
        in: self.navigationController,
      ), topDetailPushID != replacementPushID else { return }

      self.poppingForReplacementID = replacementPushID
      self.pushedAlbumDetailID = nil
      let didPop = AlbumDetailZoomPusher.popTopDetail(in: self.navigationController)
      if !didPop {
        self.poppingForReplacementID = nil
      }
    }

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
