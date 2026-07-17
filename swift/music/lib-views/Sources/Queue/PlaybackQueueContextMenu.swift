import SwiftUI

extension View {
  func playbackQueueContextMenu(
    onPlayNext: @MainActor @escaping @Sendable () -> Void,
    onAddToQueue: @MainActor @escaping @Sendable () -> Void,
  ) -> some View {
    self.contextMenu {
      Button(action: onPlayNext) {
        Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward")
      }

      Button(action: onAddToQueue) {
        Label("Add to Queue", systemImage: "text.badge.plus")
      }
    }
  }
}
