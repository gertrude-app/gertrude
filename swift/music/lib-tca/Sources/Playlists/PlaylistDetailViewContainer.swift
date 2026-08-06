import ComposableArchitecture
import Foundation
import LibViews
import SwiftUI

struct PlaylistDetailViewContainer: View {
  let store: StoreOf<PlaylistDetailFeature>
  let isPlaylistMutationInFlight: Bool

  var body: some View {
    ZStack(alignment: .top) {
      PlaylistDetailView(
        playlist: PlaylistData(playlist: self.store.playlist),
        isPlaying: self.store.isPlaying,
        isLoading: self.store.isLoading,
        currentEntryID: self.store.currentEntryID?.rawValue.uuidString,
        isCurrentTrackPlaying: self.store.isCurrentTrackPlaying,
        isMutating: self.isPlaylistMutationInFlight,
        onAddMusicTap: { self.store.send(.addMusicTapped) },
        onAddToQueue: { self.store.send(.addToQueueTapped) },
        onDelete: { self.store.send(.deleteTapped) },
        onPlayNext: { self.store.send(.playNextTapped) },
        onPlayTap: { self.store.send(.playTapped) },
        onRemoveEntry: {
          guard let id = UUID(uuidString: $0) else { return }
          self.store.send(.removeEntryTapped(.init(rawValue: id)))
        },
        onRename: { self.store.send(.renameSubmitted($0)) },
        onReorder: { rawIDs in
          let ids = rawIDs.compactMap(UUID.init(uuidString:))
            .map(MusicPlaylistEntry.ID.init(rawValue:))
          guard ids.count == rawIDs.count else { return }
          self.store.send(.reorderSubmitted(ids))
        },
        onTrackAddToPlaylist: {
          guard let id = UUID(uuidString: $0) else { return }
          self.store.send(.trackAddToPlaylistTapped(.init(rawValue: id)))
        },
        onTrackAddToQueue: {
          guard let id = UUID(uuidString: $0) else { return }
          self.store.send(.trackAddToQueueTapped(.init(rawValue: id)))
        },
        onTrackPlayNext: {
          guard let id = UUID(uuidString: $0) else { return }
          self.store.send(.trackPlayNextTapped(.init(rawValue: id)))
        },
        onTrackTap: {
          guard let id = UUID(uuidString: $0) else { return }
          self.store.send(.trackTapped(.init(rawValue: id)))
        },
      )

      if let failure = self.store.playbackFailure {
        PlaybackErrorBanner(
          title: failure.title,
          message: failure.message,
          systemImage: failure.systemImage,
          actionTitle: failure.actionTitle,
          onActionTap: { self.store.send(.playbackFailureActionTapped) },
          onDismissTap: { self.store.send(.playbackFailureDismissed) },
        )
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .transition(.move(edge: .top).combined(with: .opacity))
      }
    }
    .animation(.snappy(duration: 0.22), value: self.store.playbackFailure)
  }
}
