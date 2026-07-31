import SwiftUI

extension View {
  func playbackQueueContextMenu(
    onPlayNext: (@MainActor @Sendable () -> Void)?,
    onAddToQueue: (@MainActor @Sendable () -> Void)?,
    onAddToPlaylist: (@MainActor @Sendable () -> Void)? = nil,
    onRemoveFromPlaylist: (@MainActor @Sendable () -> Void)? = nil,
    isRemoveFromPlaylistDisabled: Bool = false,
  ) -> some View {
    self.contextMenu {
      if let onPlayNext {
        Button(action: onPlayNext) {
          Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward")
        }
        .tint(.primary)
      }

      if let onAddToQueue {
        Button(action: onAddToQueue) {
          Label("Add to Queue", systemImage: "text.badge.plus")
        }
        .tint(.primary)
      }

      if let onAddToPlaylist {
        Button(action: onAddToPlaylist) {
          Label("Add to Playlist", systemImage: "music.note.list")
        }
        .tint(.primary)
      }

      if let onRemoveFromPlaylist {
        Divider()

        Button(role: .destructive, action: onRemoveFromPlaylist) {
          Label("Remove from This Playlist", systemImage: "trash")
        }
        .tint(.red)
        .disabled(isRemoveFromPlaylistDisabled)
      }
    }
  }
}
